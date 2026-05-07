import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/models/project_model.dart';

class ProjectsController extends ChangeNotifier {
  final ServiceProjetos _serviceProjects;
  final Duration _saveDebounceDelay;
  final Duration _updateDebounceDelay;
  final Duration _deleteDebounceDelay;
  final Duration _searchDebounceDelay;

  ProjectsController(
    this._serviceProjects, {
    Duration saveDebounceDelay = const Duration(milliseconds: 500),
    Duration updateDebounceDelay = const Duration(milliseconds: 300),
    Duration deleteDebounceDelay = const Duration(milliseconds: 800),
    Duration searchDebounceDelay = const Duration(milliseconds: 300),
  }) : _saveDebounceDelay = saveDebounceDelay,
       _updateDebounceDelay = updateDebounceDelay,
       _deleteDebounceDelay = deleteDebounceDelay,
       _searchDebounceDelay = searchDebounceDelay;

  // Estados da aplicação
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  bool _isGridView = true;
  bool get hasError => _errorMessage != null;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedFilter != 'Todos';

  // NOVA: Controle de debounce para operações
  Timer? _saveDebounceTimer;
  Timer? _updateDebounceTimer;
  Timer? _deleteDebounceTimer;
  Timer? _searchDebounceTimer;

  // NOVA: Mapa para rastrear operações pendentes por projeto
  final Map<String, Completer<String>> _pendingCreateOperations = {};
  final Map<String, Completer<void>> _pendingUpdateOperations = {};
  final Map<String, Completer<void>> _pendingDeleteOperations = {};

  // Getters
  List<Project> get projects => _projects;
  List<Project> get filteredProjects => _filteredProjects;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get isGridView => _isGridView;

  // NOVA: Getters para status das operações com debounce
  bool get hasPendingOperations =>
      _pendingCreateOperations.isNotEmpty ||
      _pendingUpdateOperations.isNotEmpty ||
      _pendingDeleteOperations.isNotEmpty;

  int get pendingOperationsCount =>
      _pendingCreateOperations.length +
      _pendingUpdateOperations.length +
      _pendingDeleteOperations.length;

  // Controle de estados de operação
  void setSaving(bool value) {
    if (_isSaving != value) {
      _isSaving = value;
      notifyListeners();
    }
  }

