import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/services/service_orcamentos.dart';

class _InspectableServiceOrcamentos extends ServiceOrcamentos {
  final List<Budget> updatedBudgets = <Budget>[];

  @override
  Future<void> updateBudget(Budget budget) async {
    updatedBudgets.add(budget);
  }
}

void main() {
  group('ServiceOrcamentos', () {
    Budget budget({
      required String id,
      required BudgetStatus status,
      DateTime? expirationDate,
    }) {
      return Budget(
        id: id,
        clientName: 'Cliente X',
        projectName: 'Projeto X',
        totalValue: 1000,
        creationDate: DateTime(2026, 5, 1),
        expirationDate: expirationDate,
        status: status,
      );
    }

    test('identifica corretamente orcamento expirado pendente', () {
      final service = ServiceOrcamentos();

      expect(
        service.debugShouldMarkAsExpired(
          budget(
            id: '1',
            status: BudgetStatus.pending,
            expirationDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
        isTrue,
      );
      expect(
        service.debugShouldMarkAsExpired(
          budget(
            id: '2',
            status: BudgetStatus.approved,
            expirationDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
        isFalse,
      );
      expect(
        service.debugShouldMarkAsExpired(
          budget(id: '3', status: BudgetStatus.pending),
        ),
        isFalse,
      );
    });

    test('normaliza lista trocando budgets expirados e chamando update', () async {
      final service = _InspectableServiceOrcamentos();
      final budgets = [
        budget(
          id: '1',
          status: BudgetStatus.pending,
          expirationDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        budget(
          id: '2',
          status: BudgetStatus.pending,
          expirationDate: DateTime.now().add(const Duration(days: 3)),
        ),
      ];

      final normalized = await service.debugCheckAndUpdateExpiredBudgets(budgets);

      expect(normalized.first.status, BudgetStatus.expired);
      expect(normalized.last.status, BudgetStatus.pending);
      expect(service.updatedBudgets, hasLength(1));
      expect(service.updatedBudgets.single.id, '1');
    });
  });
}
