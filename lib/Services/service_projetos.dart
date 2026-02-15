import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_model.dart';

class ServiceProjetos {
  final CollectionReference _projectsRef = FirebaseFirestore.instance
      .collection('projetos');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // MELHORIA: Usar Set para controle mais eficiente de operações
  final Set<String> _projectsBeingCreated = {};
  final Set<String> _projectsBeingUpdated = {};
  final Set<String> _projectsBeingDeleted = {};
  final Set<String> _imagesBeingUploaded = {};

  // Cache de timestamps para controle temporal
  final Map<String, DateTime> _operationTimestamp = {};

  // Timeout para operações (5 minutos)
  static const Duration _operationTimeout = Duration(minutes: 5);

  // Timeout mais rigoroso para detecção de duplicatas (5 segundos)
  static const Duration _duplicateDetectionWindow = Duration(seconds: 5);

  ServiceProjetos() {
    // Configurar emulators em modo debug
    if (kDebugMode) {
      try {
        _storage.useStorageEmulator('localhost', 9199);
        print('🔥 Storage Emulator ativo em localhost:9199');
      } catch (e) {
        print('Storage Emulator já configurado ou erro: $e');
      }
    }
  }

  // Verificar se usuário está autenticado
  bool get isUserAuthenticated => _auth.currentUser != null;

