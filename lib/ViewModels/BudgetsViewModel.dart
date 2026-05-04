import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';

class BudgetsViewModel extends ChangeNotifier {
  final ServiceOrcamentos _service;

  List<Budget> _allBudgets = [];
  List<Budget> filteredBudgets = [];

  bool isLoading = true;
  String? errorMessage;

  BudgetStatus filterStatus = BudgetStatus.pending;
  bool isFiltering = false;
  bool isUpdatingExpired = false;
  String searchQuery = '';

  // IDs de orçamentos em aprovação para evitar double-tap
  final Set<String> approvingIds = {};

  StreamSubscription? _subscription;

  // Injeção de dependência via construtor
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
      temp = temp.where((b) => b.status == filterStatus).toList();
    }

    if (searchQuery.isNotEmpty) {
      final term = searchQuery.toLowerCase();
      temp =
          temp
              .where(
                (b) =>
                    b.clientName.toLowerCase().contains(term) ||
                    b.projectName.toLowerCase().contains(term),
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

  // ─── LÓGICA DE NEGÓCIO ──────────────────────────────────────────────────

  Future<void> forceCheckExpiredBudgets({
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    isUpdatingExpired = true;
    notifyListeners();
    try {
      await _service.forceUpdateExpiredBudgets();
      onSuccess?.call('Verificando Orçamentos Expirados...');
    } catch (e) {
      onError?.call('Erro ao verificar orçamentos expirados: $e');
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
      onSuccess?.call('Orçamento aprovado! Projeto criado em Planejamento.');
    } catch (e) {
      onError?.call('Erro ao aprovar orçamento: $e');
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
      onSuccess?.call('Orçamento rejeitado.');
    } catch (e) {
      onError?.call('Erro ao rejeitar: $e');
    }
  }

  Future<void> deleteBudget(
    Budget budget, {
    Function(String)? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      await _service.deleteBudget(budget.id);
      onSuccess?.call(
        'Orçamento de "${budget.clientName}" excluído com sucesso!',
      );
    } catch (e) {
      onError?.call('Erro ao excluir orçamento: $e');
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
