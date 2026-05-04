import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/client_portal/presentation/pages/client_projects_portal_page.dart';
import 'package:project_granith/features/client_portal/presentation/viewmodels/client_projects_portal_view_model.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:provider/provider.dart';
import '../helpers/fake_auth_service.dart';
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
      );

      await tester.pumpWidget(_buildHarness(auth: auth, viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('ACOMPANHAMENTO DE OBRAS'), findsOneWidget);
      expect(find.text('Cliente Norte'), findsOneWidget);
      expect(find.text('Projetos'), findsOneWidget);
      expect(find.text('Avanco medio'), findsOneWidget);
      expect(find.text('Obra Alfa'), findsOneWidget);
      expect(find.text('Obra Beta'), findsOneWidget);
      expect(find.text('71%'), findsOneWidget);

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
      );

      await tester.pumpWidget(_buildHarness(auth: auth, viewModel: viewModel));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum projeto vinculado'), findsOneWidget);
      await authService.dispose();
    });
  });
}
