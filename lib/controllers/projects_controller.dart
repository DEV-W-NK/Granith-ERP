import 'package:flutter/foundation.dart';
import 'package:project_granith/Services/service_projetos.dart';
import 'package:project_granith/models/project_model.dart';

class ProjectsController extends ChangeNotifier {
  final ServiceProjetos _serviceProjects;

  ProjectsController(this._serviceProjects);

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

  // Adicionar projeto
  Future<String> addProject(Project project) async {
    if (_isSaving) {
      throw Exception('Já existe uma operação de salvamento em andamento');
    }

    try {
      setSaving(true);
      
      // Validar projeto antes de salvar
      _validateProject(project);
      
      final projectId = await _serviceProjects.addProject(project);
      
      // Adicionar à lista local imediatamente para feedback visual
      final newProject = project.copyWith(id: projectId);
      _projects.add(newProject);
      _applyFilters();
      
      print('✅ Projeto adicionado: ${project.name} (ID: $projectId)');
      
      return projectId;
      
    } catch (e) {
      print('❌ Erro ao adicionar projeto: $e');
      rethrow;
    } finally {
      setSaving(false);
    }
  }

  // Atualizar projeto
  Future<void> updateProject(Project project) async {
    if (_isSaving) {
      throw Exception('Já existe uma operação de salvamento em andamento');
    }

    if (project.id == null || project.id!.isEmpty) {
      throw Exception('ID do projeto é obrigatório para atualização');
    }

    try {
      setSaving(true);
      
      // Validar projeto antes de salvar
      _validateProject(project);
      
      await _serviceProjects.updateProject(project);
      
      // Atualizar na lista local imediatamente
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
        _applyFilters();
      }
      
      print('✅ Projeto atualizado: ${project.name}');
      
    } catch (e) {
      print('❌ Erro ao atualizar projeto: $e');
      rethrow;
    } finally {
      setSaving(false);
    }
  }

  // Deletar projeto
  Future<void> deleteProject(String? projectId) async {
    if (_isDeleting) {
      throw Exception('Já existe uma operação de exclusão em andamento');
    }

    if (projectId == null || projectId.isEmpty) {
      throw Exception('ID do projeto é obrigatório para exclusão');
    }

    try {
      setDeleting(true);
      
      await _serviceProjects.deleteProject(projectId);
      
      // Remover da lista local imediatamente
      _projects.removeWhere((project) => project.id == projectId);
      _applyFilters();
      
      print('✅ Projeto deletado: $projectId');
      
    } catch (e) {
      print('❌ Erro ao deletar projeto: $e');
      rethrow;
    } finally {
      setDeleting(false);
    }
  }

  // Verificar se projeto existe
  Future<bool> projectExists(String name, String client, {String? excludeId}) async {
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

  // Filtros e busca
  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  void updateFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      _applyFilters();
    }
  }

  void clearFilters() {
    bool hasChanges = false;
    
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
      filtered = filtered.where((project) {
        return project.name.toLowerCase().contains(query) ||
               project.client.toLowerCase().contains(query) ||
               project.description.toLowerCase().contains(query) ||
               project.location.toLowerCase().contains(query) ||
               project.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Aplicar filtro de status
    if (_selectedFilter != 'Todos') {
      final status = ProjectStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == _selectedFilter.toLowerCase(),
        orElse: () => ProjectStatus.planning,
      );
      filtered = filtered.where((project) => project.status == status).toList();
    }

    // Ordenar por data de criação (mais recente primeiro) ou nome
    filtered.sort((a, b) {
      // Se ambos têm startDate, ordenar por ela
      if (a.startDate != null && b.startDate != null) {
        return b.startDate!.compareTo(a.startDate!);
      }
      // Caso contrário, ordenar por nome
      return a.name.compareTo(b.name);
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
    
    if (project.endDate != null && project.endDate!.isBefore(project.startDate)) {
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
    };
  }

  // Buscar projetos por cliente
  List<Project> getProjectsByClient(String client) {
    return _projects.where((project) => 
      project.client.toLowerCase() == client.toLowerCase()
    ).toList();
  }

  // Buscar projetos por status
  List<Project> getProjectsByStatus(ProjectStatus status) {
    return _projects.where((project) => project.status == status).toList();
  }

  // Buscar projetos vencidos (data de término passou)
  List<Project> getOverdueProjects() {
    final now = DateTime.now();
    return _projects.where((project) => 
      project.endDate != null && 
      project.endDate!.isBefore(now) &&
      project.status != ProjectStatus.completed
    ).toList();
  }

  // Buscar projetos próximos do prazo (próximos 7 dias)
  List<Project> getUpcomingDeadlineProjects({int days = 7}) {
    final now = DateTime.now();
    final deadline = now.add(Duration(days: days));
    
    return _projects.where((project) => 
      project.endDate != null && 
      project.endDate!.isAfter(now) &&
      project.endDate!.isBefore(deadline) &&
      project.status != ProjectStatus.completed
    ).toList();
  }

  // Limpar cache e recarregar
  Future<void> refreshData() async {
    await loadProjects(forceRefresh: true);
  }

  @override
  void dispose() {
    // Limpar qualquer timer ou stream subscription se houver
    super.dispose();
  }
}