  // MELHORIA: Limpeza automática e mais eficiente de operações expiradas
  void _cleanupExpiredOperations() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _operationTimestamp.entries) {
      if (now.difference(entry.value) > _operationTimeout) {
        expiredKeys.add(entry.key);
      }
    }

    // Limpar de todos os Sets
    for (final key in expiredKeys) {
      _projectsBeingCreated.remove(key);
      _projectsBeingUpdated.remove(key);
      _projectsBeingDeleted.remove(key);
      _imagesBeingUploaded.remove(key);
      _operationTimestamp.remove(key);
      print('🧹 Operação expirada removida: $key');
    }
  }

  // NOVA: Gerar chave única para projeto baseada em conteúdo
  String _generateProjectKey(String name, String client) {
    return '${name.trim().toLowerCase()}_${client.trim().toLowerCase()}';
  }

  // NOVA: Verificar se projeto está sendo processado
  bool _isProjectBeingProcessed(String projectKey) {
    _cleanupExpiredOperations();
    return _projectsBeingCreated.contains(projectKey) ||
        _projectsBeingUpdated.contains(projectKey) ||
        _projectsBeingDeleted.contains(projectKey);
  }

  // NOVA: Marcar projeto como em processamento
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

  // NOVA: Finalizar processamento do projeto
  void _finishProjectProcessing(String projectKey) {
    _projectsBeingCreated.remove(projectKey);
    _projectsBeingUpdated.remove(projectKey);
    _projectsBeingDeleted.remove(projectKey);
    _operationTimestamp.remove(projectKey);
  }

  // Obter todos os projetos
  Future<List<Project>> getProjects() async {
    try {
      final snapshot =
          await _projectsRef.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Verificar se imageUrl existe e não está vazio
        String? imageUrl = data['imageUrl'];
        if (imageUrl != null && imageUrl.isEmpty) {
          imageUrl = null; // Converter string vazia em null
        }

        return Project(
          id: doc.id,
          name: data['name'] ?? '',
          client: data['client'] ?? '',
          description: data['description'] ?? '',
          status: ProjectStatus.values.firstWhere(
            (e) => e.name == (data['status'] ?? 'planning'),
            orElse: () => ProjectStatus.planning,
          ),
          startDate: (data['startDate'] as Timestamp).toDate(),
          endDate:
              data['endDate'] != null
                  ? (data['endDate'] as Timestamp).toDate()
                  : null,
          budget: (data['budget'] ?? 0).toDouble(),
          currentCost: (data['currentCost'] ?? 0).toDouble(),
          location: data['location'] ?? '',
          tags: List<String>.from(data['tags'] ?? []),
          teamSize: data['teamSize'] ?? 0,
          imageUrl: imageUrl,
        );
      }).toList();
    } catch (e) {
      print('Erro ao buscar projetos: $e');
      throw Exception('Erro ao carregar projetos: $e');
    }
  }

  // CORREÇÃO PRINCIPAL: Controle rigoroso de duplicação com verificação temporal
  Future<String> addProject(Project project) async {
    final projectKey = _generateProjectKey(project.name, project.client);

    // MELHORIA: Verificação mais rigorosa de processamento
    if (_isProjectBeingProcessed(projectKey)) {
      throw Exception(
        'Projeto já está sendo processado. Aguarde a conclusão da operação anterior.',
      );
    }

    try {
      _markProjectProcessing(projectKey, 'create');

      print(
        '🔄 Iniciando criação do projeto: ${project.name} (Cliente: ${project.client})',
      );

      // MELHORIA: Usar transação com verificação temporal rigorosa
      final result = await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final now = DateTime.now();
        final recentCutoff = now.subtract(_duplicateDetectionWindow);

        // 1. Verificar projetos duplicados existentes
        final existingQuery =
            await _projectsRef
                .where('name', isEqualTo: project.name.trim())
                .where('client', isEqualTo: project.client.trim())
                .get();

        if (existingQuery.docs.isNotEmpty) {
          throw Exception(
            'Já existe um projeto com este nome para este cliente',
          );
        }

        // 2. NOVA: Verificar projetos criados recentemente (últimos 5 segundos)
        final recentQuery =
            await _projectsRef
                .where('name', isEqualTo: project.name.trim())
                .where('client', isEqualTo: project.client.trim())
                .where(
                  'createdAt',
                  isGreaterThan: Timestamp.fromDate(recentCutoff),
                )
                .get();

        if (recentQuery.docs.isNotEmpty) {
          print(
            '⚠️ Projeto duplicado detectado nos últimos ${_duplicateDetectionWindow.inSeconds} segundos',
          );
          throw Exception(
            'Projeto duplicado detectado. Operação cancelada para evitar duplicação.',
          );
        }

        // 3. Criar referência de documento com ID personalizado se fornecido
        DocumentReference newDocRef;
        if (project.id.isNotEmpty) {
          newDocRef = _projectsRef.doc(project.id);

          // Verificar se ID já existe
          final docSnapshot = await transaction.get(newDocRef);
          if (docSnapshot.exists) {
            throw Exception('Já existe um projeto com este ID');
          }
        } else {
          newDocRef = _projectsRef.doc();
        }

        // 4. Preparar dados do projeto com metadados de controle
        final projectData = {
          'name': project.name.trim(),
          'client': project.client.trim(),
          'description': project.description.trim(),
          'status': project.status.name,
          'startDate': Timestamp.fromDate(project.startDate),
          'endDate':
              project.endDate != null
                  ? Timestamp.fromDate(project.endDate!)
                  : null,
          'budget': project.budget,
          'currentCost': project.currentCost,
          'location': project.location.trim(),
          'tags': project.tags.map((tag) => tag.trim()).toList(),
          'teamSize': project.teamSize,
          'imageUrl': project.imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid ?? 'anonymous',
          // NOVA: Metadados para controle de duplicação
          'projectKey': projectKey,
          'creationTimestamp': Timestamp.fromDate(now),
        };

        // 5. Criar o documento
        transaction.set(newDocRef, projectData);

        print('✅ Projeto criado na transação: ${newDocRef.id}');
        return newDocRef;
      });

      print('✅ Projeto adicionado com sucesso: ${result.id}');

      // NOVA: Pequeno delay para permitir propagação do timestamp
      await Future.delayed(Duration(milliseconds: 100));

      return result.id;
    } catch (e) {
      print('❌ Erro ao adicionar projeto: $e');
      rethrow; // Re-lançar a exceção original
    } finally {
      _finishProjectProcessing(projectKey);
    }
  }

  // CORREÇÃO: Atualizar projeto com verificação melhorada
  Future<void> updateProject(Project project) async {
    if (project.id.isEmpty) {
      throw Exception('ID do projeto é obrigatório para atualização');
    }

    final projectKey = _generateProjectKey(project.name, project.client);

    // MELHORIA: Verificação específica para updates
    if (_projectsBeingUpdated.contains(projectKey) ||
        _projectsBeingDeleted.contains(projectKey)) {
      throw Exception(
        'Projeto já está sendo atualizado ou deletado. Aguarde a conclusão da operação.',
      );
    }

    try {
      _markProjectProcessing(projectKey, 'update');

      print('🔄 Iniciando atualização do projeto: ${project.id}');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Verificar se o documento existe
        final docRef = _projectsRef.doc(project.id);
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('Projeto não encontrado');
        }

        // 2. Verificar duplicatas (excluindo o próprio projeto)
        final existingQuery =
            await _projectsRef
                .where('name', isEqualTo: project.name.trim())
                .where('client', isEqualTo: project.client.trim())
                .get();

        final duplicates =
            existingQuery.docs.where((doc) => doc.id != project.id).toList();

        if (duplicates.isNotEmpty) {
          throw Exception(
            'Já existe outro projeto com este nome para este cliente',
          );
        }

        // 3. Atualizar o documento
        final updateData = {
          'name': project.name.trim(),
          'client': project.client.trim(),
          'description': project.description.trim(),
          'status': project.status.name,
          'startDate': Timestamp.fromDate(project.startDate),
          'endDate':
              project.endDate != null
                  ? Timestamp.fromDate(project.endDate!)
                  : null,
          'budget': project.budget,
          'currentCost': project.currentCost,
          'location': project.location.trim(),
          'tags': project.tags.map((tag) => tag.trim()).toList(),
          'teamSize': project.teamSize,
          'imageUrl': project.imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? 'anonymous',
          // NOVA: Atualizar chave do projeto
          'projectKey': projectKey,
        };

        transaction.update(docRef, updateData);
      });

      print('✅ Projeto atualizado: ${project.id}');
    } catch (e) {
      print('❌ Erro ao atualizar projeto: $e');
      rethrow;
    } finally {
      _finishProjectProcessing(projectKey);
    }
  }

  // Verificar se projeto existe (melhorado com cache)
  Future<bool> projectExists({
    required String name,
    required String client,
    String? excludeId,
  }) async {
    try {
      final projectKey = _generateProjectKey(name, client);

      // Verificar se está sendo processado
      if (_isProjectBeingProcessed(projectKey)) {
        return true; // Considera como existente se está sendo processado
      }

      final query =
          await _projectsRef
              .where('name', isEqualTo: name.trim())
              .where('client', isEqualTo: client.trim())
              .limit(5) // Limitar para otimizar performance
              .get();

      if (excludeId != null) {
        return query.docs.any((doc) => doc.id != excludeId);
      }

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar existência do projeto: $e');
      return false;
    }
  }

  // Deletar projeto (melhorado com controle rigoroso)
  Future<void> deleteProject(String projectId) async {
    if (projectId.isEmpty) {
      throw Exception('ID do projeto é obrigatório para exclusão');
    }

    // NOVA: Obter dados do projeto para gerar chave
    final projectDoc = await _projectsRef.doc(projectId).get();
    if (!projectDoc.exists) {
      throw Exception('Projeto não encontrado');
    }

    final projectData = projectDoc.data() as Map<String, dynamic>;
    final projectKey = _generateProjectKey(
      projectData['name'] ?? '',
      projectData['client'] ?? '',
    );

    if (_isProjectBeingProcessed(projectKey)) {
      throw Exception(
        'Projeto está sendo processado. Não é possível deletar agora.',
      );
    }

    try {
      _markProjectProcessing(projectKey, 'delete');

      print('🔄 Iniciando exclusão do projeto: $projectId');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docRef = _projectsRef.doc(projectId);
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('Projeto não encontrado');
        }

        // Deletar documento
        transaction.delete(docRef);
      });

      // Deletar imagens associadas (fora da transação)
      await _deleteProjectImage(projectId);

      print('✅ Projeto deletado: $projectId');
    } catch (e) {
      print('❌ Erro ao deletar projeto: $e');
      rethrow;
    } finally {
      _finishProjectProcessing(projectKey);
    }
  }

  // Upload de imagem com controle melhorado de duplicação
  Future<String?> uploadProjectImage({
    File? file,
    Uint8List? webData,
    required String projectId,
    bool replaceExisting = true,
  }) async {
    final uploadKey = 'upload_$projectId';

    // MELHORIA: Controle específico para uploads
    if (_imagesBeingUploaded.contains(uploadKey)) {
      throw Exception('Upload já em andamento para este projeto');
    }

    try {
      _imagesBeingUploaded.add(uploadKey);
      _operationTimestamp[uploadKey] = DateTime.now();

      print('🔄 Iniciando upload de imagem para projeto: $projectId');

      // Verificar autenticação
      if (!isUserAuthenticated && !kDebugMode) {
        print('❌ Usuário não autenticado');
        throw Exception('Usuário não está autenticado');
      }

      // Validar dados de entrada
      if (kIsWeb && webData == null) {
        print('❌ Dados web não fornecidos');
        return null;
      }

      if (!kIsWeb && file == null) {
        print('❌ Arquivo não fornecido');
        return null;
      }

      // Se replaceExisting for true, deletar imagens existentes primeiro
      if (replaceExisting) {
        await _deleteProjectImage(projectId);
      }

      // Gerar nome único para o arquivo com timestamp mais preciso
      final now = DateTime.now();
      final timestamp = '${now.millisecondsSinceEpoch}_${now.microsecond}';
      final fileName = 'project_$timestamp.jpg';
      final ref = _storage.ref('projects/$projectId/$fileName');

      print('📂 Caminho do arquivo: ${ref.fullPath}');

      UploadTask uploadTask;

      if (kIsWeb && webData != null) {
        // Validar dados da imagem
        if (!_isValidImageData(webData)) {
          print('❌ Dados de imagem inválidos');
          throw Exception('Formato de imagem não suportado');
        }

        print('🌐 Upload web - Tamanho: ${webData.length} bytes');

        uploadTask = ref.putData(
          webData,
          SettableMetadata(
            contentType: _getContentType(webData),
            customMetadata: {
              'projectId': projectId,
              'uploadedAt': DateTime.now().toIso8601String(),
              'platform': 'web',
              'uploadedBy': _auth.currentUser?.uid ?? 'anonymous',
            },
          ),
        );
      } else if (!kIsWeb && file != null) {
        // Verificar se o arquivo existe
        if (!await file.exists()) {
          print('❌ Arquivo não existe');
          throw Exception('Arquivo não encontrado');
        }

        final fileSize = await file.length();
        print('📱 Upload mobile - Tamanho: $fileSize bytes');

        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'projectId': projectId,
              'uploadedAt': DateTime.now().toIso8601String(),
              'platform': 'mobile',
              'uploadedBy': _auth.currentUser?.uid ?? 'anonymous',
            },
          ),
        );
      } else {
        print('❌ Nenhum dado válido fornecido');
        return null;
      }

      // Monitorar progresso do upload
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print(
          '📈 Progresso do upload: ${(progress * 100).toStringAsFixed(1)}%',
        );
      });

      // Aguardar conclusão do upload
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('✅ Upload concluído com sucesso!');
        print('🔗 URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('❌ Upload falhou - Estado: ${snapshot.state}');
        throw Exception('Upload não foi concluído com sucesso');
      }
    } catch (e) {
      print('💥 Erro no upload: $e');

      // Tratar erros específicos do Firebase
      if (e.toString().contains('unauthorized')) {
        throw Exception(
          'Sem permissão para fazer upload. Verifique as regras do Firebase Storage.',
        );
      } else if (e.toString().contains('quota-exceeded')) {
        throw Exception('Limite de armazenamento excedido.');
      } else if (e.toString().contains('invalid-argument')) {
        throw Exception('Arquivo inválido ou corrompido.');
      } else {
        throw Exception('Erro no upload da imagem: $e');
      }
    } finally {
      _imagesBeingUploaded.remove(uploadKey);
      _operationTimestamp.remove(uploadKey);
    }
  }

  // Deletar imagem do projeto
  Future<void> _deleteProjectImage(String projectId) async {
    try {
      // Listar todos os arquivos do projeto
      final projectRef = _storage.ref('projects/$projectId');
      final listResult = await projectRef.listAll();

      // Deletar todos os arquivos encontrados
      for (final item in listResult.items) {
        await item.delete();
        print('🗑️ Imagem deletada: ${item.name}');
      }
    } catch (e) {
      print('⚠️ Erro ao deletar imagens do projeto: $e');
      // Não propagar o erro, pois pode não haver imagens
    }
  }

  // Obter URL de imagem do projeto
  Future<String?> getProjectImageUrl(String projectId) async {
    try {
      final projectRef = _storage.ref('projects/$projectId');
      final listResult = await projectRef.listAll();

      if (listResult.items.isNotEmpty) {
        // Retornar a primeira imagem encontrada
        return await listResult.items.first.getDownloadURL();
      }

      return null;
    } catch (e) {
      print('❌ Erro ao obter URL da imagem: $e');
      return null;
    }
  }

  // Validar dados de imagem
  bool _isValidImageData(Uint8List data) {
    if (data.length < 4) return false;

    // Headers de formatos suportados
    final signatures = {
      'JPEG': [0xFF, 0xD8, 0xFF],
      'PNG': [0x89, 0x50, 0x4E, 0x47],
      'WebP': [0x52, 0x49, 0x46, 0x46],
      'GIF': [0x47, 0x49, 0x46, 0x38],
    };

    for (final signature in signatures.values) {
      bool matches = true;
      for (int i = 0; i < signature.length && i < data.length; i++) {
        if (data[i] != signature[i]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }

    return false;
  }

  // Detectar content type da imagem
  String _getContentType(Uint8List data) {
    if (data.length >= 3 &&
        data[0] == 0xFF &&
        data[1] == 0xD8 &&
        data[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (data.length >= 4 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return 'image/png';
    }
    if (data.length >= 4 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46) {
      return 'image/webp';
    }
    if (data.length >= 4 &&
        data[0] == 0x47 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x38) {
      return 'image/gif';
    }
    return 'image/jpeg'; // fallback
  }

  // Função de teste para verificar conectividade
  Future<void> testStorageConnection() async {
    try {
      print('🧪 === TESTE DE CONEXÃO STORAGE ===');

      // Teste 1: Verificar autenticação
      if (isUserAuthenticated) {
        print('✅ Usuário autenticado: ${_auth.currentUser!.uid}');
      } else {
        print('⚠️ Usuário não autenticado');
      }

      // Teste 2: Testar listagem
      final rootRef = _storage.ref();
      final listResult = await rootRef.listAll();
      print(
        '📁 Pastas encontradas: ${listResult.prefixes.map((p) => p.name).toList()}',
      );

      // Teste 3: Upload de teste
      final testData = _createTestImageData();
      final testRef = _storage.ref(
        'test/connection_test_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await testRef.putData(
        testData,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final testUrl = await testRef.getDownloadURL();
      print('✅ Teste de upload bem-sucedido!');
      print('🔗 URL de teste: $testUrl');

      // Limpar teste
      await testRef.delete();
      print('🧹 Arquivo de teste removido');
    } catch (e) {
      print('❌ Erro no teste de conexão: $e');
      rethrow;
    }
  }

  // Criar dados de imagem de teste
  Uint8List _createTestImageData() {
    // Criar um JPEG mínimo válido (1x1 pixel preto)
    return Uint8List.fromList([
      // JPEG header
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
      // Minimal JPEG data
      0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11,
      0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
      0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08,
      0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0xFF, 0xDA, 0x00, 0x0C, 0x03, 0x01, 0x00, 0x02, 0x11, 0x03, 0x11, 0x00,
      0x3F, 0x00, 0x80, 0xFF, 0xD9,
    ]);
  }

  // Listar todas as imagens de um projeto
  Future<List<String>> getProjectImages(String projectId) async {
    try {
      final projectRef = _storage.ref('projects/$projectId');
      final listResult = await projectRef.listAll();

      final urls = <String>[];
      for (final item in listResult.items) {
        try {
          final url = await item.getDownloadURL();
          urls.add(url);
        } catch (e) {
          print('Erro ao obter URL de ${item.name}: $e');
        }
      }

      return urls;
    } catch (e) {
      print('Erro ao listar imagens do projeto: $e');
      return [];
    }
  }

  // NOVA: Limpar todas as operações forçadamente (útil para debugging)
  void forceCleanAllOperations() {
    final totalOperations =
        _projectsBeingCreated.length +
        _projectsBeingUpdated.length +
        _projectsBeingDeleted.length +
        _imagesBeingUploaded.length;

    _projectsBeingCreated.clear();
    _projectsBeingUpdated.clear();
    _projectsBeingDeleted.clear();
    _imagesBeingUploaded.clear();
    _operationTimestamp.clear();

    print('🧹 $totalOperations operações limpas forçadamente');
  }

  // NOVA: Verificar se existem operações em progresso
  bool hasOperationsInProgress() {
    _cleanupExpiredOperations();
    return _projectsBeingCreated.isNotEmpty ||
        _projectsBeingUpdated.isNotEmpty ||
        _projectsBeingDeleted.isNotEmpty ||
        _imagesBeingUploaded.isNotEmpty;
  }

  // NOVA: Obter estatísticas detalhadas das operações
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
      'oldestOperation':
          _operationTimestamp.isEmpty
              ? null
              : _operationTimestamp.values
                  .reduce((a, b) => a.isBefore(b) ? a : b)
                  .toIso8601String(),
      'newestOperation':
          _operationTimestamp.isEmpty
              ? null
              : _operationTimestamp.values
                  .reduce((a, b) => a.isAfter(b) ? a : b)
                  .toIso8601String(),
    };
  }

  // NOVA: Verificar se um projeto específico está sendo processado
  bool isProjectCurrentlyProcessing(String projectName, String projectClient) {
    final projectKey = _generateProjectKey(projectName, projectClient);
    return _isProjectBeingProcessed(projectKey);
  }

  // NOVA: Aguardar conclusão de operações específicas
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
      print('⏳ Aguardando conclusão da operação para: $projectKey');
    }
  }

  // NOVA: Método para backup de emergência - cancelar operação específica
  void cancelProjectOperation(String projectName, String projectClient) {
    final projectKey = _generateProjectKey(projectName, projectClient);

    final wasCancelled =
        _projectsBeingCreated.remove(projectKey) ||
        _projectsBeingUpdated.remove(projectKey) ||
        _projectsBeingDeleted.remove(projectKey);

    _operationTimestamp.remove(projectKey);

    if (wasCancelled) {
      print('⚠️ Operação cancelada para projeto: $projectKey');
    } else {
      print('ℹ️ Nenhuma operação ativa encontrada para: $projectKey');
    }
  }

  // NOVA: Método de diagnóstico completo
  Future<Map<String, dynamic>> runDiagnostics() async {
    print('🔍 === EXECUTANDO DIAGNÓSTICOS COMPLETOS ===');

    final diagnostics = <String, dynamic>{};

    try {
      // 1. Verificar estado das operações
      diagnostics['operations'] = getDetailedOperationStats();

      // 2. Verificar conectividade com Firestore
      final testQuery = await _projectsRef.limit(1).get();
      diagnostics['firestoreConnection'] = {
        'status': 'connected',
        'documentsFound': testQuery.docs.length,
      };

      // 3. Verificar conectividade com Storage
      try {
        final rootRef = _storage.ref();
        final listResult = await rootRef.list(ListOptions(maxResults: 1));
        diagnostics['storageConnection'] = {
          'status': 'connected',
          'itemsFound': listResult.items.length,
        };
      } catch (e) {
        diagnostics['storageConnection'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      // 4. Verificar autenticação
      diagnostics['authentication'] = {
        'isAuthenticated': isUserAuthenticated,
        'userId': _auth.currentUser?.uid,
        'userEmail': _auth.currentUser?.email,
      };

      // 5. Estatísticas gerais
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

    print('✅ Diagnósticos concluídos');
    return diagnostics;
  }

  // NOVA: Auxiliar para distribuição de status
  Map<String, int> _getStatusDistribution(List<Project> projects) {
    final distribution = <String, int>{};
    for (final project in projects) {
      final status = project.status.name;
      distribution[status] = (distribution[status] ?? 0) + 1;
    }
    return distribution;
  }

  // NOVA: Auxiliar para distribuição de clientes
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

  // NOVA: Método para recuperação de dados corrompidos
  Future<List<Project>> recoverCorruptedProjects() async {
    print('🚑 Iniciando recuperação de projetos corrompidos...');

    try {
      final snapshot = await _projectsRef.get();
      final corruptedProjects = <Project>[];
      final validProjects = <Project>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Tentar criar o projeto
          final project = Project(
            id: doc.id,
            name: data['name'] ?? 'NOME_CORROMPIDO_${doc.id}',
            client: data['client'] ?? 'CLIENTE_CORROMPIDO',
            description: data['description'] ?? '',
            status: ProjectStatus.values.firstWhere(
              (e) => e.name == (data['status'] ?? 'planning'),
              orElse: () => ProjectStatus.planning,
            ),
            startDate:
                data['startDate'] != null
                    ? (data['startDate'] as Timestamp).toDate()
                    : DateTime.now(),
            endDate:
                data['endDate'] != null
                    ? (data['endDate'] as Timestamp).toDate()
                    : null,
            budget: (data['budget'] ?? 0).toDouble(),
            currentCost: (data['currentCost'] ?? 0).toDouble(),
            location: data['location'] ?? '',
            tags:
                data['tags'] != null
                    ? List<String>.from(data['tags'])
                    : <String>[],
            teamSize: data['teamSize'] ?? 0,
            imageUrl: data['imageUrl'],
          );

          validProjects.add(project);
        } catch (e) {
          print('⚠️ Projeto corrompido encontrado: ${doc.id} - $e');

          // Criar projeto de recuperação
          final recoveryProject = Project(
            id: doc.id,
            name: 'PROJETO_RECUPERADO_${doc.id}',
            client: 'CLIENTE_RECUPERADO',
            description: 'Projeto recuperado de dados corrompidos',
            status: ProjectStatus.planning,
            startDate: DateTime.now(),
            budget: 0,
            currentCost: 0,
            location: '',
            tags: ['RECUPERADO'],
            teamSize: 0,
          );

          corruptedProjects.add(recoveryProject);
        }
      }

      print('✅ Recuperação concluída:');
      print('   - Projetos válidos: ${validProjects.length}');
      print('   - Projetos corrompidos: ${corruptedProjects.length}');

      return [...validProjects, ...corruptedProjects];
    } catch (e) {
      print('❌ Erro na recuperação: $e');
      throw Exception('Falha na recuperação de projetos: $e');
    }
  }
}
