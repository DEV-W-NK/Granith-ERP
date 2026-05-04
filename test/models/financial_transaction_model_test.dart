import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

void main() {
  group('FinancialTransactionModel', () {
    test('fromMap converte enums e datas corretamente', () {
      final now = DateTime(2026, 5, 3, 12);
      final transaction = FinancialTransactionModel.fromMap({
        'description': 'Compra de insumos',
        'amount': 2500.75,
        'type': 'expense',
        'status': 'paid',
        'origin': 'purchase',
        'category': 'material',
        'dueDate': now.toIso8601String(),
        'paymentDate': now.toIso8601String(),
        'projectId': 'project-1',
        'supplierId': 'supplier-1',
        'referenceId': 'purchase-1',
        'createdBy': 'user-1',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'notes': 'NF 123',
      }, 'tx-1');

      expect(transaction.id, 'tx-1');
      expect(transaction.type, TransactionType.expense);
      expect(transaction.status, TransactionStatus.paid);
      expect(transaction.origin, TransactionOrigin.purchase);
      expect(transaction.category, TransactionCategory.material);
      expect(transaction.projectId, 'project-1');
      expect(transaction.amount, 2500.75);
      expect(transaction.paymentDate, now);
    });

    test('markAsPaid atualiza status e data de pagamento', () {
      final pending = FinancialTransactionModel(
        id: 'tx-1',
        description: 'Despesa futura',
        amount: 500,
        type: TransactionType.expense,
        status: TransactionStatus.pending,
        origin: TransactionOrigin.manual,
        category: TransactionCategory.other,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'user-1',
        createdAt: DateTime.now(),
      );

      final paid = pending.markAsPaid();

      expect(paid.status, TransactionStatus.paid);
      expect(paid.paymentDate, isNotNull);
      expect(paid.updatedAt, isNotNull);
      expect(paid.isOverdue, isFalse);
    });
  });
}
