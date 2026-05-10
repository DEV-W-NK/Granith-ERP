import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/core/supabase/supabase_selects.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/reports_chart_models.dart';
import 'package:project_granith/services/financial_service.dart';

class ReportsController extends ChangeNotifier {
  final FinancialService _financialService;

  ReportsController({FinancialService? financialService})
    : _financialService = financialService ?? FinancialService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DreExecutiveReport? _dreReport;
  DreExecutiveReport? get dreReport => _dreReport;

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

  Future<void> loadDreReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dreReport = await fetchDreExecutiveReport();
    } catch (e) {
      debugPrint('[ReportsController] Erro ao carregar DRE: $e');
      _dreReport = DreExecutiveReport.empty;
      _error = 'Nao foi possivel carregar o DRE gerencial.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<DreExecutiveReport> fetchDreExecutiveReport() async {
    final transactionsFuture = _fetchTransactions();
    final projectsFuture = _fetchProjects();
    final employeesFuture = _fetchEmployees();
    final inventoryFuture = _fetchInventoryRows();
    final purchasesFuture = _fetchPurchases();
    final measurementsFuture = _fetchProjectMeasurements();
    final dailyLogsFuture = _fetchDailyLogRows();

    final results = await Future.wait<dynamic>([
      transactionsFuture,
      projectsFuture,
      employeesFuture,
      inventoryFuture,
      purchasesFuture,
      measurementsFuture,
      dailyLogsFuture,
    ]);

    return buildDreExecutiveReportFromData(
      transactions: results[0] as List<FinancialTransactionModel>,
      projects: results[1] as List<Map<String, dynamic>>,
      employees: results[2] as List<Map<String, dynamic>>,
      inventory: results[3] as List<Map<String, dynamic>>,
      purchases: results[4] as List<Map<String, dynamic>>,
      measurements: results[5] as List<Map<String, dynamic>>,
      dailyLogs: results[6] as List<Map<String, dynamic>>,
      periodFrom: periodFrom,
      periodTo: periodTo,
    );
  }

  static DreExecutiveReport buildDreExecutiveReportFromData({
    required List<FinancialTransactionModel> transactions,
    List<Map<String, dynamic>> projects = const [],
    List<Map<String, dynamic>> employees = const [],
    List<Map<String, dynamic>> inventory = const [],
    List<Map<String, dynamic>> purchases = const [],
    List<Map<String, dynamic>> measurements = const [],
    List<Map<String, dynamic>> dailyLogs = const [],
    DateTime? periodFrom,
    DateTime? periodTo,
  }) {
    final periodTransactions =
        transactions.where((transaction) {
          if (transaction.status == TransactionStatus.cancelled) return false;
          return _isDateInPeriod(transaction.dueDate, periodFrom, periodTo);
        }).toList();

    final paidTransactions =
        periodTransactions
            .where(
              (transaction) => transaction.status == TransactionStatus.paid,
            )
            .toList();
    final paidExpenses =
        paidTransactions
            .where((transaction) => transaction.type == TransactionType.expense)
            .toList();

    final grossRevenue = _sumTransactions(
      paidTransactions,
      (transaction) => transaction.type == TransactionType.income,
    );
    final taxDeductions = _sumTransactions(
      paidExpenses,
      (transaction) => transaction.category == TransactionCategory.tax,
    );
    final netRevenue = grossRevenue - taxDeductions;

    bool isDirectProjectCost(FinancialTransactionModel transaction) {
      if (!_hasProject(transaction)) return false;
      return switch (transaction.category) {
        TransactionCategory.material ||
        TransactionCategory.labor ||
        TransactionCategory.equipment ||
        TransactionCategory.measurement ||
        TransactionCategory.other => true,
        TransactionCategory.administrative || TransactionCategory.tax => false,
      };
    }

    final projectMaterialCosts = _sumTransactions(
      paidExpenses,
      (transaction) =>
          isDirectProjectCost(transaction) &&
          transaction.category == TransactionCategory.material,
    );
    final laborCosts = _sumTransactions(
      paidExpenses,
      (transaction) =>
          isDirectProjectCost(transaction) &&
          transaction.category == TransactionCategory.labor,
    );
    final equipmentCosts = _sumTransactions(
      paidExpenses,
      (transaction) =>
          isDirectProjectCost(transaction) &&
          transaction.category == TransactionCategory.equipment,
    );
    final directCosts = _sumTransactions(paidExpenses, isDirectProjectCost);
    final otherProjectCosts =
        directCosts - projectMaterialCosts - laborCosts - equipmentCosts;

    bool isOperationalExpense(FinancialTransactionModel transaction) {
      return transaction.category != TransactionCategory.tax &&
          !isDirectProjectCost(transaction);
    }

    final operationalExpenses = _sumTransactions(
      paidExpenses,
      isOperationalExpense,
    );
    final operationalMaterialCosts = _sumTransactions(
      paidExpenses,
      (transaction) =>
          isOperationalExpense(transaction) &&
          transaction.category == TransactionCategory.material,
    );
    final operationalLaborCosts = _sumTransactions(
      paidExpenses,
      (transaction) =>
          isOperationalExpense(transaction) &&
          transaction.category == TransactionCategory.labor,
    );
    final operationalEquipmentCosts = _sumTransactions(
      paidExpenses,
      (transaction) =>
          isOperationalExpense(transaction) &&
          transaction.category == TransactionCategory.equipment,
    );
    final administrativeExpenses = _sumTransactions(
      paidExpenses,
      (transaction) =>
          isOperationalExpense(transaction) &&
          transaction.category == TransactionCategory.administrative,
    );
    final otherOperationalExpenses =
        operationalExpenses -
        operationalMaterialCosts -
        operationalLaborCosts -
        operationalEquipmentCosts -
        administrativeExpenses;

    final grossProfit = netRevenue - directCosts;
    final operatingResult = grossProfit - operationalExpenses;
    final paidExpenseTotal = _sumTransactions(paidExpenses, (_) => true);

    final pendingIncome = _sumTransactions(
      periodTransactions,
      (transaction) =>
          transaction.type == TransactionType.income &&
          transaction.status != TransactionStatus.paid,
    );
    final pendingExpense = _sumTransactions(
      periodTransactions,
      (transaction) =>
          transaction.type == TransactionType.expense &&
          transaction.status != TransactionStatus.paid,
    );
    final now = DateTime.now();
    final overdueExpense = _sumTransactions(
      periodTransactions,
      (transaction) =>
          transaction.type == TransactionType.expense &&
          (transaction.status == TransactionStatus.overdue ||
              (transaction.status == TransactionStatus.pending &&
                  transaction.dueDate.isBefore(now))),
    );

    final expensesByCategory = <String, double>{};
    final expensesByOrigin = <String, double>{};
    for (final transaction in paidExpenses) {
      expensesByCategory[transaction.category.name] =
          (expensesByCategory[transaction.category.name] ?? 0) +
          transaction.amount;
      expensesByOrigin[transaction.origin.name] =
          (expensesByOrigin[transaction.origin.name] ?? 0) + transaction.amount;
    }

    final materialCosts = projectMaterialCosts + operationalMaterialCosts;
    final context = _buildCompanyContext(
      projects: projects,
      employees: employees,
      inventory: inventory,
      purchases: purchases,
      measurements: measurements,
      dailyLogs: dailyLogs,
      periodFrom: periodFrom,
      periodTo: periodTo,
    );

    final lines = <DreLine>[
      DreLine(
        concept: 'Receita bruta',
        value: grossRevenue,
        type: DreLineType.header,
        detail: 'Entradas financeiras pagas no periodo',
        referenceValue: grossRevenue,
      ),
      DreLine(
        concept: '(-) Impostos e taxas',
        value: -taxDeductions,
        detail: 'Deducoes classificadas como impostos/taxas',
        referenceValue: grossRevenue,
      ),
      DreLine(
        concept: '(=) Receita liquida',
        value: netRevenue,
        type: DreLineType.subtotal,
        referenceValue: grossRevenue,
      ),
      DreLine(
        concept: 'Custos diretos de obra',
        value: -directCosts,
        type: DreLineType.header,
        detail: 'Custos pagos vinculados a projetos',
        referenceValue: netRevenue,
      ),
      DreLine(
        concept: 'Materiais aplicados em obras',
        value: -projectMaterialCosts,
        detail: 'Compras/consumo com projeto vinculado',
        referenceValue: netRevenue,
      ),
      DreLine(
        concept: 'Mao de obra direta',
        value: -laborCosts,
        referenceValue: netRevenue,
      ),
      DreLine(
        concept: 'Equipamentos de obra',
        value: -equipmentCosts,
        referenceValue: netRevenue,
      ),
      if (otherProjectCosts > 0.01)
        DreLine(
          concept: 'Outros custos de obra',
          value: -otherProjectCosts,
          referenceValue: netRevenue,
        ),
      DreLine(
        concept: '(=) Lucro bruto',
        value: grossProfit,
        type: DreLineType.subtotal,
        referenceValue: netRevenue,
      ),
      DreLine(
        concept: 'Despesas operacionais',
        value: -operationalExpenses,
        type: DreLineType.header,
        detail: 'Gastos da empresa fora do custo direto da obra',
        referenceValue: netRevenue,
      ),
      DreLine(
        concept: 'Administrativo e estrutura',
        value: -administrativeExpenses,
        referenceValue: netRevenue,
      ),
      if (operationalMaterialCosts > 0.01)
        DreLine(
          concept: 'Materiais operacionais sem obra',
          value: -operationalMaterialCosts,
          referenceValue: netRevenue,
        ),
      if (operationalLaborCosts > 0.01)
        DreLine(
          concept: 'Mao de obra operacional sem obra',
          value: -operationalLaborCosts,
          referenceValue: netRevenue,
        ),
      if (operationalEquipmentCosts > 0.01)
        DreLine(
          concept: 'Equipamentos operacionais sem obra',
          value: -operationalEquipmentCosts,
          referenceValue: netRevenue,
        ),
      if (otherOperationalExpenses > 0.01)
        DreLine(
          concept: 'Outras despesas operacionais',
          value: -otherOperationalExpenses,
          referenceValue: netRevenue,
        ),
      DreLine(
        concept: '(=) Resultado operacional',
        value: operatingResult,
        type: DreLineType.result,
        detail: 'Resultado antes de itens financeiros e nao recorrentes',
        referenceValue: netRevenue,
      ),
    ];

    final report = DreExecutiveReport(
      periodFrom: periodFrom,
      periodTo: periodTo,
      grossRevenue: grossRevenue,
      taxDeductions: taxDeductions,
      netRevenue: netRevenue,
      materialCosts: materialCosts,
      projectMaterialCosts: projectMaterialCosts,
      operationalMaterialCosts: operationalMaterialCosts,
      laborCosts: laborCosts,
      operationalLaborCosts: operationalLaborCosts,
      equipmentCosts: equipmentCosts,
      operationalEquipmentCosts: operationalEquipmentCosts,
      otherProjectCosts: otherProjectCosts,
      directCosts: directCosts,
      grossProfit: grossProfit,
      administrativeExpenses: administrativeExpenses,
      otherOperationalExpenses: otherOperationalExpenses,
      operationalExpenses: operationalExpenses,
      operatingResult: operatingResult,
      pendingIncome: pendingIncome,
      pendingExpense: pendingExpense,
      overdueExpense: overdueExpense,
      paidExpenseTotal: paidExpenseTotal,
      expensesByCategory: expensesByCategory,
      expensesByOrigin: expensesByOrigin,
      lines: lines,
      executiveInsights: const [],
      managementActions: const [],
      companyContext: context,
    );

    return DreExecutiveReport(
      periodFrom: report.periodFrom,
      periodTo: report.periodTo,
      grossRevenue: report.grossRevenue,
      taxDeductions: report.taxDeductions,
      netRevenue: report.netRevenue,
      materialCosts: report.materialCosts,
      projectMaterialCosts: report.projectMaterialCosts,
      operationalMaterialCosts: report.operationalMaterialCosts,
      laborCosts: report.laborCosts,
      operationalLaborCosts: report.operationalLaborCosts,
      equipmentCosts: report.equipmentCosts,
      operationalEquipmentCosts: report.operationalEquipmentCosts,
      otherProjectCosts: report.otherProjectCosts,
      directCosts: report.directCosts,
      grossProfit: report.grossProfit,
      administrativeExpenses: report.administrativeExpenses,
      otherOperationalExpenses: report.otherOperationalExpenses,
      operationalExpenses: report.operationalExpenses,
      operatingResult: report.operatingResult,
      pendingIncome: report.pendingIncome,
      pendingExpense: report.pendingExpense,
      overdueExpense: report.overdueExpense,
      paidExpenseTotal: report.paidExpenseTotal,
      expensesByCategory: report.expensesByCategory,
      expensesByOrigin: report.expensesByOrigin,
      lines: report.lines,
      executiveInsights: _buildExecutiveInsights(report),
      managementActions: _buildManagementActions(report),
      companyContext: report.companyContext,
    );
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
    final report = await fetchDreExecutiveReport();
    return report.lines.map((line) => line.toMap()).toList();
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
      final budget = _toDouble(project['budget']);
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
    final rows = await _fetchInventoryRows();

    return rows.map((data) {
      final quantity = _toDouble(data['quantity']);
      final minQuantity = _toDouble(data['minQuantity']);
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
    final response = await _fetchDailyLogRows();
    final projectMap = <String, ({int logs, int workers})>{};

    for (final data in response) {
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
  }) {
    return _financialService.getTransactions(
      from: from ?? periodFrom,
      to: to ?? periodTo,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProjects() async {
    final response = await AppSupabase.client
        .from('projects')
        .select(
          'id,name,client,status,budget,currentCost,estimatedProgress,'
          'estimated_progress,measuredAmount,measured_amount,'
          'measurementCount,measurement_count,lastMeasurementAt,'
          'last_measurement_at,endDate',
        );
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchEmployees() async {
    final response = await AppSupabase.client
        .from('employees')
        .select('id,status,baseSalary');
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchInventoryRows() async {
    final response = await AppSupabase.client
        .from('inventory')
        .select(SupabaseSelects.inventoryReport)
        .order('name');
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPurchases() async {
    dynamic query = AppSupabase.client
        .from('purchases')
        .select('id,status,totalValue,purchaseDate,expectedDeliveryDate');

    if (periodFrom != null) {
      query = query.gte('purchaseDate', DbValue.toPrimitive(periodFrom!));
    }
    if (periodTo != null) {
      query = query.lte('purchaseDate', DbValue.toPrimitive(periodTo!));
    }

    final response = await query;
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchProjectMeasurements() async {
    dynamic query = AppSupabase.client
        .from('project_measurements')
        .select(
          'id,status,netAmount,net_amount,measurementDate,measurement_date,'
          'projectId,project_id',
        );

    if (periodFrom != null) {
      query = query.gte('measurementDate', DbValue.toPrimitive(periodFrom!));
    }
    if (periodTo != null) {
      query = query.lte('measurementDate', DbValue.toPrimitive(periodTo!));
    }

    final response = await query;
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchDailyLogRows() async {
    dynamic query = AppSupabase.client
        .from('daily_logs')
        .select(SupabaseSelects.dailyLogReport);

    if (periodFrom != null) {
      query = query.gte('date', DbValue.toPrimitive(periodFrom!));
    }
    if (periodTo != null) {
      query = query.lte('date', DbValue.toPrimitive(periodTo!));
    }

    final response = await query.order('date', ascending: false).limit(100);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  static DreCompanyContext _buildCompanyContext({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> employees,
    required List<Map<String, dynamic>> inventory,
    required List<Map<String, dynamic>> purchases,
    required List<Map<String, dynamic>> measurements,
    required List<Map<String, dynamic>> dailyLogs,
    DateTime? periodFrom,
    DateTime? periodTo,
  }) {
    final activeProjects =
        projects.where((project) => project['status'] != 'completed').toList();
    final projectBudgetTotal = projects.fold<double>(
      0,
      (sum, project) => sum + _toDouble(project['budget']),
    );
    final projectCurrentCostTotal = projects.fold<double>(
      0,
      (sum, project) => sum + _toDouble(project['currentCost']),
    );
    final projectMeasuredTotal = projects.fold<double>(
      0,
      (sum, project) =>
          sum +
          _toDouble(project['measuredAmount'] ?? project['measured_amount']),
    );
    final overBudgetProjects =
        projects.where((project) {
          final budget = _toDouble(project['budget']);
          return budget > 0 && _toDouble(project['currentCost']) > budget;
        }).length;

    final activeEmployees =
        employees.where((employee) => employee['status'] == 'ativo').toList();
    final monthlyPayrollBase = activeEmployees.fold<double>(
      0,
      (sum, employee) => sum + _toDouble(employee['baseSalary']),
    );

    final criticalInventoryItems =
        inventory.where((item) {
          final minQuantity = _toDouble(item['minQuantity']);
          if (minQuantity <= 0) return false;
          return _toDouble(item['quantity']) <= minQuantity;
        }).length;

    final openPurchases =
        purchases.where((purchase) {
          final rawStatus = purchase['status'];
          final status =
              rawStatus is int ? rawStatus : int.tryParse('$rawStatus') ?? 0;
          return status >= 0 && status < 3;
        }).toList();
    final openPurchaseValue = openPurchases.fold<double>(
      0,
      (sum, purchase) => sum + _toDouble(purchase['totalValue']),
    );

    final periodMeasurements =
        measurements.where((measurement) {
          final date = DbValue.toDateTime(
            measurement['measurementDate'] ?? measurement['measurement_date'],
          );
          if (date == null) return true;
          return _isDateInPeriod(date, periodFrom, periodTo);
        }).toList();
    final measurementsInPeriod = periodMeasurements.fold<double>(
      0,
      (sum, measurement) =>
          sum +
          _toDouble(measurement['netAmount'] ?? measurement['net_amount']),
    );
    final measurementsReceivable = periodMeasurements
        .where((measurement) => measurement['status'] == 'approved')
        .fold<double>(
          0,
          (sum, measurement) =>
              sum +
              _toDouble(measurement['netAmount'] ?? measurement['net_amount']),
        );

    return DreCompanyContext(
      projectCount: projects.length,
      activeProjectCount: activeProjects.length,
      overBudgetProjectCount: overBudgetProjects,
      projectBudgetTotal: projectBudgetTotal,
      projectCurrentCostTotal: projectCurrentCostTotal,
      projectMeasuredTotal: projectMeasuredTotal,
      activeEmployeeCount: activeEmployees.length,
      monthlyPayrollBase: monthlyPayrollBase,
      inventoryItemCount: inventory.length,
      criticalInventoryItemCount: criticalInventoryItems,
      dailyLogCount: dailyLogs.length,
      openPurchaseCount: openPurchases.length,
      openPurchaseValue: openPurchaseValue,
      measurementsInPeriod: measurementsInPeriod,
      measurementsReceivable: measurementsReceivable,
    );
  }

  static List<String> _buildExecutiveInsights(DreExecutiveReport report) {
    final insights = <String>[];

    if (!report.hasData) {
      return [
        'Ainda nao ha dados suficientes para uma leitura financeira executiva.',
      ];
    }

    if (report.netRevenue <= 0 && report.paidExpenseTotal > 0) {
      insights.add(
        'O periodo tem despesas registradas sem receita paga equivalente; a prioridade e faturamento/cobranca.',
      );
    } else if (report.operatingResult >= 0) {
      insights.add(
        'A empresa esta gerando resultado operacional positivo com margem de ${_formatPercent(report.operatingMargin)}.',
      );
    } else {
      insights.add(
        'A operacao ficou negativa no periodo; cada R\$ 1,00 de receita liquida nao cobriu custos e estrutura.',
      );
    }

    if (report.directCostRatio > 0.70) {
      insights.add(
        'Custos diretos consomem ${_formatPercent(report.directCostRatio)} da receita liquida; ha pouco espaco para estrutura e lucro.',
      );
    }

    if (report.materialRatio > 0.45) {
      insights.add(
        'Materiais representam ${_formatPercent(report.materialRatio)} da receita liquida; compras e perdas em obra devem ser revisadas.',
      );
    }

    if (report.operationalExpenseRatio > 0.25) {
      insights.add(
        'Despesas operacionais estao em ${_formatPercent(report.operationalExpenseRatio)} da receita liquida; a estrutura pesa no resultado.',
      );
    }

    if (report.pendingExpense > report.pendingIncome &&
        report.pendingExpense > 0) {
      insights.add(
        'Contas a pagar em aberto superam contas a receber; o caixa futuro precisa de cobranca ativa ou renegociacao.',
      );
    }

    if (report.overdueExpense > 0) {
      insights.add(
        'Existem despesas vencidas no periodo, elevando risco de fornecedores, juros e ruptura operacional.',
      );
    }

    if (report.companyContext.overBudgetProjectCount > 0) {
      insights.add(
        '${report.companyContext.overBudgetProjectCount} obra(s) aparecem acima do orcamento cadastrado.',
      );
    }

    return insights;
  }

  static List<String> _buildManagementActions(DreExecutiveReport report) {
    final actions = <String>[];

    if (report.materialRatio > 0.35) {
      actions.add(
        'Negociar curva ABC de materiais e comparar compra prevista, compra real e consumo por obra.',
      );
    }

    if (report.operationalExpenseRatio > 0.20) {
      actions.add(
        'Separar despesas fixas, cortar recorrencias sem dono e definir teto mensal de OPEX.',
      );
    }

    if (report.pendingIncome > 0 ||
        report.companyContext.measurementsReceivable > 0) {
      actions.add(
        'Priorizar cobranca de medicoes aprovadas e contas a receber antes de novas compras nao essenciais.',
      );
    }

    if (report.companyContext.overBudgetProjectCount > 0) {
      actions.add(
        'Revisar obras acima do orcamento com foco em aditivos, retrabalho e compras emergenciais.',
      );
    }

    if (report.operationalMaterialCosts > 0) {
      actions.add(
        'Classificar materiais sem projeto como estoque, consumo interno ou custo de obra para evitar distorcao no DRE.',
      );
    }

    if (actions.isEmpty) {
      actions.add(
        'Manter disciplina de lancamento por projeto, origem e categoria para preservar a leitura gerencial.',
      );
    }

    return actions;
  }

  static double _sumTransactions(
    Iterable<FinancialTransactionModel> transactions,
    bool Function(FinancialTransactionModel transaction) test,
  ) {
    return transactions
        .where(test)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  static bool _hasProject(FinancialTransactionModel transaction) {
    return transaction.projectId != null && transaction.projectId!.isNotEmpty;
  }

  static bool _isDateInPeriod(DateTime date, DateTime? from, DateTime? to) {
    if (from != null && date.isBefore(from)) return false;
    if (to != null && date.isAfter(to)) return false;
    return true;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  static String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
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
