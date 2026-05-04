import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/reports_chart_models.dart';
import 'package:project_granith/services/financial_service.dart';

class ReportsController extends ChangeNotifier {
  final FinancialService _financialService;

  ReportsController({FinancialService? financialService})
    : _financialService = financialService ?? FinancialService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DateTime? periodFrom;
  DateTime? periodTo;

  void setPeriod(DateTime? from, DateTime? to) {
    periodFrom = from;
    periodTo = to;
    notifyListeners();
  }

  void setCurrentYear() {
    final now = DateTime.now();
    periodFrom = DateTime(now.year);
    periodTo = DateTime(now.year, 12, 31, 23, 59, 59);
    notifyListeners();
  }

  void setCurrentMonth() {
    final now = DateTime.now();
    periodFrom = DateTime(now.year, now.month);
    periodTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    notifyListeners();
  }

  void clearPeriod() {
    periodFrom = null;
    periodTo = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> generateReport(String reportType) async {
    _isLoading = true;
    notifyListeners();
    try {
      switch (reportType) {
        case 'financial_dre':
          return _buildDRE();
        case 'costs_by_project':
          return _buildCostsByProject();
        case 'cash_flow':
          return _buildCashFlow();
        case 'inventory_position':
          return _buildInventoryPosition();
        case 'daily_log_summary':
          return _buildDailyLogSummary();
        default:
          return [];
      }
    } catch (e) {
      debugPrint('[ReportsController] Erro ao gerar relatorio $reportType: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MonthlyChartData>> fetchMonthlyData() async {
    final from = periodFrom ?? DateTime(DateTime.now().year);
    final to = periodTo ?? DateTime(DateTime.now().year, 12, 31, 23, 59, 59);
    final transactions = await _fetchTransactions(from: from, to: to);
    final map = <String, ({double income, double expense})>{};

    for (final t in transactions) {
      if (t.status != TransactionStatus.paid) continue;
      final key =
          '${t.dueDate.year}-${t.dueDate.month.toString().padLeft(2, '0')}';
      final current = map[key] ?? (income: 0.0, expense: 0.0);

      map[key] =
          t.type == TransactionType.income
              ? (income: current.income + t.amount, expense: current.expense)
              : (income: current.income, expense: current.expense + t.amount);
    }

    final result = <MonthlyChartData>[];
    var cursor = DateTime(from.year, from.month);
    final end = DateTime(to.year, to.month);

    while (!cursor.isAfter(end)) {
      final key = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
      final entry = map[key] ?? (income: 0.0, expense: 0.0);
      result.add(
        MonthlyChartData(
          label: _monthName(cursor.month),
          income: entry.income,
          expense: entry.expense,
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return result;
  }

  Future<List<CategoryChartData>> fetchExpensesByCategory() async {
    final from = periodFrom ?? DateTime(DateTime.now().year);
    final to = periodTo ?? DateTime(DateTime.now().year, 12, 31, 23, 59, 59);
    final raw = await _financialService.getSumByCategory(
      type: TransactionType.expense,
      from: from,
      to: to,
    );

    const labels = <String, String>{
      'material': 'Materiais',
      'labor': 'Mao de Obra',
      'equipment': 'Equipamentos',
      'administrative': 'Administrativo',
      'tax': 'Impostos',
      'measurement': 'Medicoes',
      'other': 'Outros',
    };

    return raw.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => CategoryChartData(
            label: labels[entry.key] ?? entry.key,
            value: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Future<List<Map<String, dynamic>>> _buildDRE() async {
    final transactions = await _fetchTransactions();
    final totalIncome = _sum(
      transactions,
      type: TransactionType.income,
      status: TransactionStatus.paid,
    );

    final byCategory = <TransactionCategory, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.status == TransactionStatus.paid) {
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }

    final material = byCategory[TransactionCategory.material] ?? 0;
    final labor = byCategory[TransactionCategory.labor] ?? 0;
    final equipment = byCategory[TransactionCategory.equipment] ?? 0;
    final admin = byCategory[TransactionCategory.administrative] ?? 0;
    final tax = byCategory[TransactionCategory.tax] ?? 0;
    final other = byCategory[TransactionCategory.other] ?? 0;
    final measurement = byCategory[TransactionCategory.measurement] ?? 0;

    final directCosts = material + labor + equipment;
    final netRevenue = totalIncome - tax;
    final grossProfit = netRevenue - directCosts;
    final result = grossProfit - admin - other;

    return [
      _header('Receita Bruta', totalIncome),
      if (measurement > 0) _line('  Medicoes / Faturamento', measurement),
      if (tax > 0) _line('(-) Impostos e Taxas', -tax),
      _result('(=) Receita Liquida', netRevenue),
      _header('Custos Diretos', -directCosts, negative: true),
      if (material > 0) _line('  (-) Materiais', -material),
      if (labor > 0) _line('  (-) Mao de Obra', -labor),
      if (equipment > 0) _line('  (-) Equipamentos', -equipment),
      _result('(=) Lucro Bruto', grossProfit),
      if (admin > 0) _line('(-) Despesas Administrativas', -admin),
      if (other > 0) _line('(-) Outras Despesas', -other),
      _result('(=) Resultado Operacional', result, highlight: true),
    ];
  }

  Future<List<Map<String, dynamic>>> _buildCostsByProject() async {
    final transactions = await _fetchTransactions();
    final projects = await _fetchProjects();
    final costMap = <String, double>{};
    final incomeMap = <String, double>{};

    for (final t in transactions) {
      final projectId = t.projectId;
      if (projectId == null) continue;

      if (t.type == TransactionType.expense &&
          t.status == TransactionStatus.paid) {
        costMap[projectId] = (costMap[projectId] ?? 0) + t.amount;
      }
      if (t.type == TransactionType.income &&
          t.status == TransactionStatus.paid) {
        incomeMap[projectId] = (incomeMap[projectId] ?? 0) + t.amount;
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final project in projects) {
      final cost = costMap[project['id']] ?? 0.0;
      final income = incomeMap[project['id']] ?? 0.0;
      final budget = (project['budget'] as num?)?.toDouble() ?? 0.0;
      final percent =
          budget > 0 ? (cost / budget * 100).clamp(0.0, 999.0) : 0.0;

      result.add({
        'concept': project['name'] ?? 'Projeto sem nome',
        'value': cost,
        'income': income,
        'budget': budget,
        'percent': percent,
        'detail': '${percent.toStringAsFixed(1)}% do orcamento',
        'isOverBudget': cost > budget && budget > 0,
      });
    }

    result.sort(
      (a, b) => (b['value'] as double).compareTo(a['value'] as double),
    );

    final totalCost = result.fold(0.0, (sum, row) => sum + row['value']);
    final totalIncome = result.fold(0.0, (sum, row) => sum + row['income']);
    result.add({
      'concept': 'TOTAL',
      'value': totalCost,
      'income': totalIncome,
      'budget': 0.0,
      'percent': 0.0,
      'detail': '${result.length} projeto(s)',
      'isHeader': true,
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> _buildCashFlow() async {
    final transactions = await _fetchTransactions();
    final monthMap = <String, ({double income, double expense})>{};

    for (final t in transactions) {
      if (t.status != TransactionStatus.paid) continue;
      final key =
          '${t.dueDate.year}-${t.dueDate.month.toString().padLeft(2, '0')}';
      final current = monthMap[key] ?? (income: 0.0, expense: 0.0);
      monthMap[key] =
          t.type == TransactionType.income
              ? (income: current.income + t.amount, expense: current.expense)
              : (income: current.income, expense: current.expense + t.amount);
    }

    final sorted =
        monthMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    var accumulated = 0.0;
    return sorted.map((entry) {
      final parts = entry.key.split('-');
      final income = entry.value.income;
      final expense = entry.value.expense;
      final balance = income - expense;
      accumulated += balance;
      return {
        'concept': '${_monthName(int.parse(parts[1]))}/${parts[0]}',
        'value': balance,
        'income': income,
        'expense': expense,
        'acumulado': accumulated,
        'detail': 'Entradas: $income | Saidas: $expense',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _buildInventoryPosition() async {
    final response = await AppSupabase.client
        .from('inventory')
        .select()
        .order('name');

    return (response as List).map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      final quantity = (data['quantity'] as num? ?? 0).toDouble();
      final minQuantity = (data['minQuantity'] as num? ?? 0).toDouble();
      return {
        'concept': data['name'] ?? '',
        'value': quantity,
        'detail': data['unit'] ?? 'un',
        'minQuantity': minQuantity,
        'isLowStock': minQuantity > 0 && quantity <= minQuantity,
        'isOutOfStock': quantity <= 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _buildDailyLogSummary() async {
    dynamic query = AppSupabase.client.from('daily_logs').select();

    if (periodFrom != null) {
      query = query.gte('date', DbValue.toPrimitive(periodFrom!));
    }
    if (periodTo != null) {
      query = query.lte('date', DbValue.toPrimitive(periodTo!));
    }

    final response = await query.order('date', ascending: false).limit(100);
    final projectMap = <String, ({int logs, int workers})>{};

    for (final row in response as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final projectName = data['projectName'] as String? ?? 'Projeto';
      final manpower = Map<String, dynamic>.from(data['manpower'] ?? {});
      final workers = manpower.values.fold<int>(
        0,
        (sum, value) => sum + (value as num? ?? 0).toInt(),
      );
      final current = projectMap[projectName] ?? (logs: 0, workers: 0);
      projectMap[projectName] = (
        logs: current.logs + 1,
        workers: current.workers + workers,
      );
    }

    return projectMap.entries
        .map(
          (entry) => {
            'concept': entry.key,
            'value': entry.value.logs,
            'detail': '${entry.value.workers} trabalhador(es) no periodo',
          },
        )
        .toList();
  }

  Future<List<FinancialTransactionModel>> _fetchTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    final f = from ?? periodFrom;
    final t = to ?? periodTo;
    dynamic query = AppSupabase.client.from('financial_transactions').select();

    if (f != null) {
      query = query.gte('dueDate', DbValue.toPrimitive(f));
    }
    if (t != null) {
      query = query.lte('dueDate', DbValue.toPrimitive(t));
    }

    final response = await query;
    return (response as List).map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      return FinancialTransactionModel.fromMap(
        data,
        data['id'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchProjects() async {
    final response = await AppSupabase.client.from('projects').select();
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  double _sum(
    List<FinancialTransactionModel> transactions, {
    required TransactionType type,
    required TransactionStatus status,
  }) {
    return transactions
        .where(
          (transaction) =>
              transaction.type == type && transaction.status == status,
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  Map<String, dynamic> _header(
    String concept,
    double value, {
    bool negative = false,
  }) {
    return {
      'concept': concept,
      'value': value,
      'isHeader': true,
      'negative': negative,
    };
  }

  Map<String, dynamic> _line(String concept, double value) {
    return {'concept': concept, 'value': value, 'isHeader': false};
  }

  Map<String, dynamic> _result(
    String concept,
    double value, {
    bool highlight = false,
  }) {
    return {
      'concept': concept,
      'value': value,
      'isResult': true,
      'highlight': highlight,
    };
  }

  String _monthName(int month) {
    const names = [
      '',
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
    return names[month];
  }
}
