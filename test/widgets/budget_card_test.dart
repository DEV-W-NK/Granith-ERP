import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/widgets/budgets/budget_card.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('BudgetCard', () {
    testWidgets('renderiza dados principais e aprova/rejeita', (tester) async {
      var approved = false;
      var rejected = false;

      final budget = Budget(
        id: 'budget-1',
        clientName: 'Cliente Atlas',
        projectName: 'Torre Norte',
        totalValue: 125000,
        creationDate: DateTime(2026, 5, 1),
        expirationDate: DateTime.now().add(const Duration(days: 10)),
        status: BudgetStatus.pending,
        items: [
          BudgetItem(
            description: 'Estrutural - Escopo base',
            quantity: 1,
            unitPrice: 125000,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildHarness(
          BudgetCard(
            budget: budget,
            onApprove: () => approved = true,
            onReject: () => rejected = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cliente Atlas'), findsOneWidget);
      expect(find.text('Torre Norte'), findsOneWidget);
      expect(find.textContaining('125000'), findsOneWidget);

      await tester.tap(find.text('Aprovar'));
      await tester.pumpAndSettle();
      expect(approved, isTrue);

      await tester.tap(find.text('Rejeitar'));
      await tester.pumpAndSettle();
      expect(rejected, isTrue);
    });

    testWidgets('mostra status expirado quando a validade passou', (
      tester,
    ) async {
      final budget = Budget(
        id: 'budget-2',
        clientName: 'Cliente Vencido',
        projectName: 'Obra Antiga',
        totalValue: 1000,
        creationDate: DateTime(2026, 1, 1),
        expirationDate: DateTime.now().subtract(const Duration(days: 2)),
        status: BudgetStatus.pending,
      );

      await tester.pumpWidget(_buildHarness(BudgetCard(budget: budget)));
      await tester.pumpAndSettle();

      expect(find.text('Expirado'), findsNWidgets(2));
    });
  });
}
