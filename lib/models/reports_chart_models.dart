class MonthlyChartData {
  final String label; // "Jan", "Fev"...
  final double income;
  final double expense;
  double get profit => income - expense;

  MonthlyChartData({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class CategoryChartData {
  final String label;
  final double value;

  CategoryChartData({required this.label, required this.value});
}

enum DreLineType { header, line, subtotal, result }

class DreLine {
  final String concept;
  final double value;
  final DreLineType type;
  final String? detail;
  final double? referenceValue;

  const DreLine({
    required this.concept,
    required this.value,
    this.type = DreLineType.line,
    this.detail,
    this.referenceValue,
  });

  bool get isHeader => type == DreLineType.header;
  bool get isResult => type == DreLineType.result;
  bool get isSubtotal => type == DreLineType.subtotal;
  bool get highlight => type == DreLineType.result;
  bool get negative => value < 0;

  double get referencePercent {
    final base = referenceValue;
    if (base == null || base.abs() < 0.01) return 0;
    return value / base * 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'concept': concept,
      'value': value,
      'detail': detail,
      'isHeader': isHeader,
      'isResult': isResult || isSubtotal,
      'highlight': highlight,
      'negative': negative,
      'percent': referencePercent,
    };
  }
}

class DreCompanyContext {
  final int projectCount;
  final int activeProjectCount;
  final int overBudgetProjectCount;
  final double projectBudgetTotal;
  final double projectCurrentCostTotal;
  final double projectMeasuredTotal;
  final int activeEmployeeCount;
  final double monthlyPayrollBase;
  final int inventoryItemCount;
  final int criticalInventoryItemCount;
  final int dailyLogCount;
  final int openPurchaseCount;
  final double openPurchaseValue;
  final double measurementsInPeriod;
  final double measurementsReceivable;

  const DreCompanyContext({
    required this.projectCount,
    required this.activeProjectCount,
    required this.overBudgetProjectCount,
    required this.projectBudgetTotal,
    required this.projectCurrentCostTotal,
    required this.projectMeasuredTotal,
    required this.activeEmployeeCount,
    required this.monthlyPayrollBase,
    required this.inventoryItemCount,
    required this.criticalInventoryItemCount,
    required this.dailyLogCount,
    required this.openPurchaseCount,
    required this.openPurchaseValue,
    required this.measurementsInPeriod,
    required this.measurementsReceivable,
  });

  double get projectCostBurnPercent {
    if (projectBudgetTotal <= 0) return 0;
    return projectCurrentCostTotal / projectBudgetTotal * 100;
  }

  double get measuredBudgetPercent {
    if (projectBudgetTotal <= 0) return 0;
    return projectMeasuredTotal / projectBudgetTotal * 100;
  }

  static const empty = DreCompanyContext(
    projectCount: 0,
    activeProjectCount: 0,
    overBudgetProjectCount: 0,
    projectBudgetTotal: 0,
    projectCurrentCostTotal: 0,
    projectMeasuredTotal: 0,
    activeEmployeeCount: 0,
    monthlyPayrollBase: 0,
    inventoryItemCount: 0,
    criticalInventoryItemCount: 0,
    dailyLogCount: 0,
    openPurchaseCount: 0,
    openPurchaseValue: 0,
    measurementsInPeriod: 0,
    measurementsReceivable: 0,
  );
}

class DreExecutiveReport {
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final double grossRevenue;
  final double taxDeductions;
  final double netRevenue;
  final double materialCosts;
  final double projectMaterialCosts;
  final double operationalMaterialCosts;
  final double laborCosts;
  final double operationalLaborCosts;
  final double equipmentCosts;
  final double operationalEquipmentCosts;
  final double otherProjectCosts;
  final double directCosts;
  final double grossProfit;
  final double administrativeExpenses;
  final double otherOperationalExpenses;
  final double operationalExpenses;
  final double operatingResult;
  final double pendingIncome;
  final double pendingExpense;
  final double overdueExpense;
  final double paidExpenseTotal;
  final Map<String, double> expensesByCategory;
  final Map<String, double> expensesByOrigin;
  final List<DreLine> lines;
  final List<String> executiveInsights;
  final List<String> managementActions;
  final DreCompanyContext companyContext;

  const DreExecutiveReport({
    this.periodFrom,
    this.periodTo,
    required this.grossRevenue,
    required this.taxDeductions,
    required this.netRevenue,
    required this.materialCosts,
    required this.projectMaterialCosts,
    required this.operationalMaterialCosts,
    required this.laborCosts,
    required this.operationalLaborCosts,
    required this.equipmentCosts,
    required this.operationalEquipmentCosts,
    required this.otherProjectCosts,
    required this.directCosts,
    required this.grossProfit,
    required this.administrativeExpenses,
    required this.otherOperationalExpenses,
    required this.operationalExpenses,
    required this.operatingResult,
    required this.pendingIncome,
    required this.pendingExpense,
    required this.overdueExpense,
    required this.paidExpenseTotal,
    required this.expensesByCategory,
    required this.expensesByOrigin,
    required this.lines,
    required this.executiveInsights,
    required this.managementActions,
    required this.companyContext,
  });

  double get grossMargin => _ratio(grossProfit, netRevenue);
  double get operatingMargin => _ratio(operatingResult, netRevenue);
  double get directCostRatio => _ratio(directCosts, netRevenue);
  double get materialRatio => _ratio(materialCosts, netRevenue);
  double get operationalExpenseRatio => _ratio(operationalExpenses, netRevenue);
  double get taxRatio => _ratio(taxDeductions, grossRevenue);
  double get cashCoverage =>
      pendingExpense <= 0 ? 999 : pendingIncome / pendingExpense;

  bool get hasData =>
      grossRevenue > 0 ||
      paidExpenseTotal > 0 ||
      pendingIncome > 0 ||
      pendingExpense > 0 ||
      companyContext.projectCount > 0;

  String get periodLabel {
    if (periodFrom == null && periodTo == null) return 'Historico completo';
    final from = periodFrom;
    final to = periodTo;
    if (from == null) return 'Ate ${_formatDate(to!)}';
    if (to == null) return 'A partir de ${_formatDate(from)}';
    return '${_formatDate(from)} a ${_formatDate(to)}';
  }

  static const empty = DreExecutiveReport(
    grossRevenue: 0,
    taxDeductions: 0,
    netRevenue: 0,
    materialCosts: 0,
    projectMaterialCosts: 0,
    operationalMaterialCosts: 0,
    laborCosts: 0,
    operationalLaborCosts: 0,
    equipmentCosts: 0,
    operationalEquipmentCosts: 0,
    otherProjectCosts: 0,
    directCosts: 0,
    grossProfit: 0,
    administrativeExpenses: 0,
    otherOperationalExpenses: 0,
    operationalExpenses: 0,
    operatingResult: 0,
    pendingIncome: 0,
    pendingExpense: 0,
    overdueExpense: 0,
    paidExpenseTotal: 0,
    expensesByCategory: <String, double>{},
    expensesByOrigin: <String, double>{},
    lines: <DreLine>[],
    executiveInsights: <String>[],
    managementActions: <String>[],
    companyContext: DreCompanyContext.empty,
  );

  static double _ratio(double value, double base) {
    if (base.abs() < 0.01) return 0;
    return value / base;
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
