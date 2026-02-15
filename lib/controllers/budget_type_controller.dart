import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/services/budget_type_service.dart';

class BudgetTypeController extends ChangeNotifier {
  final BudgetTypeService _service;

  BudgetTypeController(this._service);

  // Estados
  List<BudgetType> _budgetTypes = [];
  List<BudgetType> _filteredBudgetTypes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  bool _isGridView = true;

  // Getters
  List<BudgetType> get budgetTypes => _budgetTypes;
  List<BudgetType> get filteredBudgetTypes => _filteredBudgetTypes;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get isGridView => _isGridView;
  bool get hasActiveFilters => _searchQuery.isNotEmpty || _selectedFilter != 'Todos';

  // Opções de filtro disponíveis
  List<String> get filterOptions => [
    'Todos',
    'Ativos',
    'Inativos',
    'Material',
    'Mão de Obra',
    'Equipamento',
    'Serviço',
  ];

  // Carregar tipos de orçamento
  Future<void> loadBudgetTypes({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _setLoading(true);
    _clearError();

    try {
      final budgetTypes = await _service.getBudgetTypes();
      _budgetTypes = budgetTypes;
      _applyFilters();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Criar tipo de orçamento
  Future<bool> createBudgetType(BudgetType budgetType) async {
    try {
      _clearError();
      
      // Verificar se nome já existe
      final nameExists = await _service.budgetTypeNameExists(budgetType.name);
      if (nameExists) {
        _setError('Já existe um tipo de orçamento com este nome');
        return false;
      }

      await _service.createBudgetType(budgetType);
      await loadBudgetTypes(forceRefresh: true);
      return true;
    } catch (e) {
      _setError('Erro ao criar tipo de orçamento: $e');
      return false;
    }
  }

  // Atualizar tipo de orçamento
  Future<bool> updateBudgetType(BudgetType budgetType) async {
    try {
      _clearError();
      
      // Verificar se nome já existe (excluindo o atual)
      final nameExists = await _service.budgetTypeNameExists(
        budgetType.name,
        excludeId: budgetType.id,
      );
      if (nameExists) {
        _setError('Já existe um tipo de orçamento com este nome');
        return false;
      }

      await _service.updateBudgetType(budgetType);
      await loadBudgetTypes(forceRefresh: true);
      return true;
    } catch (e) {
      _setError('Erro ao atualizar tipo de orçamento: $e');
      return false;
    }
  }

  // Deletar tipo de orçamento
  Future<bool> deleteBudgetType(String id) async {
    try {
      _clearError();
      await _service.deleteBudgetType(id);
      await loadBudgetTypes(forceRefresh: true);
      return true;
    } catch (e) {
      _setError('Erro ao deletar tipo de orçamento: $e');
      return false;
    }
  }

  // Alternar status (ativo/inativo)
  Future<bool> toggleBudgetTypeStatus(String id, bool isActive) async {
    try {
      _clearError();
      await _service.toggleBudgetTypeStatus(id, isActive);
      await loadBudgetTypes(forceRefresh: true);
      return true;
    } catch (e) {
      _setError('Erro ao alterar status: $e');
      return false;
    }
  }

  // Atualizar busca
  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilters();
    }
  }

  // Atualizar filtro
  void updateFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      _applyFilters();
    }
  }

  // Limpar filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedFilter = 'Todos';
    _applyFilters();
  }

  // Alterar modo de visualização
  void setViewMode(bool isGrid) {
    if (_isGridView != isGrid) {
      _isGridView = isGrid;
      notifyListeners();
    }
  }

  // Aplicar filtros
  void _applyFilters() {
    List<BudgetType> filtered = List.from(_budgetTypes);

    // Filtro de busca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((budgetType) {
        return budgetType.name.toLowerCase().contains(query) ||
               budgetType.description.toLowerCase().contains(query) ||
               budgetType.category.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por categoria/status
    switch (_selectedFilter) {
      case 'Ativos':
        filtered = filtered.where((bt) => bt.isActive).toList();
        break;
      case 'Inativos':
        filtered = filtered.where((bt) => !bt.isActive).toList();
        break;
      case 'Material':
      case 'Mão de Obra':
      case 'Equipamento':
      case 'Serviço':
        filtered = filtered.where((bt) => bt.category == _selectedFilter).toList();
        break;
    }

    _filteredBudgetTypes = filtered;
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

}