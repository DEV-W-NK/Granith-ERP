import 'dart:async';

import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';

class FakeServiceOrcamentos extends ServiceOrcamentos {
  FakeServiceOrcamentos({List<Budget>? initialBudgets})
    : _budgets = List<Budget>.from(initialBudgets ?? const <Budget>[]);

  final StreamController<List<Budget>> _controller =
      StreamController<List<Budget>>.broadcast();
  final List<Budget> _budgets;

  bool forceUpdateCalled = false;
  Object? forceUpdateError;
  Object? approveError;
  Object? rejectError;
  Object? deleteError;

  Budget? approvedBudget;
  String? rejectedBudgetId;
  String? deletedBudgetId;
  Budget? lastAddedBudget;
  Budget? lastUpdatedBudget;

  void emitBudgets([List<Budget>? budgets]) {
    if (budgets != null) {
      _budgets
        ..clear()
        ..addAll(budgets);
    }
    _controller.add(List<Budget>.from(_budgets));
  }

  @override
  Stream<List<Budget>> getBudgets() => _controller.stream;

  @override
  Future<void> forceUpdateExpiredBudgets() async {
    forceUpdateCalled = true;
    if (forceUpdateError != null) {
      throw forceUpdateError!;
    }
  }

  @override
  Future<String> approveBudget(Budget budget) async {
    approvedBudget = budget;
    if (approveError != null) {
      throw approveError!;
    }
    return 'project-from-budget';
  }

  @override
  Future<void> rejectBudget(String budgetId) async {
    rejectedBudgetId = budgetId;
    if (rejectError != null) {
      throw rejectError!;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    deletedBudgetId = id;
    if (deleteError != null) {
      throw deleteError!;
    }
    _budgets.removeWhere((budget) => budget.id == id);
  }

  @override
  Future<void> addBudget(Budget budget) async {
    lastAddedBudget = budget;
    _budgets.add(budget);
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    lastUpdatedBudget = budget;
    final index = _budgets.indexWhere((item) => item.id == budget.id);
    if (index >= 0) {
      _budgets[index] = budget;
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
