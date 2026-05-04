import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/widgets/budgets/budget_form_dialog.dart';

import '../helpers/fake_budget_type_service.dart';
import '../helpers/fake_client_account_service.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('BudgetFormDialog', () {
    testWidgets('valida cliente e projeto obrigatorios', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildHarness(
          BudgetFormDialog(
            onSave: (_) {},
            budgetTypeService: FakeBudgetTypeService(),
            clientAccountService: FakeClientAccountService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(ElevatedButton).last);
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.textContaining('obrigat'), findsNWidgets(2));
    });

    testWidgets('salva orçamento em edicao com tipo reconstruido', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final budgetType = BudgetType(
        id: 'type-1',
        name: 'Estrutural',
        description: 'Escopo estrutural',
        category: 'obras',
        isActive: true,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
        iconName: 'construction',
        color: '#0055FF',
      );
      final budget = Budget(
        id: 'budget-1',
        clientName: 'Cliente Norte',
        projectName: 'Torre Azul',
        totalValue: 50000,
        creationDate: DateTime(2026, 5, 1),
        expirationDate: DateTime.now().add(const Duration(days: 30)),
        status: BudgetStatus.pending,
        items: [
          BudgetItem(
            description: 'Estrutural - Escopo estrutural',
            quantity: 1,
            unitPrice: 50000,
          ),
        ],
        clientAccountId: 'client-9',
      );
      Budget? savedBudget;

      await tester.pumpWidget(
        _buildHarness(
          BudgetFormDialog(
            budget: budget,
            onSave: (value) => savedBudget = value,
            budgetTypeService: FakeBudgetTypeService(activeTypes: [budgetType]),
            clientAccountService: FakeClientAccountService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(ElevatedButton).last);
      await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(savedBudget, isNotNull);
      expect(savedBudget?.projectName, 'Torre Azul');
      expect(savedBudget?.items, hasLength(1));
      expect(savedBudget?.items.single.description, contains('Estrutural'));
    });
  });
}
