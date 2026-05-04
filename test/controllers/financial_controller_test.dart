import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

import '../helpers/fake_financial_service.dart';

FinancialTransactionModel _tx({
  required String id,
  required TransactionType type,
  required TransactionStatus status,
  required TransactionCategory category,
  required TransactionOrigin origin,
  required DateTime dueDate,
  double amount = 100,
  String? projectId,
}) {
  return FinancialTransactionModel(
    id: id,
    description: 'Transacao $id',
    amount: amount,
    type: type,
    status: status,
    origin: origin,
    category: category,
    dueDate: dueDate,
    projectId: projectId,
    createdBy: 'tester',
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  group('FinancialController', () {
    test('init sincroniza overdue e consolida indicadores', () async {
      final service = FakeFinancialService();
      final controller = FinancialController(service: service);
      final now = DateTime.now();

      controller.init();
      service.emit([
        _tx(
          id: 'income-paid',
          type: TransactionType.income,
          status: TransactionStatus.paid,
          category: TransactionCategory.measurement,
          origin: TransactionOrigin.budget,
          dueDate: now.subtract(const Duration(days: 1)),
          amount: 800,
          projectId: 'p1',
        ),
        _tx(
          id: 'expense-paid',
          type: TransactionType.expense,
          status: TransactionStatus.paid,
          category: TransactionCategory.material,
          origin: TransactionOrigin.purchase,
          dueDate: now.subtract(const Duration(days: 2)),
          amount: 300,
          projectId: 'p1',
        ),
        _tx(
          id: 'expense-overdue',
          type: TransactionType.expense,
          status: TransactionStatus.pending,
          category: TransactionCategory.labor,
          origin: TransactionOrigin.manual,
          dueDate: now.subtract(const Duration(days: 3)),
          amount: 120,
          projectId: 'p1',
        ),
        _tx(
          id: 'income-pending',
          type: TransactionType.income,
          status: TransactionStatus.pending,
          category: TransactionCategory.measurement,
          origin: TransactionOrigin.budget,
          dueDate: now.add(const Duration(days: 4)),
          amount: 250,
          projectId: 'p2',
        ),
      ]);

      await Future<void>.delayed(Duration.zero);

      expect(controller.isLoading, isFalse);
      expect(controller.totalIncome, 800);
      expect(controller.totalExpense, 300);
      expect(controller.balance, 500);
      expect(controller.totalPendingIncome, 250);
      expect(controller.totalOverdueExpense, 120);
      expect(controller.expensesByCategory[TransactionCategory.material], 300);
      expect(controller.expensesByOrigin[TransactionOrigin.manual], 120);
      expect(service.lastUpdatedTransaction?.id, 'expense-overdue');
      expect(service.lastUpdatedTransaction?.status, TransactionStatus.overdue);

      controller.dispose();
      await service.dispose();
    });

    test(
      'aplica filtros de projeto e periodo sobre a lista corrente',
      () async {
        final service = FakeFinancialService();
        final controller = FinancialController(service: service);
        final now = DateTime.now();

        controller.init();
        service.emit([
          _tx(
            id: 'a',
            type: TransactionType.expense,
            status: TransactionStatus.paid,
            category: TransactionCategory.material,
            origin: TransactionOrigin.purchase,
            dueDate: now.subtract(const Duration(days: 1)),
            amount: 90,
            projectId: 'p1',
          ),
          _tx(
            id: 'b',
            type: TransactionType.expense,
            status: TransactionStatus.paid,
            category: TransactionCategory.equipment,
            origin: TransactionOrigin.manual,
            dueDate: now.subtract(const Duration(days: 10)),
            amount: 180,
            projectId: 'p2',
          ),
        ]);

        await Future<void>.delayed(Duration.zero);

        controller.setProjectFilter('p1');
        expect(controller.transactions.map((item) => item.id), ['a']);

        controller.setPeriodFilter(
          now.subtract(const Duration(days: 3)),
          now.add(const Duration(days: 1)),
        );
        expect(controller.transactions.map((item) => item.id), ['a']);

        controller.clearFilters();
        expect(controller.transactions, hasLength(2));

        controller.dispose();
        await service.dispose();
      },
    );

    test('delegates add update pay cancel and delete operations', () async {
      final service = FakeFinancialService();
      final controller = FinancialController(service: service);
      final tx = _tx(
        id: 'tx-1',
        type: TransactionType.expense,
        status: TransactionStatus.pending,
        category: TransactionCategory.administrative,
        origin: TransactionOrigin.manual,
        dueDate: DateTime.now(),
        amount: 55,
      );

      await controller.addTransaction(tx);
      await controller.updateTransaction(
        tx.copyWith(description: 'Atualizada'),
      );
      await controller.markAsPaid('tx-1');
      await controller.cancelTransaction('tx-1');
      await controller.deleteTransaction('tx-1');

      expect(service.lastAddedTransaction?.id, 'tx-1');
      expect(service.lastUpdatedTransaction?.description, 'Atualizada');
      expect(service.lastMarkedAsPaidId, 'tx-1');
      expect(service.lastCancelledId, 'tx-1');
      expect(service.lastDeletedId, 'tx-1');

      controller.dispose();
      await service.dispose();
    });
  });
}
