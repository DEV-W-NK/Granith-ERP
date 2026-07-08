import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/client_portal/presentation/pages/client_projects_portal_page.dart';
import 'package:project_granith/features/client_portal/presentation/viewmodels/client_projects_portal_view_model.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:provider/provider.dart';
import '../helpers/fake_auth_service.dart';
import '../helpers/fake_project_measurement_service.dart';
import '../helpers/fake_project_service.dart';

Widget _buildHarness({
  required AuthViewModel auth,
  required ClientProjectsPortalViewModel viewModel,
}) {
  return ChangeNotifierProvider.value(
    value: auth,
    child: MaterialApp(home: ClientProjectsPortalPage(viewModel: viewModel)),
  );
}

void main() {
  group('ClientProjectsPortalPage', () {
    testWidgets('renderiza resumo, cards de projeto e permite logout', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('user-1', 'cliente@granith.com'),
        profile: const UserModel(
          uid: 'user-1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: const [
          ClientAccount(
            id: 'client-1',
            name: 'Cliente Norte',
            ownerEmail: 'cliente@granith.com',
            contactEmail: 'contato@clientenorte.com',
            contactPhone: '11999990000',
            portalAccessStatus: ClientPortalAccessStatus.active,
          ),
        ],
      );
      final auth = AuthViewModel(service: authService);
      final projectService = FakeProjectService(
        initialProjects: [
          Project(
            id: 'project-1',
            name: 'Obra Alfa',
            client: 'Cliente Norte',
            description: 'Execucao da fase estrutural',
            status: ProjectStatus.inProgress,
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 1),
            budget: 100000,
            currentCost: 30000,
            location: 'Campinas',
            tags: const [],
            teamSize: 7,
            clientAccountId: 'client-1',
            estimatedProgress: 42,
            measuredAmount: 42000,
            measurementCount: 2,
          ),
          Project(
            id: 'project-2',
            name: 'Obra Beta',
            client: 'Cliente Norte',
            description: 'Acabamento final',
            status: ProjectStatus.completed,
            startDate: DateTime(2025, 7, 1),
            endDate: DateTime(2026, 1, 20),
            budget: 80000,
            currentCost: 78000,
            location: 'Jundiai',
            tags: const [],
            teamSize: 4,
            clientAccountId: 'client-1',
            estimatedProgress: 100,
            measuredAmount: 80000,
            measurementCount: 4,
          ),
        ],
      );
      final viewModel = ClientProjectsPortalViewModel(
        projectService: projectService,
        measurementService: FakeProjectMeasurementService(
          initialMeasurements: [
            ProjectMeasurement(
              id: 'measurement-1',
              projectId: 'project-1',
              projectName: 'Obra Alfa',
              projectClient: 'Cliente Norte',
              title: 'Fase estrutural aprovada',
              sequence: 2,
              status: ProjectMeasurementStatus.approved,
              measurementDate: DateTime(2026, 5, 10),
              grossAmount: 42000,
              discountAmount: 0,
              netAmount: 42000,
              accumulatedGrossAmount: 42000,
              measurementPercentage: 42,
              accumulatedPercentage: 42,
              contractBalance: 58000,
              notes: 'Medicao aprovada pela engenharia.',
            ),
            ProjectMeasurement(
              id: 'measurement-pending',
              projectId: 'project-1',
              projectName: 'Obra Alfa',
              projectClient: 'Cliente Norte',
              title: 'Pendente de aprovacao',
              sequence: 3,
              status: ProjectMeasurementStatus.pending,
              measurementDate: DateTime(2026, 6, 10),
              grossAmount: 15000,
              discountAmount: 0,
              netAmount: 15000,
              accumulatedGrossAmount: 57000,
              measurementPercentage: 15,
              accumulatedPercentage: 57,
              contractBalance: 43000,
              notes: '',
            ),
          ],
        ),
      );

      await tester.pumpWidget(_buildHarness(auth: auth, viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('ACOMPANHAMENTO DE OBRAS'), findsOneWidget);
      expect(find.text('Cliente Norte'), findsWidgets);
      expect(find.text('Projetos'), findsOneWidget);
      expect(find.text('Avanco medio'), findsOneWidget);
      expect(find.text('Obra Alfa'), findsOneWidget);
      expect(find.text('Obra Beta'), findsOneWidget);
      expect(find.text('71%'), findsOneWidget);
      expect(find.text('Detalhes da obra'), findsNWidgets(2));
      expect(find.text('Medicoes aprovadas'), findsOneWidget);
      expect(find.text('Medicoes aprovadas (1)'), findsOneWidget);
      expect(find.text('Fase estrutural aprovada'), findsOneWidget);
      expect(find.text('Pendente de aprovacao'), findsNothing);

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      expect(authService.signOutCalled, isTrue);
      await authService.dispose();
    });

    testWidgets('mostra mensagem quando conta nao possui projetos vinculados', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1500));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('user-1', 'cliente@granith.com'),
        profile: const UserModel(
          uid: 'user-1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: const [
          ClientAccount(
            id: 'client-1',
            name: 'Cliente Norte',
            ownerEmail: 'cliente@granith.com',
            contactEmail: 'contato@clientenorte.com',
            contactPhone: '11999990000',
            portalAccessStatus: ClientPortalAccessStatus.active,
          ),
        ],
      );
      final auth = AuthViewModel(service: authService);
      final viewModel = ClientProjectsPortalViewModel(
        projectService: FakeProjectService(initialProjects: const []),
        measurementService: FakeProjectMeasurementService(),
      );

      await tester.pumpWidget(_buildHarness(auth: auth, viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum projeto vinculado'), findsOneWidget);
      await authService.dispose();
    });
  });
}
