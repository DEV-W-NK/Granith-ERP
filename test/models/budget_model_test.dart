import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/budget_model.dart';

void main() {
  group('Budget', () {
    test('fromMap aceita datas ISO e chaves snake_case do cliente', () {
      final budget = Budget.fromMap({
        'id': 'budget-1',
        'clientName': 'Cliente Horizonte',
        'projectName': 'Obra Leste',
        'totalValue': 150000.0,
        'created_at': '2026-05-01T10:00:00Z',
        'expirationDate': '2026-05-31T23:59:59Z',
        'status': BudgetStatus.pending.index,
        'description': 'Escopo estrutural',
        'items': [
          {
            'description': 'Concreto usinado',
            'quantity': 2,
            'unitPrice': 1500.0,
          },
        ],
        'client_account_id': 'client-22',
        'client_account_name': 'Conta Horizonte',
      });

      expect(budget.id, 'budget-1');
      expect(
        budget.creationDate.toUtc(),
        DateTime.parse('2026-05-01T10:00:00Z'),
      );
      expect(
        budget.expirationDate?.toUtc(),
        DateTime.parse('2026-05-31T23:59:59Z'),
      );
      expect(budget.clientAccountId, 'client-22');
      expect(budget.clientAccountName, 'Conta Horizonte');
      expect(budget.items, hasLength(1));
      expect(budget.items.single.total, 3000.0);
    });

    test('toMap inclui chaves camelCase e snake_case do cliente', () {
      final budget = Budget(
        id: 'budget-2',
        clientName: 'Cliente Atlas',
        projectName: 'Torre Norte',
        totalValue: 80000,
        creationDate: DateTime.utc(2026, 5, 3),
        status: BudgetStatus.approved,
        description: 'Proposta executiva',
        items: [
          BudgetItem(description: 'Aco CA-50', quantity: 4, unitPrice: 400),
        ],
        clientAccountId: 'client-9',
        clientAccountName: 'Conta Atlas',
      );

      final map = budget.toMap();

      expect(map['clientAccountId'], 'client-9');
      expect(map['client_account_id'], 'client-9');
      expect(map['clientAccountName'], 'Conta Atlas');
      expect(map['client_account_name'], 'Conta Atlas');
      expect((map['items'] as List).single['total'], 1600);
    });

    test('copyWith sobrescreve campos selecionados e preserva restante', () {
      final original = Budget(
        id: 'budget-3',
        clientName: 'Cliente Base',
        projectName: 'Obra Base',
        totalValue: 12000,
        creationDate: DateTime(2026, 1, 1),
        clientAccountId: 'client-1',
      );

      final copy = original.copyWith(
        status: BudgetStatus.rejected,
        clientAccountName: 'Conta Base',
      );

      expect(copy.id, original.id);
      expect(copy.clientName, original.clientName);
      expect(copy.status, BudgetStatus.rejected);
      expect(copy.clientAccountId, 'client-1');
      expect(copy.clientAccountName, 'Conta Base');
    });
  });
}
