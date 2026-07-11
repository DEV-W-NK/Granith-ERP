import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/financial_service.dart';
import 'package:project_granith/services/service_projetos.dart';

enum AdministrativeProfitScope { company, project }

class AdministrativeProfitProjectOption {
  final String id;
  final String name;
  final String client;

  const AdministrativeProfitProjectOption({
    required this.id,
    required this.name,
    required this.client,
  });

  String get label {
    final cleanClient = client.trim();
    if (cleanClient.isEmpty) return name;
    return '$name - $cleanClient';
  }
}

class AdministrativeProfitPoint {
  final DateTime month;
  final String label;
  final double income;
  final double expense;

  const AdministrativeProfitPoint({
    required this.month,
    required this.label,
    required this.income,
    required this.expense,
  });

  double get profit => income - expense;
}

class AdministrativeProfitSummary {
  final AdministrativeProfitScope scope;
  final DateTime from;
  final DateTime to;
  final AdministrativeProfitProjectOption? selectedProject;
  final double income;
  final double expense;
  final double profit;
  final double pendingIncome;
  final double pendingExpense;
  final Map<TransactionCategory, double> expensesByCategory;
  final List<AdministrativeProfitPoint> points;

  const AdministrativeProfitSummary({
    required this.scope,
    required this.from,
    required this.to,
    required this.selectedProject,
    required this.income,
    required this.expense,
    required this.profit,
    required this.pendingIncome,
    required this.pendingExpense,
    required this.expensesByCategory,
    required this.points,
  });

  bool get hasData =>
      income > 0.01 ||
      expense > 0.01 ||
      pendingIncome > 0.01 ||
      pendingExpense > 0.01;

  double get margin {
    if (income.abs() < 0.01) return 0;
    return profit / income;
  }

  double get expenseRatio {
    if (income.abs() < 0.01) return expense > 0 ? 1 : 0;
    return expense / income;
  }

  TransactionCategory? get mainExpenseCategory {
    if (expensesByCategory.isEmpty) return null;
    return expensesByCategory.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  double get mainExpenseCategoryValue {
    final category = mainExpenseCategory;
    if (category == null) return 0;
    return expensesByCategory[category] ?? 0;
  }

  static AdministrativeProfitSummary empty({
    required DateTime from,
    required DateTime to,
    AdministrativeProfitScope scope = AdministrativeProfitScope.company,
    AdministrativeProfitProjectOption? selectedProject,
  }) {
    return AdministrativeProfitSummary(
      scope: scope,
      from: from,
      to: to,
      selectedProject: selectedProject,
      income: 0,
      expense: 0,
      profit: 0,
      pendingIncome: 0,
      pendingExpense: 0,
      expensesByCategory: const {},
      points: buildEmptyPoints(from, to),
    );
  }
}

class AdministrativeProfitController extends ChangeNotifier {
  final FinancialService _financialService;
  final ServiceProjetos _projectService;
  final AppDataRefreshBus _refreshBus;
  StreamSubscription<AppDataRefreshEvent>? _refreshSubscription;
  Timer? _refreshDebounce;
  bool _disposed = false;

