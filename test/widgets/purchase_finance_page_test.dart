import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/financial/purchase_finance_page_widgets.dart';

import '../helpers/fake_financial_service.dart';

class _TestAuthController extends AuthController {
  _TestAuthController(this._user) : super(bootstrapOnInit: false);

  final UserModel _user;

  @override
  UserModel? get user => _user;
}

FinancialTransactionModel _tx({
  required String id,
  required String description,
  required TransactionOrigin origin,
  TransactionStatus status = TransactionStatus.pending,
}) {
  return FinancialTransactionModel(
    id: id,
    description: description,
    amount: 1200,
    type: TransactionType.expense,
    status: status,
    origin: origin,
    category: TransactionCategory.material,
    dueDate: DateTime(2026, 5, 15),
    projectId: 'project-1',
    supplierId: 'supplier-1',
    referenceId: origin == TransactionOrigin.purchase ? 'purchase-1' : null,
    createdBy: 'buyer-1',
    createdAt: DateTime(2026, 5, 8),
  );
}

Widget _buildHarness({
  required AuthController authController,
  required FinancialController financialController,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: authController),
      ChangeNotifierProvider<FinancialController>.value(
        value: financialController,
      ),
    ],
    child: const MaterialApp(
      home: SizedBox(
        width: 1024,
        height: 720,
        child: PurchaseFinancePageView(),
      ),
    ),
  );
}

void main() {
  group('PurchaseFinancePageView', () {
    testWidgets('mostra somente contas originadas por compras', (tester) async {
      final authController = _TestAuthController(
        const UserModel(
          uid: 'buyer-1',
          email: 'compras@granith.com',
          permissions: [PermissionCodes.purchasesConsolidate],
        ),
      );
      final service = FakeFinancialService();
      final financialController = FinancialController(service: service)..init();
      service.emit([
        _tx(
          id: 'purchase-payable',
          description: 'Compra: Cimento',
          origin: TransactionOrigin.purchase,
        ),
        _tx(
          id: 'manual-expense',
          description: 'Conta de luz',
          origin: TransactionOrigin.manual,
        ),
      ]);

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          financialController: financialController,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Compra: Cimento'), findsOneWidget);
      expect(find.text('Conta de luz'), findsNothing);
      expect(find.text('Somente financeiro quita'), findsOneWidget);
      expect(find.text('Marcar pago'), findsNothing);

      financialController.dispose();
      await service.dispose();
      authController.dispose();
    });

    testWidgets('financeiro pode quitar conta de compra', (tester) async {
      final authController = _TestAuthController(
        const UserModel(
          uid: 'finance-1',
          email: 'financeiro@granith.com',
          permissions: [PermissionCodes.purchaseFinanceWrite],
        ),
      );
      final service = FakeFinancialService();
      final financialController = FinancialController(service: service)..init();
      service.emit([
        _tx(
          id: 'purchase-payable',
          description: 'Compra: Cimento',
          origin: TransactionOrigin.purchase,
        ),
      ]);

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          financialController: financialController,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.ensureVisible(find.text('Marcar pago').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marcar pago').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Marcar pago').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(service.lastMarkedAsPaidId, 'purchase-payable');

      financialController.dispose();
      await service.dispose();
      authController.dispose();
    });

    testWidgets('mantem cards estaveis em viewports comuns', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final size in const [
        Size(390, 844),
        Size(1024, 720),
        Size(1366, 768),
      ]) {
        await tester.binding.setSurfaceSize(size);
        final authController = _TestAuthController(
          const UserModel(
            uid: 'finance-1',
            email: 'financeiro@granith.com',
            permissions: [PermissionCodes.purchaseFinanceWrite],
          ),
        );
        final service = FakeFinancialService();
        final financialController = FinancialController(service: service)
          ..init();
        service.emit([
          _tx(
            id: 'purchase-payable',
            description: 'Compra: Cimento',
            origin: TransactionOrigin.purchase,
          ),
          _tx(
            id: 'purchase-paid',
            description: 'Compra: Brita',
            origin: TransactionOrigin.purchase,
            status: TransactionStatus.paid,
          ),
        ]);

        await tester.pumpWidget(
          _buildHarness(
            authController: authController,
            financialController: financialController,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Compras no Financeiro'), findsOneWidget);
        expect(find.text('Em aberto'), findsWidgets);
        expect(find.text('Compra: Cimento'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        financialController.dispose();
        await service.dispose();
        authController.dispose();
      }
    });
  });
}
