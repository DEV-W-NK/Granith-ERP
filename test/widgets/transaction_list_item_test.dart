import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/widgets/financial/TransactionListItem.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_financial_service.dart';

FinancialTransactionModel _tx({
  required String id,
  required TransactionType type,
  required TransactionStatus status,
  required DateTime dueDate,
  double amount = 120,
  String? projectId,
}) {
  return FinancialTransactionModel(
    id: id,
    description: 'Transacao $id',
    amount: amount,
    type: type,
    status: status,
    origin: TransactionOrigin.manual,
    category: TransactionCategory.material,
    dueDate: dueDate,
    projectId: projectId,
    createdBy: 'tester',
    createdAt: DateTime(2026, 5, 1),
  );
}

Widget _buildHarness({
  required FinancialController controller,
  required Widget child,
}) {
  return ChangeNotifierProvider<FinancialController>.value(
    value: controller,
    child: MaterialApp(
      home: Scaffold(body: SizedBox(width: 960, child: child)),
    ),
  );
}

void main() {
  group('TransactionListItem', () {
    testWidgets('swipe para a direita marca transacao como paga', (
      tester,
    ) async {
      final service = FakeFinancialService();
      final controller = FinancialController(service: service);
      final item = _tx(
        id: 'tx-1',
        type: TransactionType.expense,
        status: TransactionStatus.pending,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        _buildHarness(
          controller: controller,
          child: TransactionListItem(transaction: item),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
      await tester.drag(find.byType(Dismissible), const Offset(400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(service.lastMarkedAsPaidId, 'tx-1');
      expect(find.text('Marcado como pago'), findsOneWidget);

      controller.dispose();
      await service.dispose();
    });

    testWidgets('swipe para a esquerda pede confirmacao e cancela transacao', (
      tester,
    ) async {
      final service = FakeFinancialService();
      final controller = FinancialController(service: service);
      final item = _tx(
        id: 'tx-2',
        type: TransactionType.expense,
        status: TransactionStatus.pending,
        dueDate: DateTime.now().add(const Duration(days: 2)),
        projectId: 'project-1',
      );

      await tester.pumpWidget(
        _buildHarness(
          controller: controller,
          child: TransactionListItem(transaction: item),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Cancelar transa'), findsWidgets);

      await tester.tap(find.textContaining('Cancelar transa').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(service.lastCancelledId, 'tx-2');

      controller.dispose();
      await service.dispose();
    });

    testWidgets('transacao paga renderiza card sem dismiss', (tester) async {
      final service = FakeFinancialService();
      final controller = FinancialController(service: service);
      final item = _tx(
        id: 'tx-3',
        type: TransactionType.income,
        status: TransactionStatus.paid,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        amount: 900,
      );

      await tester.pumpWidget(
        _buildHarness(
          controller: controller,
          child: TransactionListItem(transaction: item),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
      expect(find.textContaining('PAGO'), findsOneWidget);
      expect(find.textContaining('900'), findsOneWidget);

      controller.dispose();
      await service.dispose();
    });
  });
}