  void setDeleting(bool value) {
    if (_isDeleting != value) {
      _isDeleting = value;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String? message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  // NOVA: Gerar chave única para operações
  String _generateOperationKey(Project project) {
    return '${project.name.trim().toLowerCase()}_${project.client.trim().toLowerCase()}';
  }

  // Carregar projetos
  Future<void> loadProjects({bool forceRefresh = false}) async {
    // Evitar múltiplas carregamentos simultâneos
    if (_isLoading && !forceRefresh) return;

    try {
      _setLoading(true);
      _setError(null);

      final projects = await _serviceProjects.getProjects();

      _projects = projects;
      _applyFilters();

      print('✅ ${projects.length} projetos carregados com sucesso');
    } catch (e) {
      _setError(e.toString());
      print('❌ Erro ao carregar projetos: $e');

      // Em caso de erro, manter a lista atual se houver
      if (_projects.isEmpty) {
        _filteredProjects = [];
      }
    } finally {
      _setLoading(false);
    }
  }

  // NOVA: Adicionar projeto com debounce
  Future<String> addProject(Project project) async {
    final operationKey = _generateOperationKey(project);

    // Verificar se já existe operação pendente para este projeto
    if (_pendingCreateOperations.containsKey(operationKey)) {
      print('⏳ Operação de criação já pendente para: ${project.name}');
      return _pendingCreateOperations[operationKey]!.future;
    }

    // Cancelar timer anterior se existir
    _saveDebounceTimer?.cancel();

    final completer = Completer<String>();
    _pendingCreateOperations[operationKey] = completer;

    print(
      '🔄 Agendando criação do projeto: ${project.name} (${_saveDebounceDelay.inMilliseconds}ms)',
    );

    // Criar timer com delay para debounce
    _saveDebounceTimer = Timer(_saveDebounceDelay, () async {
      try {
        // Verificar se o completer ainda está válido
        if (!_pendingCreateOperations.containsKey(operationKey)) {
          print('⚠️ Operação cancelada antes da execução: ${project.name}');
          return;
        }

        // Verificar se já existe outra operação de salvamento
        if (_isSaving) {
          final error = 'Já existe uma operação de salvamento em andamento';
          print('❌ $error');
          completer.completeError(Exception(error));
          return;
        }

        setSaving(true);

        // Validar projeto antes de salvar
        _validateProject(project);

        print('💾 Executando criação do projeto: ${project.name}');
        final projectId = await _serviceProjects.addProject(project);

        // Adicionar à lista local imediatamente para feedback visual
        final newProject = project.copyWith(id: projectId);
        _projects.add(newProject);
        _applyFilters();

        print(
          '✅ Projeto adicionado com sucesso: ${project.name} (ID: $projectId)',
        );
        completer.complete(projectId);
      } catch (e) {
        print('❌ Erro ao adicionar projeto: $e');
        completer.completeError(e);
      } finally {
        setSaving(false);
        _pendingCreateOperations.remove(operationKey);
      }
    });

    return completer.future;
  }

  // NOVA: Atualizar projeto com debounce
  Future<void> updateProject(Project project) async {
    if (project.id.isEmpty) {
      throw Exception('ID do projeto é obrigatório para atualização');
    }

    final operationKey = project.id;

    // Verificar se já existe operação pendente para este projeto
    if (_pendingUpdateOperations.containsKey(operationKey)) {
      print('⏳ Operação de atualização já pendente para: ${project.name}');
      return _pendingUpdateOperations[operationKey]!.future;
    }

    // Cancelar timer anterior se existir
    _updateDebounceTimer?.cancel();

    final completer = Completer<void>();
    _pendingUpdateOperations[operationKey] = completer;

    print(
      '🔄 Agendando atualização do projeto: ${project.name} (${_updateDebounceDelay.inMilliseconds}ms)',
    );

    // Criar timer com delay para debounce
    _updateDebounceTimer = Timer(_updateDebounceDelay, () async {
      try {
        // Verificar se o completer ainda está válido
        if (!_pendingUpdateOperations.containsKey(operationKey)) {
          print('⚠️ Operação de atualização cancelada: ${project.name}');
          return;
        }

        if (_isSaving) {
          final error = 'Já existe uma operação de salvamento em andamento';
          print('❌ $error');
          completer.completeError(Exception(error));
          return;
        }

        setSaving(true);

        // Validar projeto antes de salvar
        _validateProject(project);

        print('💾 Executando atualização do projeto: ${project.name}');
        await _serviceProjects.updateProject(project);

        // Atualizar na lista local imediatamente
        final index = _projects.indexWhere((p) => p.id == project.id);
        if (index != -1) {
          _projects[index] = project;
          _applyFilters();
        }

        print('✅ Projeto atualizado com sucesso: ${project.name}');
        completer.complete();
      } catch (e) {
        print('❌ Erro ao atualizar projeto: $e');
        completer.completeError(e);
      } finally {
        setSaving(false);
        _pendingUpdateOperations.remove(operationKey);
      }
    });

    return completer.future;
  }

  // NOVA: Deletar projeto com debounce
  Future<void> deleteProject(String? projectId) async {
    if (projectId == null || projectId.isEmpty) {
      throw Exception('ID do projeto é obrigatório para exclusão');
    }

    // Verificar se já existe operação pendente para este projeto
    if (_pendingDeleteOperations.containsKey(projectId)) {
      print('⏳ Operação de exclusão já pendente para: $projectId');
      return _pendingDeleteOperations[projectId]!.future;
    }

    // Cancelar timer anterior se existir
    _deleteDebounceTimer?.cancel();

    final completer = Completer<void>();
    _pendingDeleteOperations[projectId] = completer;

    // Encontrar o projeto para log
    final project = _projects.firstWhere(
      (p) => p.id == projectId,
      orElse:
          () => Project(
            name: 'PROJETO_NAO_ENCONTRADO',
            client: '',
            startDate: DateTime.now(),
            budget: 0,
            currentCost: 0,
            teamSize: 0,
            status: ProjectStatus.planning,
            location: '',
            description: '',
            tags: [],
          ),
    );

    print(
      '🔄 Agendando exclusão do projeto: ${project.name} (${_deleteDebounceDelay.inMilliseconds}ms)',
    );

    // Criar timer com delay maior para deletar (operação mais crítica)
    _deleteDebounceTimer = Timer(_deleteDebounceDelay, () async {
      try {
        // Verificar se o completer ainda está válido
        if (!_pendingDeleteOperations.containsKey(projectId)) {
          print('⚠️ Operação de exclusão cancelada: ${project.name}');
          return;
        }

        if (_isDeleting) {
          final error = 'Já existe uma operação de exclusão em andamento';
          print('❌ $error');
          completer.completeError(Exception(error));
          return;
        }

        setDeleting(true);

        print('🗑️ Executando exclusão do projeto: ${project.name}');
        await _serviceProjects.deleteProject(projectId);

        // Remover da lista local imediatamente
        _projects.removeWhere((project) => project.id == projectId);
        _applyFilters();

        print('✅ Projeto deletado com sucesso: $projectId');
        completer.complete();
      } catch (e) {
        print('❌ Erro ao deletar projeto: $e');
        completer.completeError(e);
      } finally {
        setDeleting(false);
        _pendingDeleteOperations.remove(projectId);
      }
    });

    return completer.future;
  }

  // NOVA: Cancelar operação pendente específica
  bool cancelPendingOperation(
    String projectIdentifier, {
    String operationType = 'all',
  }) {
    bool cancelled = false;

    switch (operationType) {
      case 'create':
        if (_pendingCreateOperations.containsKey(projectIdentifier)) {
          _pendingCreateOperations[projectIdentifier]!.completeError(
            Exception('Operação cancelada pelo usuário'),
          );
          _pendingCreateOperations.remove(projectIdentifier);
          cancelled = true;
        }
        break;

      case 'update':
        if (_pendingUpdateOperations.containsKey(projectIdentifier)) {
          _pendingUpdateOperations[projectIdentifier]!.completeError(
            Exception('Operação cancelada pelo usuário'),
          );
          _pendingUpdateOperations.remove(projectIdentifier);
          cancelled = true;
        }
        break;

      case 'delete':
        if (_pendingDeleteOperations.containsKey(projectIdentifier)) {
          _pendingDeleteOperations[projectIdentifier]!.completeError(
            Exception('Operação cancelada pelo usuário'),
          );
          _pendingDeleteOperations.remove(projectIdentifier);
          cancelled = true;
        }
        break;

      case 'all':
      default:
        // Cancelar em todos os mapas
        cancelled =
            cancelPendingOperation(
              projectIdentifier,
              operationType: 'create',
            ) ||
            cancelPendingOperation(
              projectIdentifier,
              operationType: 'update',
            ) ||
            cancelPendingOperation(projectIdentifier, operationType: 'delete');
    }

    if (cancelled) {
      print('🚫 Operação cancelada: $projectIdentifier ($operationType)');
      notifyListeners();
    }

    return cancelled;
  }

  // NOVA: Cancelar todas as operações pendentes
  void cancelAllPendingOperations() {
    int cancelledCount = 0;

    // Cancelar operações de criação
    for (final completer in _pendingCreateOperations.values) {
      completer.completeError(Exception('Operação cancelada - limpeza geral'));
      cancelledCount++;
    }
    _pendingCreateOperations.clear();

    // Cancelar operações de atualização
    for (final completer in _pendingUpdateOperations.values) {
      completer.completeError(Exception('Operação cancelada - limpeza geral'));
      cancelledCount++;
    }
    _pendingUpdateOperations.clear();

    // Cancelar operações de exclusão
    for (final completer in _pendingDeleteOperations.values) {
      completer.completeError(Exception('Operação cancelada - limpeza geral'));
      cancelledCount++;
    }
    _pendingDeleteOperations.clear();

    // Cancelar timers ativos
    _saveDebounceTimer?.cancel();
    _updateDebounceTimer?.cancel();
    _deleteDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();

    if (cancelledCount > 0) {
      print('🧹 $cancelledCount operações pendentes canceladas');
      notifyListeners();
    }
  }

  // Verificar se projeto existe
  Future<bool> projectExists(
    String name,
    String client, {
    String? excludeId,
  }) async {
    try {
      return await _serviceProjects.projectExists(
        name: name,
        client: client,
        excludeId: excludeId,
      );
    } catch (e) {
      print('❌ Erro ao verificar existência do projeto: $e');
      return false;
    }
  }

  // Upload de imagem do projeto
  Future<String?> uploadProjectImage({
    required String projectId,
    dynamic file, // File para mobile, Uint8List para web
    bool replaceExisting = true,
  }) async {
    try {
      String? imageUrl;

      if (kIsWeb && file is Uint8List) {
        imageUrl = await _serviceProjects.uploadProjectImage(
          projectId: projectId,
          webData: file,
          replaceExisting: replaceExisting,
        );
      } else if (!kIsWeb && file != null) {
        imageUrl = await _serviceProjects.uploadProjectImage(
          projectId: projectId,
          file: file,
          replaceExisting: replaceExisting,
        );
      }

      if (imageUrl != null) {
        // Atualizar projeto na lista local com nova imagem
        final projectIndex = _projects.indexWhere((p) => p.id == projectId);
        if (projectIndex != -1) {
          _projects[projectIndex] = _projects[projectIndex].copyWith(
            imageUrl: imageUrl,
          );
          _applyFilters();
        }

        print('✅ Imagem uploaded para projeto $projectId');
      }

      return imageUrl;
    } catch (e) {
      print('❌ Erro ao fazer upload da imagem: $e');
      rethrow;
    }
  }

  // NOVA: Busca com debounce
  void updateSearchQuery(String query) {
    if (_searchQuery == query) return;

    _searchQuery = query;

    // Cancelar timer anterior
    _searchDebounceTimer?.cancel();

    // Aplicar filtros imediatamente se query estiver vazia
    if (query.isEmpty) {
      _applyFilters();
      return;
    }

    // Criar timer para debounce da busca
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      _applyFilters();
      print('🔍 Busca aplicada: "$query"');
    });

    // Notificar imediatamente para atualizar UI (campo de busca)
    notifyListeners();
  }

