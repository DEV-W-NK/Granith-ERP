import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceProjetos {
  static const String _table = 'projects';
  static const String _bucket = 'project-images';

  final Set<String> _projectsBeingCreated = {};
  final Set<String> _projectsBeingUpdated = {};
  final Set<String> _projectsBeingDeleted = {};
  final Set<String> _imagesBeingUploaded = {};
  final Map<String, DateTime> _operationTimestamp = {};

  static const Duration _operationTimeout = Duration(minutes: 5);
  static const Duration _duplicateDetectionWindow = Duration(seconds: 5);

  SupabaseClient get _client => AppSupabase.client;
  User? get _currentUser => _client.auth.currentUser;

  bool get isUserAuthenticated => _currentUser != null;

  void _cleanupExpiredOperations() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _operationTimestamp.entries) {
      if (now.difference(entry.value) > _operationTimeout) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _projectsBeingCreated.remove(key);
      _projectsBeingUpdated.remove(key);
      _projectsBeingDeleted.remove(key);
      _imagesBeingUploaded.remove(key);
      _operationTimestamp.remove(key);
    }
  }

  String _generateProjectKey(String name, String client) {
    return '${name.trim().toLowerCase()}_${client.trim().toLowerCase()}';
  }

  bool _isProjectBeingProcessed(String projectKey) {
    _cleanupExpiredOperations();
    return _projectsBeingCreated.contains(projectKey) ||
        _projectsBeingUpdated.contains(projectKey) ||
        _projectsBeingDeleted.contains(projectKey);
  }

  void _markProjectProcessing(String projectKey, String operationType) {
    _operationTimestamp[projectKey] = DateTime.now();

    switch (operationType) {
      case 'create':
        _projectsBeingCreated.add(projectKey);
        break;
      case 'update':
        _projectsBeingUpdated.add(projectKey);
        break;
      case 'delete':
        _projectsBeingDeleted.add(projectKey);
        break;
    }
  }

  void _finishProjectProcessing(String projectKey) {
    _projectsBeingCreated.remove(projectKey);
    _projectsBeingUpdated.remove(projectKey);
    _projectsBeingDeleted.remove(projectKey);
    _operationTimestamp.remove(projectKey);
  }

  Map<String, dynamic> _projectToRow(Project project, {bool includeId = true}) {
    final now = DateTime.now();
    final row = <String, dynamic>{
      if (includeId && project.id.isNotEmpty) 'id': project.id,
      'name': project.name.trim(),
      'client': project.client.trim(),
      'description': project.description.trim(),
      'status': project.status.name,
      'startDate': project.startDate,
      'endDate': project.endDate,
      'budget': project.budget,
      'currentCost': project.currentCost,
      'location': project.location.trim(),
      'tags': project.tags.map((tag) => tag.trim()).toList(),
      'teamSize': project.teamSize,
      'imageUrl': project.imageUrl,
      'clientAccountId': project.clientAccountId,
      'client_account_id': project.clientAccountId,
      'clientAccountName': project.clientAccountName,
      'client_account_name': project.clientAccountName,
      'projectKey': _generateProjectKey(project.name, project.client),
      'contentHash': project.contentHash,
      'updatedAt': now,
      'updated_at': now,
      'updatedBy': _currentUser?.id ?? 'anonymous',
      'updated_by': _currentUser?.id ?? 'anonymous',
    };

    return DbValue.normalizeMap(row);
  }

  Future<List<Project>> getProjects({String? clientAccountId}) async {
    try {
      var query = _client.from(_table).select();
      if (clientAccountId != null && clientAccountId.trim().isNotEmpty) {
        query = query.eq('clientAccountId', clientAccountId.trim());
      }
      final response = await query.order('createdAt', ascending: false);

      return (response as List).map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        return Project.fromMap((data['id'] ?? '').toString(), data);
      }).toList();
    } catch (e) {
      throw Exception('Erro ao carregar projetos: $e');
    }
  }

  Future<List<Project>> getProjectsByClientAccount(String clientAccountId) {
    return getProjects(clientAccountId: clientAccountId);
  }

  Future<String> addProject(Project project) async {
    final projectKey = _generateProjectKey(project.name, project.client);

    if (_isProjectBeingProcessed(projectKey)) {
      throw Exception(
        'Projeto já está sendo processado. Aguarde a conclusão da operação anterior.',
      );
    }

    try {
      _markProjectProcessing(projectKey, 'create');

      final recentCutoff =
          DateTime.now()
              .subtract(_duplicateDetectionWindow)
              .toUtc()
              .toIso8601String();

      final existing = await _client
          .from(_table)
          .select('id')
          .eq('name', project.name.trim())
          .eq('client', project.client.trim())
          .limit(1);

      if ((existing as List).isNotEmpty) {
        throw Exception('Já existe um projeto com este nome para este cliente');
      }

      final recent = await _client
          .from(_table)
          .select('id')
          .eq('name', project.name.trim())
          .eq('client', project.client.trim())
          .gte('createdAt', recentCutoff)
          .limit(1);

      if ((recent as List).isNotEmpty) {
        throw Exception(
          'Projeto duplicado detectado. Operação cancelada para evitar duplicação.',
        );
      }

      final now = DateTime.now();
      final payload = _projectToRow(project, includeId: project.id.isNotEmpty)
        ..addAll(
          DbValue.normalizeMap({
            'createdAt': now,
            'created_at': now,
            'createdBy': _currentUser?.id ?? 'anonymous',
            'created_by': _currentUser?.id ?? 'anonymous',
            'creationTimestamp': now,
            'creation_timestamp': now,
          }),
        );

      final created =
          await _client.from(_table).insert(payload).select('id').single();

      return (created['id']).toString();
    } catch (e) {
      rethrow;
    } finally {
      _finishProjectProcessing(projectKey);
    }
  }

  Future<void> updateProject(Project project) async {
    if (project.id.isEmpty) {
      throw Exception('ID do projeto é obrigatório para atualização');
    }

    final projectKey = _generateProjectKey(project.name, project.client);

    if (_projectsBeingUpdated.contains(projectKey) ||
        _projectsBeingDeleted.contains(projectKey)) {
      throw Exception(
        'Projeto já está sendo atualizado ou deletado. Aguarde a conclusão da operação.',
      );
    }

    try {
      _markProjectProcessing(projectKey, 'update');

      final existing = await _client
          .from(_table)
          .select('id')
          .eq('name', project.name.trim())
          .eq('client', project.client.trim());

      final duplicates =
          (existing as List)
              .where((row) => (row['id']).toString() != project.id)
              .toList();

      if (duplicates.isNotEmpty) {
        throw Exception(
          'Já existe outro projeto com este nome para este cliente',
        );
      }

      await _client
          .from(_table)
          .update(_projectToRow(project, includeId: false))
          .eq('id', project.id);
    } catch (e) {
      rethrow;
    } finally {
      _finishProjectProcessing(projectKey);
    }
  }

  Future<bool> projectExists({
    required String name,
    required String client,
    String? excludeId,
  }) async {
    try {
      final projectKey = _generateProjectKey(name, client);
      if (_isProjectBeingProcessed(projectKey)) {
        return true;
      }

      final response = await _client
          .from(_table)
          .select('id')
          .eq('name', name.trim())
          .eq('client', client.trim())
          .limit(5);

      final rows = (response as List).cast<Map<String, dynamic>>();
      if (excludeId != null) {
        return rows.any((row) => (row['id']).toString() != excludeId);
      }

      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteProject(String projectId) async {
    if (projectId.isEmpty) {
      throw Exception('ID do projeto é obrigatório para exclusão');
    }

    final response =
        await _client
            .from(_table)
            .select('name, client')
            .eq('id', projectId)
            .maybeSingle();

    if (response == null) {
      throw Exception('Projeto não encontrado');
    }

    final projectKey = _generateProjectKey(
      (response['name'] ?? '').toString(),
      (response['client'] ?? '').toString(),
    );

    if (_isProjectBeingProcessed(projectKey)) {
      throw Exception(
        'Projeto está sendo processado. Não é possível deletar agora.',
      );
    }

    try {
      _markProjectProcessing(projectKey, 'delete');
      await _client.from(_table).delete().eq('id', projectId);
      await _deleteProjectImage(projectId);
    } catch (e) {
      rethrow;
    } finally {
      _finishProjectProcessing(projectKey);
    }
  }

  Future<String?> uploadProjectImage({
    File? file,
    Uint8List? webData,
    required String projectId,
    bool replaceExisting = true,
  }) async {
    final uploadKey = 'upload_$projectId';

    if (_imagesBeingUploaded.contains(uploadKey)) {
      throw Exception('Upload já em andamento para este projeto');
    }

    try {
      _imagesBeingUploaded.add(uploadKey);
      _operationTimestamp[uploadKey] = DateTime.now();

      if (!isUserAuthenticated && !kDebugMode) {
        throw Exception('Usuário não está autenticado');
      }

      if (kIsWeb && webData == null) {
        return null;
      }

      if (!kIsWeb && file == null) {
        return null;
      }

      if (replaceExisting) {
        await _deleteProjectImage(projectId);
      }

      final now = DateTime.now();
      final fileName =
          'project_${now.millisecondsSinceEpoch}_${now.microsecond}.jpg';
      final path = '$projectId/$fileName';

      if (kIsWeb && webData != null) {
        if (!_isValidImageData(webData)) {
          throw Exception('Formato de imagem não suportado');
        }

        await _client.storage
            .from(_bucket)
            .uploadBinary(
              path,
              webData,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
      } else if (!kIsWeb && file != null) {
        if (!await file.exists()) {
          throw Exception('Arquivo não encontrado');
        }

        await _client.storage
            .from(_bucket)
            .upload(
              path,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
      } else {
        return null;
      }

      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Erro no upload da imagem: $e');
    } finally {
      _imagesBeingUploaded.remove(uploadKey);
      _operationTimestamp.remove(uploadKey);
    }
  }

  Future<void> _deleteProjectImage(String projectId) async {
    try {
      final files = await _client.storage.from(_bucket).list(path: projectId);
      if (files.isEmpty) {
        return;
      }

      final paths = files.map((file) => '$projectId/${file.name}').toList();
      await _client.storage.from(_bucket).remove(paths);
    } catch (_) {
      // Ignora quando a pasta/bucket ainda não existe ou não há arquivos.
    }
  }

  Future<String?> getProjectImageUrl(String projectId) async {
    try {
      final files = await _client.storage.from(_bucket).list(path: projectId);
      if (files.isEmpty) {
        return null;
      }

      return _client.storage
          .from(_bucket)
          .getPublicUrl('$projectId/${files.first.name}');
    } catch (_) {
      return null;
    }
  }

  bool _isValidImageData(Uint8List data) {
    if (data.length < 4) return false;

    final signatures = {
      'jpeg': [0xFF, 0xD8, 0xFF],
      'png': [0x89, 0x50, 0x4E, 0x47],
      'webp': [0x52, 0x49, 0x46, 0x46],
      'gif': [0x47, 0x49, 0x46, 0x38],
    };

    for (final signature in signatures.values) {
      var matches = true;
      for (var i = 0; i < signature.length && i < data.length; i++) {
        if (data[i] != signature[i]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return true;
      }
    }

    return false;
  }

  void debugMarkProjectProcessing(
    String projectName,
    String projectClient,
    String operationType,
  ) {
    _markProjectProcessing(
      _generateProjectKey(projectName, projectClient),
      operationType,
    );
  }

  void debugMarkImageUploadInProgress(String projectId, {DateTime? at}) {
    final key = 'upload_$projectId';
    _imagesBeingUploaded.add(key);
    _operationTimestamp[key] = at ?? DateTime.now();
  }

  void debugSetOperationTimestamp(String key, DateTime timestamp) {
    _operationTimestamp[key] = timestamp;
  }

  bool debugIsValidImageData(Uint8List data) => _isValidImageData(data);

  Future<void> testStorageConnection() async {
    final files = await _client.storage.from(_bucket).list();
    debugPrint(
      'Supabase Storage conectado. Arquivos encontrados: ${files.length}',
    );
  }

  Future<List<String>> getProjectImages(String projectId) async {
    try {
      final files = await _client.storage.from(_bucket).list(path: projectId);
      return files
          .map(
            (file) => _client.storage
                .from(_bucket)
                .getPublicUrl('$projectId/${file.name}'),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  void forceCleanAllOperations() {
    _projectsBeingCreated.clear();
    _projectsBeingUpdated.clear();
    _projectsBeingDeleted.clear();
    _imagesBeingUploaded.clear();
    _operationTimestamp.clear();
  }

  bool hasOperationsInProgress() {
    _cleanupExpiredOperations();
    return _projectsBeingCreated.isNotEmpty ||
        _projectsBeingUpdated.isNotEmpty ||
        _projectsBeingDeleted.isNotEmpty ||
        _imagesBeingUploaded.isNotEmpty;
  }

  Map<String, dynamic> getDetailedOperationStats() {
    _cleanupExpiredOperations();

    return {
      'projectsBeingCreated': _projectsBeingCreated.length,
      'projectsBeingUpdated': _projectsBeingUpdated.length,
      'projectsBeingDeleted': _projectsBeingDeleted.length,
      'imagesBeingUploaded': _imagesBeingUploaded.length,
      'totalOperations':
          _projectsBeingCreated.length +
          _projectsBeingUpdated.length +
          _projectsBeingDeleted.length +
          _imagesBeingUploaded.length,
      'operationDetails': {
        'creating': _projectsBeingCreated.toList(),
        'updating': _projectsBeingUpdated.toList(),
        'deleting': _projectsBeingDeleted.toList(),
        'uploading': _imagesBeingUploaded.toList(),
      },
    };
  }

  bool isProjectCurrentlyProcessing(String projectName, String projectClient) {
    return _isProjectBeingProcessed(
      _generateProjectKey(projectName, projectClient),
    );
  }

  Future<void> waitForProjectOperationCompletion(
    String projectName,
    String projectClient, {
    Duration maxWait = const Duration(minutes: 2),
    Duration checkInterval = const Duration(milliseconds: 500),
  }) async {
    final projectKey = _generateProjectKey(projectName, projectClient);
    final startTime = DateTime.now();

    while (_isProjectBeingProcessed(projectKey)) {
      if (DateTime.now().difference(startTime) > maxWait) {
        throw Exception('Timeout aguardando conclusão da operação do projeto');
      }

      await Future.delayed(checkInterval);
    }
  }

  void cancelProjectOperation(String projectName, String projectClient) {
    final projectKey = _generateProjectKey(projectName, projectClient);
    _projectsBeingCreated.remove(projectKey);
    _projectsBeingUpdated.remove(projectKey);
    _projectsBeingDeleted.remove(projectKey);
    _operationTimestamp.remove(projectKey);
  }

  Future<Map<String, dynamic>> runDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    try {
      diagnostics['operations'] = getDetailedOperationStats();

      final testQuery = await _client.from(_table).select('id').limit(1);
      diagnostics['supabaseConnection'] = {
        'status': 'connected',
        'documentsFound': (testQuery as List).length,
      };

      final storageFiles = await _client.storage.from(_bucket).list();
      diagnostics['storageConnection'] = {
        'status': 'connected',
        'itemsFound': storageFiles.length,
      };

      diagnostics['authentication'] = {
        'isAuthenticated': isUserAuthenticated,
        'userId': _currentUser?.id,
        'userEmail': _currentUser?.email,
      };

      final allProjects = await getProjects();
      diagnostics['projectStats'] = {
        'totalProjects': allProjects.length,
        'statusDistribution': _getStatusDistribution(allProjects),
        'clientDistribution': _getClientDistribution(allProjects),
      };

      diagnostics['timestamp'] = DateTime.now().toIso8601String();
      diagnostics['status'] = 'success';
    } catch (e) {
      diagnostics['status'] = 'error';
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }

  Map<String, int> _getStatusDistribution(List<Project> projects) {
    final distribution = <String, int>{};
    for (final project in projects) {
      distribution[project.status.name] =
          (distribution[project.status.name] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _getClientDistribution(List<Project> projects) {
    final distribution = <String, int>{};
    for (final project in projects) {
      final client = project.client.trim();
      if (client.isNotEmpty) {
        distribution[client] = (distribution[client] ?? 0) + 1;
      }
    }
    return distribution;
  }

  Future<List<Project>> recoverCorruptedProjects() async {
    final response = await _client.from(_table).select();
    final recovered = <Project>[];

    for (final row in (response as List)) {
      final data = Map<String, dynamic>.from(row as Map);
      try {
        recovered.add(Project.fromMap((data['id'] ?? '').toString(), data));
      } catch (_) {
        recovered.add(
          Project(
            id: (data['id'] ?? '').toString(),
            name: 'PROJETO_RECUPERADO_${data['id'] ?? ''}',
            client: 'CLIENTE_RECUPERADO',
            description: 'Projeto recuperado de dados corrompidos',
            status: ProjectStatus.planning,
            startDate: DateTime.now(),
            budget: 0,
            currentCost: 0,
            location: '',
            tags: const ['RECUPERADO'],
            teamSize: 0,
          ),
        );
      }
    }

    return recovered;
  }
}
