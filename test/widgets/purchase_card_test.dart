import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/purchases/purchase_card.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_purchase_service.dart';

class _TestAuthController extends AuthController {
  _TestAuthController(this._user) : super(bootstrapOnInit: false);

  final UserModel _user;

  @override
  UserModel? get user => _user;
}

Widget _buildHarness({
  required Widget child,
  required AuthController authController,
}) {
  return ChangeNotifierProvider<AuthController>.value(
    value: authController,
    child: MaterialApp(
      home: Scaffold(body: SizedBox(width: 960, height: 320, child: child)),
    ),
  );
}

Purchase _purchase(PurchaseStatus status) {
  return Purchase(
    id: 'purchase-1',
    itemId: 'item-1',
    itemName: 'Cimento CP-II',
    supplierId: 'sup-1',
    supplierName: 'Fornecedor Atlas',
    projectId: 'project-1',
    projectName: 'Residencial Azul',
    deliveryAddress: 'Rua A, 123',
    quantity: 12,
    totalValue: 4200,
    status: status,
    purchaseDate: DateTime(2026, 5, 3),
    financialTransactionId: status == PurchaseStatus.delivered ? 'ft-1' : null,
  );
}

void main() {
  group('PurchaseCard', () {
    testWidgets('confirma pedido para compra pendente', (tester) async {
      final purchaseService = FakePurchaseService();
      final authController = AuthController(bootstrapOnInit: false);

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          child: PurchaseCard(
            purchase: _purchase(PurchaseStatus.pending),
            purchaseService: purchaseService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Cimento CP-II'), findsOneWidget);
      expect(find.text('Confirmar pedido'), findsOneWidget);

      await tester.tap(find.text('Confirmar pedido'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(purchaseService.lastUpdatedStatusId, 'purchase-1');
      expect(purchaseService.lastUpdatedStatus, PurchaseStatus.ordered);
      authController.dispose();
    });

    testWidgets('confirma entrega para compra ja pedida', (tester) async {
      final authController = _TestAuthController(
        const UserModel(
          uid: 'user-1',
          email: 'ceo@granith.com',
          displayName: 'CEO Granith',
          role: UserRole.admin,
        ),
      );
      final purchaseService = FakePurchaseService();

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          child: PurchaseCard(
            purchase: _purchase(PurchaseStatus.ordered),
            purchaseService: purchaseService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Confirmar entrega'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Confirmar entrega').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(purchaseService.lastConfirmedDeliveryPurchase?.id, 'purchase-1');
      expect(purchaseService.lastReceivedBy, 'user-1');

      authController.dispose();
    });

    testWidgets('aprova e recusa compra aguardando CEO', (tester) async {
      final authController = _TestAuthController(
        const UserModel(
          uid: 'user-1',
          email: 'ceo@granith.com',
          displayName: 'CEO Granith',
          role: UserRole.admin,
        ),
      );
      final purchaseService = FakePurchaseService();

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          child: PurchaseCard(
            purchase: _purchase(PurchaseStatus.awaitingApproval),
            purchaseService: purchaseService,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Aprovar compra'), findsOneWidget);
      expect(find.text('Recusar'), findsOneWidget);

      await tester.tap(find.text('Aprovar compra'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Aprovar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(purchaseService.lastApprovedPurchaseId, 'purchase-1');
      expect(purchaseService.lastApprovedByName, 'CEO Granith');

      await tester.tap(find.text('Recusar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.enterText(find.byType(TextField), 'Preco acima do previsto');
      await tester.tap(find.text('Recusar').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(purchaseService.lastRejectedPurchaseId, 'purchase-1');
      expect(purchaseService.lastRejectionReason, 'Preco acima do previsto');

      authController.dispose();
    });

    testWidgets('mostra despesa lancada quando compra ja foi entregue', (
      tester,
    ) async {
      final authController = AuthController(bootstrapOnInit: false);

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          child: PurchaseCard(purchase: _purchase(PurchaseStatus.delivered)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.textContaining('Despesa'), findsOneWidget);

      authController.dispose();
    });
  });
}
