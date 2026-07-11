import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/administrative_profit_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

void main() {
  group('AdministrativeProfitController', () {
    test('buildSummary calcula empresa e filtra obra selecionada', () {
      final from = DateTime(2026, 1);
      final to = DateTime(2026, 12, 31);
      final projects = const [
        AdministrativeProfitProjectOption(
          id: 'project-a',
          name: 'Obra A',
          client: 'Cliente A',
        ),
        AdministrativeProfitProjectOption(
          id: 'project-b',
          name: 'Obra B',
          client: 'Cliente B',
        ),
      ];
      final transactions = [
        _transaction(
          id: 'income-a',
          amount: 10000,
          type: TransactionType.income,
          status: TransactionStatus.paid,
          projectId: 'project-a',
        ),
        _transaction(
          id: 'expense-a',
          amount: 3500,
          type: TransactionType.expense,
          status: TransactionStatus.paid,
          projectId: 'project-a',
          category: TransactionCategory.material,
        ),
        _transaction(
          id: 'income-b',
          amount: 6000,
          type: TransactionType.income,
          status: TransactionStatus.paid,
          projectId: 'project-b',
        ),
        _transaction(
          id: 'expense-company',
          amount: 1500,
          type: TransactionType.expense,
          status: TransactionStatus.paid,
          category: TransactionCategory.administrative,
        ),
        _transaction(
          id: 'pending-a',
          amount: 800,
          type: TransactionType.expense,
          status: TransactionStatus.pending,
          projectId: 'project-a',
        ),
        _transaction(
          id: 'cancelled-a',
          amount: 999,
          type: TransactionType.expense,
          status: TransactionStatus.cancelled,
          projectId: 'project-a',
        ),
      ];

      final company = AdministrativeProfitController.buildSummary(
        transactions: transactions,
        projects: projects,
        scope: AdministrativeProfitScope.company,
        selectedProjectId: null,
        from: from,
        to: to,
      );
      final project = AdministrativeProfitController.buildSummary(
        transactions: transactions,
        projects: projects,
        scope: AdministrativeProfitScope.project,
        selectedProjectId: 'project-a',
        from: from,
        to: to,
      );

      expect(company.income, 16000);
      expect(company.expense, 5000);
      expect(company.profit, 11000);
      expect(project.selectedProject?.label, 'Obra A - Cliente A');
      expect(project.income, 10000);
      expect(project.expense, 3500);
      expect(project.pendingExpense, 800);
      expect(project.profit, 6500);
      expect(project.expensesByCategory[TransactionCategory.material], 3500);
      expect(
        project.expensesByCategory[TransactionCategory.administrative],
        isNull,
      );
    });
  });
}

FinancialTransactionModel _transaction({
  required String id,
  required double amount,
  required TransactionType type,
  required TransactionStatus status,
  String? projectId,
  TransactionCategory category = TransactionCategory.other,
}) {
  return FinancialTransactionModel(
    id: id,
    description: id,
    amount: amount,
    type: type,
    status: status,
    origin: TransactionOrigin.manual,
    category: category,
    dueDate: DateTime(2026, 3, 12),
    projectId: projectId,
    createdBy: 'test',
    createdAt: DateTime(2026, 3, 1),
  );
}