  AdministrativeProfitController({
    FinancialService? financialService,
    ServiceProjetos? projectService,
    AppDataRefreshBus? refreshBus,
    bool autoRefresh = true,
  }) : _financialService = financialService ?? FinancialService(),
       _projectService = projectService ?? ServiceProjetos(),
       _refreshBus = refreshBus ?? AppDataRefreshBus.instance {
    _setCurrentYear(notify: false);
    if (autoRefresh) {
      _refreshSubscription = _refreshBus.listen(const [
        AppDataRefreshBus.financialTransactions,
        AppDataRefreshBus.projects,
        AppDataRefreshBus.projectMeasurements,
        AppDataRefreshBus.purchases,
      ], (_) => _scheduleRefresh());
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AdministrativeProfitScope _scope = AdministrativeProfitScope.company;
  AdministrativeProfitScope get scope => _scope;

  DateTime _periodFrom = DateTime.now();
  DateTime get periodFrom => _periodFrom;

  DateTime _periodTo = DateTime.now();
  DateTime get periodTo => _periodTo;

  List<AdministrativeProfitProjectOption> _projects = const [];
  List<AdministrativeProfitProjectOption> get projects => _projects;

  String? _selectedProjectId;
  String? get selectedProjectId => _selectedProjectId;

  AdministrativeProfitSummary? _summary;
  AdministrativeProfitSummary? get summary => _summary;

  bool get isCurrentMonth {
    final now = DateTime.now();
    return _periodFrom.year == now.year &&
        _periodFrom.month == now.month &&
        _periodFrom.day == 1 &&
        _periodTo.year == now.year &&
        _periodTo.month == now.month &&
        _periodTo.day == DateTime(now.year, now.month + 1, 0).day;
  }

  bool get isCurrentYear {
    final now = DateTime.now();
    return _periodFrom.year == now.year &&
        _periodFrom.month == 1 &&
        _periodFrom.day == 1 &&
        _periodTo.year == now.year &&
        _periodTo.month == 12 &&
        _periodTo.day == 31;
  }

  bool get isLastNinetyDays {
    final now = DateTime.now();
    final expectedFrom = _dateOnly(now.subtract(const Duration(days: 89)));
    final expectedTo = _endOfDay(now);
    return _sameDay(_periodFrom, expectedFrom) &&
        _sameDay(_periodTo, expectedTo);
  }

  void setScope(AdministrativeProfitScope scope) {
    if (_scope == scope) return;
    _scope = scope;
    if (_scope == AdministrativeProfitScope.project &&
        _selectedProjectId == null &&
        _projects.isNotEmpty) {
      _selectedProjectId = _projects.first.id;
    }
    notifyListeners();
    unawaited(load(showLoader: false));
  }

  void selectProject(String? projectId) {
    if (_selectedProjectId == projectId) return;
    _selectedProjectId = projectId;
    notifyListeners();
    unawaited(load(showLoader: false));
  }

  void setCurrentMonth() {
    _setCurrentMonth();
    unawaited(load(showLoader: false));
  }

  void setCurrentYear() {
    _setCurrentYear();
    unawaited(load(showLoader: false));
  }

  void setLastNinetyDays() {
    final now = DateTime.now();
    _periodFrom = _dateOnly(now.subtract(const Duration(days: 89)));
    _periodTo = _endOfDay(now);
    notifyListeners();
    unawaited(load(showLoader: false));
  }

  void setPeriod(DateTime from, DateTime to) {
    _periodFrom = _dateOnly(from);
    _periodTo = _endOfDay(to);
    notifyListeners();
    unawaited(load(showLoader: false));
  }

  Future<void> load({bool showLoader = true}) async {
    if (_disposed) return;
    if (showLoader) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    try {
      final projectsFuture = _projectService.getProjects();
      final transactionsFuture = _financialService.getTransactions(
        from: _periodFrom,
        to: _periodTo,
      );
      final results = await Future.wait<dynamic>([
        projectsFuture,
        transactionsFuture,
      ]);

      final projectRows = results[0] as List<Project>;
      final transactions = results[1] as List<FinancialTransactionModel>;

      _projects =
          projectRows
              .where((project) => project.id.trim().isNotEmpty)
              .map(
                (project) => AdministrativeProfitProjectOption(
                  id: project.id,
                  name: project.name,
                  client: project.client,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label));

      if (_scope == AdministrativeProfitScope.project) {
        final selectedExists = _projects.any(
          (project) => project.id == _selectedProjectId,
        );
        if (!selectedExists) {
          _selectedProjectId = _projects.isEmpty ? null : _projects.first.id;
        }
      }

      _summary = buildSummary(
        transactions: transactions,
        projects: _projects,
        scope: _scope,
        selectedProjectId: _selectedProjectId,
        from: _periodFrom,
        to: _periodTo,
      );
    } catch (error) {
      debugPrint('[AdministrativeProfitController] load error: $error');
      _summary = AdministrativeProfitSummary.empty(
        from: _periodFrom,
        to: _periodTo,
        scope: _scope,
        selectedProject: _selectedProjectOption,
      );
      _error = 'Nao foi possivel carregar a analise administrativa.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  static AdministrativeProfitSummary buildSummary({
    required List<FinancialTransactionModel> transactions,
    required List<AdministrativeProfitProjectOption> projects,
    required AdministrativeProfitScope scope,
    required String? selectedProjectId,
    required DateTime from,
    required DateTime to,
  }) {
    final normalizedFrom = _dateOnly(from);
    final normalizedTo = _endOfDay(to);
    AdministrativeProfitProjectOption? selectedProject;
    for (final project in projects) {
      if (project.id == selectedProjectId) {
        selectedProject = project;
        break;
      }
    }
    final scopedTransactions =
        transactions.where((transaction) {
          if (transaction.status == TransactionStatus.cancelled) return false;
          if (transaction.dueDate.isBefore(normalizedFrom)) return false;
          if (transaction.dueDate.isAfter(normalizedTo)) return false;
          if (scope == AdministrativeProfitScope.project) {
            if (selectedProjectId == null || selectedProjectId.isEmpty) {
              return false;
            }
            return transaction.projectId == selectedProjectId;
          }
          return true;
        }).toList();

    final paidTransactions =
        scopedTransactions
            .where(
              (transaction) => transaction.status == TransactionStatus.paid,
            )
            .toList();

    final income = _sum(
      paidTransactions,
      (transaction) => transaction.type == TransactionType.income,
    );
    final expense = _sum(
      paidTransactions,
      (transaction) => transaction.type == TransactionType.expense,
    );
    final pendingIncome = _sum(
      scopedTransactions,
      (transaction) =>
          transaction.type == TransactionType.income &&
          transaction.status != TransactionStatus.paid,
    );
    final pendingExpense = _sum(
      scopedTransactions,
      (transaction) =>
          transaction.type == TransactionType.expense &&
          transaction.status != TransactionStatus.paid,
    );

    final categoryMap = <TransactionCategory, double>{};
    for (final transaction in paidTransactions) {
      if (transaction.type != TransactionType.expense) continue;
      categoryMap[transaction.category] =
          (categoryMap[transaction.category] ?? 0) + transaction.amount;
    }

    final byMonth =
        <String, ({DateTime month, double income, double expense})>{};
    var cursor = DateTime(normalizedFrom.year, normalizedFrom.month);
    final end = DateTime(normalizedTo.year, normalizedTo.month);
    while (!cursor.isAfter(end)) {
      final key = _monthKey(cursor);
      byMonth[key] = (month: cursor, income: 0, expense: 0);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    for (final transaction in paidTransactions) {
      final month = DateTime(
        transaction.dueDate.year,
        transaction.dueDate.month,
      );
      final key = _monthKey(month);
      final current = byMonth[key] ?? (month: month, income: 0.0, expense: 0.0);
      byMonth[key] =
          transaction.type == TransactionType.income
              ? (
                month: current.month,
                income: current.income + transaction.amount,
                expense: current.expense,
              )
              : (
                month: current.month,
                income: current.income,
                expense: current.expense + transaction.amount,
              );
    }

    final points =
        byMonth.values
            .map(
              (entry) => AdministrativeProfitPoint(
                month: entry.month,
                label: _monthLabel(entry.month),
                income: entry.income,
                expense: entry.expense,
              ),
            )
            .toList()
          ..sort((a, b) => a.month.compareTo(b.month));

    return AdministrativeProfitSummary(
      scope: scope,
      from: normalizedFrom,
      to: normalizedTo,
      selectedProject: selectedProject,
      income: income,
      expense: expense,
      profit: income - expense,
      pendingIncome: pendingIncome,
      pendingExpense: pendingExpense,
      expensesByCategory: categoryMap,
      points: points,
    );
  }

  AdministrativeProfitProjectOption? get _selectedProjectOption {
    for (final project in _projects) {
      if (project.id == _selectedProjectId) return project;
    }
    return null;
  }

  void _scheduleRefresh() {
    if (_disposed || _summary == null) return;
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 450), () {
      if (_disposed) return;
      unawaited(load(showLoader: false));
    });
  }

  void _setCurrentMonth({bool notify = true}) {
    final now = DateTime.now();
    _periodFrom = DateTime(now.year, now.month);
    _periodTo = _endOfDay(DateTime(now.year, now.month + 1, 0));
    if (notify) notifyListeners();
  }

  void _setCurrentYear({bool notify = true}) {
    final now = DateTime.now();
    _periodFrom = DateTime(now.year);
    _periodTo = _endOfDay(DateTime(now.year, 12, 31));
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshDebounce?.cancel();
    _refreshSubscription?.cancel();
    super.dispose();
  }
}

List<AdministrativeProfitPoint> buildEmptyPoints(DateTime from, DateTime to) {
  final result = <AdministrativeProfitPoint>[];
  var cursor = DateTime(from.year, from.month);
  final end = DateTime(to.year, to.month);
  while (!cursor.isAfter(end)) {
    result.add(
      AdministrativeProfitPoint(
        month: cursor,
        label: _monthLabel(cursor),
        income: 0,
        expense: 0,
      ),
    );
    cursor = DateTime(cursor.year, cursor.month + 1);
  }
  return result;
}

double _sum(
  Iterable<FinancialTransactionModel> transactions,
  bool Function(FinancialTransactionModel transaction) test,
) {
  return transactions.fold<double>(
    0,
    (sum, transaction) => test(transaction) ? sum + transaction.amount : sum,
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String _monthLabel(DateTime date) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];
  return '${months[date.month - 1]}/${date.year.toString().substring(2)}';
}
