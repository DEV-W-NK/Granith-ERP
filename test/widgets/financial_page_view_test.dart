import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/financial/financialpage_page_widgets.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_financial_service.dart';
import '../helpers/fake_service_projetos.dart';

class _TestAuthController extends AuthController {
  _TestAuthController(this._user) : super(bootstrapOnInit: false);

  final UserModel _user;

  @override
  UserModel? get user => _user;

  @override
  bool get isInitialized => true;
}

void main() {
  group('FinancialPageView', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      required FinancialController controller,
      AuthController? authController,
      Size size = const Size(1400, 900),
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final resolvedAuthController =
          authController ??
          _TestAuthController(
            const UserModel(
              uid: 'admin',
              email: 'admin@granith.com',
              role: UserRole.admin,
            ),
          );
      addTearDown(resolvedAuthController.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(
              value: resolvedAuthController,
            ),
            ChangeNotifierProvider<FinancialController>.value(
              value: controller,
            ),
            ChangeNotifierProvider<ProjectsController>(
              create: (_) => ProjectsController(FakeServiceProjetos()),
            ),
          ],
          child: const MaterialApp(home: FinancialPageView()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('renderiza indicadores e lista de transacoes no desktop', (
      tester,
    ) async {
      final service = FakeFinancialService();
      addTearDown(service.dispose);

      final controller = FinancialController(service: service)..init();
      service.emit([
        FinancialTransactionModel(
          id: 'tx-income',
          description: 'Recebimento contrato',
          amount: 15000,
          type: TransactionType.income,
          status: TransactionStatus.paid,
          origin: TransactionOrigin.manual,
          category: TransactionCategory.measurement,
          dueDate: DateTime(2026, 5, 3),
          paymentDate: DateTime(2026, 5, 3),
          createdBy: 'admin',
          createdAt: DateTime(2026, 5, 3),
        ),
        FinancialTransactionModel(
          id: 'tx-expense',
          description: 'Compra de concreto',
          amount: 5000,
          type: TransactionType.expense,
          status: TransactionStatus.pending,
          origin: TransactionOrigin.purchase,
          category: TransactionCategory.material,
          dueDate: DateTime(2026, 5, 10),
          createdBy: 'admin',
          createdAt: DateTime(2026, 5, 3),
        ),
      ]);

      await pumpPage(tester, controller: controller);

      expect(find.textContaining('Gest'), findsOneWidget);
      expect(find.text('Saldo em caixa'), findsOneWidget);
      expect(find.text('Receitas recebidas'), findsOneWidget);
      expect(find.text('Recebimento contrato'), findsOneWidget);
      expect(find.text('Compra de concreto'), findsOneWidget);
    });

    testWidgets('renderiza estado vazio e FAB no mobile', (tester) async {
      final service = FakeFinancialService();
      addTearDown(service.dispose);

      final controller = FinancialController(service: service)..init();
      service.emit(const []);

      await pumpPage(
        tester,
        controller: controller,
        size: const Size(430, 900),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.textContaining('Nenhuma movimenta'), findsOneWidget);
    });

    testWidgets('bloqueia compras sem permissao do financeiro geral', (
      tester,
    ) async {
      final service = FakeFinancialService();
      addTearDown(service.dispose);

      final controller = FinancialController(service: service)..init();
      service.emit(const []);

      final authController = _TestAuthController(
        const UserModel(
          uid: 'buyer-1',
          email: 'compras@granith.com',
          permissions: [PermissionCodes.purchasesConsolidate],
        ),
      );

      await pumpPage(
        tester,
        controller: controller,
        authController: authController,
      );

      expect(
        find.textContaining('permissao para acessar o financeiro geral'),
        findsOneWidget,
      );
      expect(find.textContaining('Gest'), findsNothing);
    });
  });
}
