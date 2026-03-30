import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/reports_chart_models.dart';
import 'package:project_granith/services/financial_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REPORTS CONTROLLER — dados reais
// ─────────────────────────────────────────────────────────────────────────────

class ReportsController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FinancialService _financialService;

  ReportsController({
    FirebaseFirestore? firestore,
    FinancialService? financialService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _financialService =
            financialService ?? FinancialService(firestore: firestore);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Filtros de período ────────────────────────────────────────────────────
  DateTime? periodFrom;
  DateTime? periodTo;

  void setPeriod(DateTime? from, DateTime? to) {
    periodFrom = from;
    periodTo   = to;
    notifyListeners();
  }

  void setCurrentYear() {
    final now = DateTime.now();
    periodFrom = DateTime(now.year, 1, 1);
    periodTo   = DateTime(now.year, 12, 31, 23, 59, 59);
    notifyListeners();
  }

  void setCurrentMonth() {
    final now = DateTime.now();
    periodFrom = DateTime(now.year, now.month, 1);
    periodTo   = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    notifyListeners();
  }

  void clearPeriod() {
    periodFrom = null;
    periodTo   = null;
    notifyListeners();
  }

  // ── Entry point genérico (mantém compatibilidade) ─────────────────────────
  Future<List<Map<String, dynamic>>> generateReport(String reportType) async {
    _isLoading = true;
    notifyListeners();
    try {
      switch (reportType) {
        case 'financial_dre':      return await _buildDRE();
        case 'costs_by_project':   return await _buildCostsByProject();
        case 'cash_flow':          return await _buildCashFlow();
        case 'inventory_position': return await _buildInventoryPosition();
        case 'daily_log_summary':  return await _buildDailyLogSummary();
        default: return [];
      }
    } catch (e) {
      debugPrint('[ReportsController] Erro ao gerar relatório $reportType: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── NOVO: dados mensais para BarChart e LineChart ─────────────────────────
  //
  // Agrupa transações PAGAS por mês dentro do período selecionado.
  // Se nenhum período estiver ativo, usa o ano corrente.
  Future<List<MonthlyChartData>> fetchMonthlyData() async {
    final from = periodFrom ?? DateTime(DateTime.now().year, 1, 1);
    final to   = periodTo   ?? DateTime(DateTime.now().year, 12, 31, 23, 59, 59);

    final transactions = await _fetchTransactions(from: from, to: to);

    // Mapa: "YYYY-MM" → {income, expense}
    final map = <String, ({double income, double expense})>{};

    for (final t in transactions) {
      if (t.status != TransactionStatus.paid) continue;
      final key = '${t.dueDate.year}-${t.dueDate.month.toString().padLeft(2, '0')}';
      final cur = map[key] ?? (income: 0.0, expense: 0.0);

      if (t.type == TransactionType.income) {
        map[key] = (income: cur.income + t.amount, expense: cur.expense);
      } else {
        map[key] = (income: cur.income, expense: cur.expense + t.amount);
      }
    }

    // Garante todos os meses do período, mesmo sem dados
    final result = <MonthlyChartData>[];
    var cursor = DateTime(from.year, from.month, 1);
    final end  = DateTime(to.year, to.month, 1);

    while (!cursor.isAfter(end)) {
      final key   = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
      final entry = map[key] ?? (income: 0.0, expense: 0.0);
      result.add(MonthlyChartData(
        label:   _monthName(cursor.month),
        income:  entry.income,
        expense: entry.expense,
      ));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return result;
  }

  // ── NOVO: dados por categoria para DonutChart ─────────────────────────────
  Future<List<CategoryChartData>> fetchExpensesByCategory() async {
    final from = periodFrom ?? DateTime(DateTime.now().year, 1, 1);
    final to   = periodTo   ?? DateTime(DateTime.now().year, 12, 31, 23, 59, 59);

    final raw = await _financialService.getSumByCategory(
      type: TransactionType.expense,
      from: from,
      to:   to,
    );

    // Labels legíveis para cada categoria
    const labels = <String, String>{
      'material':       'Materiais',
      'labor':          'Mão de Obra',
      'equipment':      'Equipamentos',
      'administrative': 'Administrativo',
      'tax':            'Impostos',
      'measurement':    'Medições',
      'other':          'Outros',
    };

    return raw.entries
        .where((e) => e.value > 0)
        .map((e) => CategoryChartData(
              label: labels[e.key] ?? e.key,
              value: e.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // ─── DRE Gerencial ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buildDRE() async {
    final transactions = await _fetchTransactions();

    final totalIncome = _sum(transactions,
        type: TransactionType.income, status: TransactionStatus.paid);

    final byCategory = <TransactionCategory, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.status == TransactionStatus.paid) {
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }

    final material    = byCategory[TransactionCategory.material]       ?? 0;
    final labor       = byCategory[TransactionCategory.labor]          ?? 0;
    final equipment   = byCategory[TransactionCategory.equipment]      ?? 0;
    final admin       = byCategory[TransactionCategory.administrative]  ?? 0;
    final tax         = byCategory[TransactionCategory.tax]            ?? 0;
    final other       = byCategory[TransactionCategory.other]          ?? 0;
    final measurement = byCategory[TransactionCategory.measurement]    ?? 0;

    final custosDiretos  = material + labor + equipment;
    final receitaLiquida = totalIncome - tax;
    final lucroBruto     = receitaLiquida - custosDiretos;
    final resultado      = lucroBruto - admin - other;

    return [
      _header('Receita Bruta',    totalIncome),
      if (measurement > 0) _line('  Medições / Faturamento', measurement),
      if (tax > 0)          _line('(-) Impostos e Taxas',     -tax),
      _result('(=) Receita Líquida', receitaLiquida),

      _header('Custos Diretos', -custosDiretos, negative: true),
      if (material  > 0) _line('  (-) Materiais',     -material),
      if (labor     > 0) _line('  (-) Mão de Obra',   -labor),
      if (equipment > 0) _line('  (-) Equipamentos',  -equipment),
      _result('(=) Lucro Bruto', lucroBruto),

      if (admin > 0) _line('(-) Despesas Administrativas', -admin),
      if (other > 0) _line('(-) Outras Despesas',          -other),
      _result('(=) Resultado Operacional', resultado, highlight: true),
    ];
  }

  // ─── Custos por Projeto ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buildCostsByProject() async {
    final transactions = await _fetchTransactions();
    final projects     = await _fetchProjects();

    final costMap   = <String, double>{};
    final incomeMap = <String, double>{};

    for (final t in transactions) {
      if (t.projectId == null) continue;
      if (t.type == TransactionType.expense &&
          t.status == TransactionStatus.paid) {
        costMap[t.projectId!] = (costMap[t.projectId!] ?? 0) + t.amount;
      }
      if (t.type == TransactionType.income &&
          t.status == TransactionStatus.paid) {
        incomeMap[t.projectId!] = (incomeMap[t.projectId!] ?? 0) + t.amount;
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final p in projects) {
      final cost   = costMap[p['id']]   ?? 0.0;
      final income = incomeMap[p['id']] ?? 0.0;
      final budget = (p['budget'] as num?)?.toDouble() ?? 0.0;
      final pct    = budget > 0 ? (cost / budget * 100).clamp(0.0, 999.0) : 0.0;

      result.add({
        'concept':      p['name'] ?? 'Projeto sem nome',
        'value':        cost,
        'income':       income,
        'budget':       budget,
        'percent':      pct,
        'detail':       '${pct.toStringAsFixed(1)}% do orçamento',
        'isOverBudget': cost > budget && budget > 0,
      });
    }

    result.sort((a, b) =>
        (b['value'] as double).compareTo(a['value'] as double));

    final totalCost   = result.fold(0.0, (s, r) => s + (r['value'] as double));
    final totalIncome = result.fold(0.0, (s, r) => s + (r['income'] as double));
    result.add({
      'concept':  'TOTAL',
      'value':    totalCost,
      'income':   totalIncome,
      'budget':   0.0,
      'percent':  0.0,
      'detail':   '${result.length - 1} projeto(s)',
      'isHeader': true,
    });

    return result;
  }

  // ─── Fluxo de Caixa ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buildCashFlow() async {
    final transactions = await _fetchTransactions();
    final monthMap = <String, ({double income, double expense})>{};

    for (final t in transactions) {
      if (t.status != TransactionStatus.paid) continue;
      final key = '${t.dueDate.year}-${t.dueDate.month.toString().padLeft(2, '0')}';
      final cur = monthMap[key] ?? (income: 0.0, expense: 0.0);
      if (t.type == TransactionType.income) {
        monthMap[key] = (income: cur.income + t.amount, expense: cur.expense);
      } else {
        monthMap[key] = (income: cur.income, expense: cur.expense + t.amount);
      }
    }

    final sorted = monthMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    double acumulado = 0;
    return sorted.map((entry) {
      final parts   = entry.key.split('-');
      final income  = entry.value.income;
      final expense = entry.value.expense;
      final saldo   = income - expense;
      acumulado    += saldo;
      return {
        'concept':   '${_monthName(int.parse(parts[1]))}/${parts[0]}',
        'value':     saldo,
        'income':    income,
        'expense':   expense,
        'acumulado': acumulado,
        'detail':    'Entradas: $income | Saídas: $expense',
      };
    }).toList();
  }

  // ─── Posição de Estoque ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buildInventoryPosition() async {
    final snap = await _firestore.collection('inventory').orderBy('name').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      final qty  = (data['quantity']    ?? 0.0).toDouble();
      final min  = (data['minQuantity'] ?? 0.0).toDouble();
      return {
        'concept':      data['name'] ?? '',
        'value':        qty,
        'detail':       data['unit'] ?? 'un',
        'minQuantity':  min,
        'isLowStock':   min > 0 && qty <= min,
        'isOutOfStock': qty <= 0,
      };
    }).toList();
  }

  // ─── Resumo Diário de Obras ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buildDailyLogSummary() async {
    Query query = _firestore
        .collection('daily_logs')
        .orderBy('date', descending: true);

    if (periodFrom != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(periodFrom!));
    }
    if (periodTo != null) {
      query = query.where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(periodTo!));
    }

    final snap = await query.limit(100).get();
    final projectMap = <String, ({int logs, int workers})>{};

    for (final doc in snap.docs) {
      final data       = doc.data() as Map<String, dynamic>;
      final projectName= data['projectName'] ?? 'Projeto';
      final manpower   = data['manpower'] as Map<String, dynamic>? ?? {};
      final workers    = manpower.values.fold(0, (s, v) => s + (v as int? ?? 0));
      final cur = projectMap[projectName] ?? (logs: 0, workers: 0);
      projectMap[projectName] = (logs: cur.logs + 1, workers: cur.workers + workers);
    }

    return projectMap.entries.map((e) => {
      'concept': e.key,
      'value':   e.value.logs,
      'detail':  '${e.value.workers} trabalhador(es) no período',
    }).toList();
  }

  // ─── Helpers de leitura ───────────────────────────────────────────────────
  Future<List<FinancialTransactionModel>> _fetchTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    final f = from ?? periodFrom;
    final t = to   ?? periodTo;

    Query query = _firestore.collection('financial_transactions');
    if (f != null) {
      query = query.where('dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(f));
    }
    if (t != null) {
      query = query.where('dueDate',
          isLessThanOrEqualTo: Timestamp.fromDate(t));
    }

    final snap = await query.get();
    return snap.docs
        .map((d) => FinancialTransactionModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchProjects() async {
    final snap = await _firestore.collection('projects').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  double _sum(List<FinancialTransactionModel> transactions,
      {required TransactionType type, required TransactionStatus status}) {
    return transactions
        .where((t) => t.type == type && t.status == status)
        .fold(0.0, (s, t) => s + t.amount);
  }

  // ─── Helpers de formatação ────────────────────────────────────────────────
  Map<String, dynamic> _header(String concept, double value,
      {bool negative = false}) =>
      {'concept': concept, 'value': value, 'isHeader': true, 'negative': negative};

  Map<String, dynamic> _line(String concept, double value) =>
      {'concept': concept, 'value': value, 'isHeader': false};

  Map<String, dynamic> _result(String concept, double value,
      {bool highlight = false}) =>
      {'concept': concept, 'value': value, 'isResult': true, 'highlight': highlight};

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return names[month];
  }
}