import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

import '../helpers/fake_reports_financial_service.dart';

void main() {
  group('ReportsController', () {
    test('setCurrentMonth, setCurrentYear e clearPeriod atualizam filtros', () {
      final controller = ReportsController(
        financialService: FakeReportsFinancialService(),
      );

      controller.setCurrentMonth();
      expect(controller.periodFrom, isNotNull);
      expect(controller.periodTo, isNotNull);
      expect(controller.periodFrom!.month, DateTime.now().month);

      controller.setCurrentYear();
      expect(controller.periodFrom!.month, 1);
      expect(controller.periodTo!.month, 12);

      controller.clearPeriod();
      expect(controller.periodFrom, isNull);
      expect(controller.periodTo, isNull);
    });

    test('fetchExpensesByCategory traduz labels e ordena por valor', () async {
      final service = FakeReportsFinancialService(
        categorySums: {'material': 9000, 'administrative': 2000, 'tax': 4000},
      );
      final controller = ReportsController(financialService: service);

      controller.setPeriod(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31, 23, 59, 59),
      );
      final result = await controller.fetchExpensesByCategory();

      expect(service.lastType, TransactionType.expense);
      expect(service.lastFrom, controller.periodFrom);
      expect(result.map((e) => e.label).toList(), [
        'Materiais',
        'Impostos',
        'Administrativo',
      ]);
      expect(result.first.value, 9000);
    });

    test('DRE gerencial separa custos diretos, OPEX e riscos de caixa', () {
      final report = ReportsController.buildDreExecutiveReportFromData(
        periodFrom: DateTime(2026, 1, 1),
        periodTo: DateTime(2026, 12, 31, 23, 59, 59),
        projects: [
          {
            'id': 'project-1',
            'status': 'inProgress',
            'budget': 180000,
            'currentCost': 90000,
            'measuredAmount': 60000,
          },
          {
            'id': 'project-2',
            'status': 'inProgress',
            'budget': 50000,
            'currentCost': 62000,
          },
        ],
        employees: [
          {'id': 'employee-1', 'status': 'ativo', 'baseSalary': 4500},
          {'id': 'employee-2', 'status': 'desligado', 'baseSalary': 3500},
        ],
        inventory: [
          {'id': 'inv-1', 'quantity': 3, 'minQuantity': 5},
          {'id': 'inv-2', 'quantity': 20, 'minQuantity': 5},
        ],
        purchases: [
          {'id': 'purchase-1', 'status': 1, 'totalValue': 12000},
          {'id': 'purchase-2', 'status': 3, 'totalValue': 8000},
        ],
        measurements: [
          {
            'id': 'm-1',
            'status': 'approved',
            'netAmount': 25000,
            'measurementDate': DateTime(2026, 5, 2).toIso8601String(),
          },
        ],
        dailyLogs: [
          {'id': 'log-1'},
        ],
        transactions: [
          _tx(
            id: 'income',
            amount: 100000,
            type: TransactionType.income,
            status: TransactionStatus.paid,
            category: TransactionCategory.measurement,
            projectId: 'project-1',
          ),
          _tx(
            id: 'tax',
            amount: 5000,
            status: TransactionStatus.paid,
            category: TransactionCategory.tax,
          ),
          _tx(
            id: 'material-project',
            amount: 35000,
            status: TransactionStatus.paid,
            category: TransactionCategory.material,
            origin: TransactionOrigin.purchase,
            projectId: 'project-1',
          ),
          _tx(
            id: 'labor-project',
            amount: 15000,
            status: TransactionStatus.paid,
            category: TransactionCategory.labor,
            projectId: 'project-1',
          ),
          _tx(
            id: 'admin',
            amount: 12000,
            status: TransactionStatus.paid,
            category: TransactionCategory.administrative,
          ),
          _tx(
            id: 'material-ops',
            amount: 3000,
            status: TransactionStatus.paid,
            category: TransactionCategory.material,
          ),
          _tx(
            id: 'pending-income',
            amount: 20000,
            type: TransactionType.income,
            status: TransactionStatus.pending,
            category: TransactionCategory.measurement,
            projectId: 'project-1',
          ),
          _tx(
            id: 'overdue-expense',
            amount: 4000,
            status: TransactionStatus.overdue,
            category: TransactionCategory.other,
            dueDate: DateTime(2026, 1, 10),
          ),
          _tx(
            id: 'previous-year',
            amount: 999999,
            type: TransactionType.income,
            status: TransactionStatus.paid,
            category: TransactionCategory.measurement,
            dueDate: DateTime(2025, 12, 31),
          ),
        ],
      );

      expect(report.grossRevenue, 100000);
      expect(report.taxDeductions, 5000);
      expect(report.netRevenue, 95000);
      expect(report.projectMaterialCosts, 35000);
      expect(report.operationalMaterialCosts, 3000);
      expect(report.directCosts, 50000);
      expect(report.operationalExpenses, 15000);
      expect(report.operatingResult, 30000);
      expect(report.pendingIncome, 20000);
      expect(report.pendingExpense, 4000);
      expect(report.overdueExpense, 4000);
      expect(report.companyContext.activeProjectCount, 2);
      expect(report.companyContext.overBudgetProjectCount, 1);
      expect(report.companyContext.criticalInventoryItemCount, 1);
      expect(report.companyContext.openPurchaseValue, 12000);
      expect(report.executiveInsights, isNotEmpty);
      expect(report.managementActions, isNotEmpty);
    });
  });
}

FinancialTransactionModel _tx({
  required String id,
  required double amount,
  TransactionType type = TransactionType.expense,
  TransactionStatus status = TransactionStatus.pending,
  TransactionOrigin origin = TransactionOrigin.manual,
  TransactionCategory category = TransactionCategory.other,
  DateTime? dueDate,
  String? projectId,
}) {
  return FinancialTransactionModel(
    id: id,
    description: id,
    amount: amount,
    type: type,
    status: status,
    origin: origin,
    category: category,
    dueDate: dueDate ?? DateTime(2026, 5, 2),
    paymentDate: status == TransactionStatus.paid ? DateTime(2026, 5, 2) : null,
    projectId: projectId,
    createdBy: 'test',
    createdAt: DateTime(2026, 5, 1),
  );
}