  void updateFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      _applyFilters();
    }
  }

  void clearFilters() {
    bool hasChanges = false;

    // Cancelar timer de busca pendente
    _searchDebounceTimer?.cancel();

    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      hasChanges = true;
    }

    if (_selectedFilter != 'Todos') {
      _selectedFilter = 'Todos';
      hasChanges = true;
    }

    if (hasChanges) {
      _applyFilters();
    }
  }

  // Alternar modo de visualização
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // Aplicar filtros
  void _applyFilters() {
    List<Project> filtered = List.from(_projects);

    // Aplicar filtro de busca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((project) {
            return project.name.toLowerCase().contains(query) ||
                project.client.toLowerCase().contains(query) ||
                project.description.toLowerCase().contains(query) ||
                project.location.toLowerCase().contains(query) ||
                project.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();
    }

    // Aplicar filtro de status
    if (_selectedFilter != 'Todos') {
      final selected = _selectedFilter.toLowerCase();
      final status = ProjectStatus.values.firstWhere(
        (s) =>
            s.name.toLowerCase() == selected ||
            s.displayName.toLowerCase() == selected,
        orElse: () => ProjectStatus.planning,
      );
      filtered = filtered.where((project) => project.status == status).toList();
    }

    // Ordenar por data de criação (mais recente primeiro) ou nome
    filtered.sort((a, b) {
      // Se ambos têm startDate, ordenar por ela
      return b.startDate.compareTo(a.startDate);
      // Caso contrário, ordenar por nome
    });

    _filteredProjects = filtered;
    notifyListeners();

    print('🔍 Filtros aplicados: ${filtered.length} projetos encontrados');
  }

  // Validação de projeto
  void _validateProject(Project project) {
    if (project.name.trim().isEmpty) {
      throw Exception('Nome do projeto é obrigatório');
    }

    if (project.client.trim().isEmpty) {
      throw Exception('Cliente é obrigatório');
    }

    if (project.budget < 0) {
      throw Exception('Orçamento não pode ser negativo');
    }

    if (project.currentCost < 0) {
      throw Exception('Custo atual não pode ser negativo');
    }

    if (project.teamSize < 0) {
      throw Exception('Tamanho da equipe não pode ser negativo');
    }

    if (project.endDate != null &&
        project.endDate!.isBefore(project.startDate)) {
      throw Exception('Data de término não pode ser anterior à data de início');
    }
  }

  // Estatísticas dos projetos
  Map<String, dynamic> getProjectStats() {
    if (_projects.isEmpty) {
      return {
        'total': 0,
        'byStatus': <String, int>{},
        'totalBudget': 0.0,
        'totalCost': 0.0,
        'averageTeamSize': 0.0,
        'pendingOperations': pendingOperationsCount,
      };
    }

    final Map<String, int> statusCount = {};
    double totalBudget = 0.0;
    double totalCost = 0.0;
    int totalTeamSize = 0;

    for (final project in _projects) {
      // Contar por status
      final statusName = project.status.name;
      statusCount[statusName] = (statusCount[statusName] ?? 0) + 1;

      // Somar valores
      totalBudget += project.budget;
      totalCost += project.currentCost;
      totalTeamSize += project.teamSize;
    }

    return {
      'total': _projects.length,
      'byStatus': statusCount,
      'totalBudget': totalBudget,
      'totalCost': totalCost,
      'averageTeamSize': totalTeamSize / _projects.length,
      'filtered': _filteredProjects.length,
      'pendingOperations': pendingOperationsCount,
    };
  }

  // NOVA: Obter detalhes das operações pendentes
  Map<String, dynamic> getPendingOperationsDetails() {
    return {
      'createOperations': _pendingCreateOperations.keys.toList(),
      'updateOperations': _pendingUpdateOperations.keys.toList(),
      'deleteOperations': _pendingDeleteOperations.keys.toList(),
      'totalPending': pendingOperationsCount,
      'hasActiveTimers':
          _saveDebounceTimer?.isActive == true ||
          _updateDebounceTimer?.isActive == true ||
          _deleteDebounceTimer?.isActive == true ||
          _searchDebounceTimer?.isActive == true,
    };
  }

  // Buscar projetos por cliente
  List<Project> getProjectsByClient(String client) {
    return _projects
        .where(
          (project) => project.client.toLowerCase() == client.toLowerCase(),
        )
        .toList();
  }

  // Buscar projetos por status
  List<Project> getProjectsByStatus(ProjectStatus status) {
    return _projects.where((project) => project.status == status).toList();
  }

  // Buscar projetos vencidos (data de término passou)
  List<Project> getOverdueProjects() {
    final now = DateTime.now();
    return _projects
        .where(
          (project) =>
              project.endDate != null &&
              project.endDate!.isBefore(now) &&
              project.status != ProjectStatus.completed,
        )
        .toList();
  }

  // Buscar projetos próximos do prazo (próximos 7 dias)
  List<Project> getUpcomingDeadlineProjects({int days = 7}) {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: days));

    return _projects
        .where(
          (project) =>
              project.endDate != null &&
              project.endDate!.isAfter(now) &&
              project.endDate!.isBefore(deadline) &&
              project.status != ProjectStatus.completed,
        )
        .toList();
  }

  // Limpar cache e recarregar
  Future<void> refreshData() async {
    await loadProjects(forceRefresh: true);
  }

  @override
  void dispose() {
    // Cancelar todas as operações pendentes e timers
    cancelAllPendingOperations();

    _saveDebounceTimer?.cancel();
    _updateDebounceTimer?.cancel();
    _deleteDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();

    super.dispose();
  }

  void setViewMode(bool isGrid) {
    if (_isGridView != isGrid) {
      _isGridView = isGrid;
      notifyListeners();
    }
  }
}
