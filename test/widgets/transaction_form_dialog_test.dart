import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/auth_controller.dart';
import 'package:project_granith/controllers/financial_controller.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/financial/transactionformdialog.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_financial_service.dart';
import '../helpers/fake_service_projetos.dart';

class _TestAuthController extends AuthController {
  _TestAuthController(this._user) : super(bootstrapOnInit: false);

  final UserModel _user;

  @override
  UserModel? get user => _user;
}

Project _project() {
  return Project(
    id: 'project-1',
    name: 'Projeto Aurora',
    client: 'Cliente Aurora',
    description: 'Projeto comercial',
    status: ProjectStatus.inProgress,
    startDate: DateTime(2026, 5, 1),
    budget: 10000,
    currentCost: 3000,
    location: 'Sao Paulo',
    tags: const ['comercial'],
    teamSize: 8,
  );
}

Widget _buildHarness({
  required AuthController authController,
  required FinancialController financialController,
  required ProjectsController projectsController,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: authController),
      ChangeNotifierProvider<FinancialController>.value(
        value: financialController,
      ),
      ChangeNotifierProvider<ProjectsController>.value(
        value: projectsController,
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('TransactionFormDialog', () {
    testWidgets('valida descricao e valor obrigatorios', (tester) async {
      final authController = AuthController(bootstrapOnInit: false);
      final financialService = FakeFinancialService();
      final financialController = FinancialController(
        service: financialService,
      );
      final projectsController = ProjectsController(
        FakeServiceProjetos(projects: [_project()]),
      );
      await projectsController.loadProjects();

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          financialController: financialController,
          projectsController: projectsController,
          child: const TransactionFormDialog(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.ensureVisible(find.text('REGISTRAR'));
      await tester.tap(find.text('REGISTRAR'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.textContaining('rigat'), findsNWidgets(2));

      projectsController.dispose();
      financialController.dispose();
      await financialService.dispose();
      authController.dispose();
    });

    testWidgets('registra nova receita com projeto selecionado', (
      tester,
    ) async {
      final authController = _TestAuthController(
        const UserModel(
          uid: 'user-1',
          email: 'financeiro@granith.com',
          displayName: 'Financeiro Granith',
          role: UserRole.admin,
        ),
      );
      final financialService = FakeFinancialService();
      final financialController = FinancialController(
        service: financialService,
      );
      final projectsController = ProjectsController(
        FakeServiceProjetos(projects: [_project()]),
      );
      await projectsController.loadProjects();

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          financialController: financialController,
          projectsController: projectsController,
          child: const TransactionFormDialog(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Receita'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Recebimento de medicao',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '1500');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Primeira medicao aprovada',
      );

      await tester.ensureVisible(find.text('Nenhum / Administrativo'));
      await tester.tap(
        find.text('Nenhum / Administrativo'),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Projeto Aurora').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.ensureVisible(find.text('REGISTRAR'));
      await tester.tap(find.text('REGISTRAR'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        financialService.lastAddedTransaction?.description,
        'Recebimento de medicao',
      );
      expect(
        financialService.lastAddedTransaction?.type,
        TransactionType.income,
      );
      expect(financialService.lastAddedTransaction?.projectId, 'project-1');
      expect(financialService.lastAddedTransaction?.createdBy, 'user-1');
      expect(
        financialService.lastAddedTransaction?.notes,
        'Primeira medicao aprovada',
      );

      projectsController.dispose();
      financialController.dispose();
      await financialService.dispose();
      authController.dispose();
    });

    testWidgets('atualiza transacao existente em modo de edicao', (
      tester,
    ) async {
      final authController = _TestAuthController(
        const UserModel(
          uid: 'user-1',
          email: 'financeiro@granith.com',
          displayName: 'Financeiro Granith',
          role: UserRole.admin,
        ),
      );
      final financialService = FakeFinancialService();
      final financialController = FinancialController(
        service: financialService,
      );
      final projectsController = ProjectsController(
        FakeServiceProjetos(projects: [_project()]),
      );
      await projectsController.loadProjects();

      final initial = FinancialTransactionModel(
        id: 'ft-1',
        description: 'Compra de materiais',
        amount: 420,
        type: TransactionType.expense,
        status: TransactionStatus.pending,
        origin: TransactionOrigin.manual,
        category: TransactionCategory.material,
        dueDate: DateTime(2026, 5, 10),
        projectId: 'project-1',
        createdBy: 'user-1',
        createdAt: DateTime(2026, 5, 1),
      );

      await tester.pumpWidget(
        _buildHarness(
          authController: authController,
          financialController: financialController,
          projectsController: projectsController,
          child: TransactionFormDialog(initial: initial),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.enterText(find.byType(TextFormField).at(1), '525');
      await tester.ensureVisible(find.textContaining('SALVAR'));
      await tester.tap(find.textContaining('SALVAR'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(financialService.lastUpdatedTransaction, isNotNull);
      expect(financialService.lastUpdatedTransaction?.id, 'ft-1');
      expect(financialService.lastUpdatedTransaction?.amount, 525);

      projectsController.dispose();
      financialController.dispose();
      await financialService.dispose();
      authController.dispose();
    });
  });
}
