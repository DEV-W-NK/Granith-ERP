import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';

class BudgetsViewModel extends ChangeNotifier {
  final ServiceOrcamentos _service;

  List<Budget> _allBudgets = [];
  List<Budget> filteredBudgets = [];
  List<Budget> get allBudgets => List.unmodifiable(_allBudgets);

  bool isLoading = true;
  String? errorMessage;

  BudgetStatus filterStatus = BudgetStatus.pending;
  bool isFiltering = false;
  bool isUpdatingExpired = false;
  String searchQuery = '';

  final Set<String> approvingIds = {};

  StreamSubscription? _subscription;

  BudgetsViewModel(this._service, {bool bootstrapOnInit = true}) {
    if (bootstrapOnInit) {
      _init();
    }
  }

  void _init() {
    forceCheckExpiredBudgets();
    listenToBudgets();
  }

  void listenToBudgets() {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.getBudgets().listen(
      (budgets) {
        _allBudgets = budgets;
        _applyFilters();
        isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        errorMessage = error.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  void _applyFilters() {
    var temp = _allBudgets;

    if (isFiltering) {
      temp = temp.where((budget) => budget.status == filterStatus).toList();
    }

    if (searchQuery.isNotEmpty) {
      final term = searchQuery.toLowerCase();
      temp =
          temp
              .where(
                (budget) =>
                    budget.clientName.toLowerCase().contains(term) ||
                    budget.projectName.toLowerCase().contains(term) ||
                    budget.description.toLowerCase().contains(term) ||
                    budget.status.displayName.toLowerCase().contains(term) ||
                    budget.items.any(
                      (item) => item.description.toLowerCase().contains(term),
                    ),
              )
              .toList();
    }

    filteredBudgets = temp;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilterStatus(BudgetStatus status) {
    filterStatus = status;
    isFiltering = true;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    isFiltering = false;
    filterStatus = BudgetStatus.pending;
    _applyFilters();
    notifyListeners();
  }

  Future<void> forceCheckExpiredBudgets({
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    isUpdatingExpired = true;
    notifyListeners();
    try {
      await _service.forceUpdateExpiredBudgets();
      onSuccess?.call('Verificando orcamentos expirados...');
    } catch (error) {
      onError?.call('Erro ao verificar orcamentos expirados: $error');
    } finally {
      isUpdatingExpired = false;
      notifyListeners();
    }
  }

  Future<void> approveBudget(
    Budget budget, {
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    approvingIds.add(budget.id);
    notifyListeners();

    try {
      await _service.approveBudget(budget);
      onSuccess?.call('Orcamento aprovado! Projeto criado em planejamento.');
    } catch (error) {
      onError?.call('Erro ao aprovar orcamento: $error');
    } finally {
      approvingIds.remove(budget.id);
      notifyListeners();
    }
  }

  Future<void> rejectBudget(
    Budget budget, {
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      await _service.rejectBudget(budget.id);
      onSuccess?.call('Orcamento rejeitado.');
    } catch (error) {
      onError?.call('Erro ao rejeitar: $error');
    }
  }

  Future<void> deleteBudget(
    Budget budget, {
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      await _service.deleteBudget(budget.id);
      onSuccess?.call('Orcamento de "${budget.clientName}" excluido.');
    } catch (error) {
      onError?.call('Erro ao excluir orcamento: $error');
    }
  }

  void addBudget(Budget budget) {
    _service.addBudget(budget);
  }

  void updateBudget(Budget budget) {
    _service.updateBudget(budget);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
