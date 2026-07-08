import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/features/client_portal/presentation/viewmodels/client_projects_portal_view_model.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/user_model.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_daily_log_service.dart';
import '../helpers/fake_project_measurement_service.dart';
import '../helpers/fake_project_service.dart';

Future<void> _flushQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('ClientProjectsPortalViewModel', () {
    test(
      'load organiza projetos e calcula avancos com conta vinculada',
      () async {
        final authService = FakeAuthService(
          currentUserValue: const FakeAuthUser('u1', 'cliente@granith.com'),
          profile: const UserModel(
            uid: 'u1',
            email: 'cliente@granith.com',
            role: UserRole.client,
          ),
          ownedAccounts: [
            ClientAccount.empty().copyWith(
              id: 'client-1',
              name: 'Cliente Atlas',
              ownerEmail: 'cliente@granith.com',
              portalAccessStatus: ClientPortalAccessStatus.active,
            ),
          ],
        );
        final auth = AuthViewModel(service: authService);
        await _flushQueue();

        final projectService = FakeProjectService(
          initialProjects: [
            Project(
              id: 'p-1',
              name: 'Planejamento Norte',
              client: 'Cliente Atlas',
              description: '',
              status: ProjectStatus.planning,
              startDate: DateTime(2026, 1, 1),
              budget: 100000,
              currentCost: 10000,
              location: 'SP',
              tags: const [],
              teamSize: 3,
              clientAccountId: 'client-1',
            ),
            Project(
              id: 'p-2',
              name: 'Estrutura Sul',
              client: 'Cliente Atlas',
              description: '',
              status: ProjectStatus.inProgress,
              startDate: DateTime(2026, 3, 1),
              budget: 100000,
              currentCost: 20000,
              location: 'SP',
              tags: const [],
              teamSize: 6,
              clientAccountId: 'client-1',
              estimatedProgress: 55,
              measuredAmount: 55000,
              measurementCount: 2,
            ),
          ],
        );

        final viewModel = ClientProjectsPortalViewModel(
          projectService: projectService,
          measurementService: FakeProjectMeasurementService(
            initialMeasurements: [
              ProjectMeasurement(
                id: 'm-1',
                projectId: 'p-2',
                projectName: 'Estrutura Sul',
                projectClient: 'Cliente Atlas',
                title: 'Medicao aprovada',
                sequence: 1,
                status: ProjectMeasurementStatus.approved,
                measurementDate: DateTime(2026, 4, 1),
                grossAmount: 55000,
                discountAmount: 5000,
                netAmount: 50000,
                accumulatedGrossAmount: 55000,
                measurementPercentage: 55,
                accumulatedPercentage: 55,
                contractBalance: 45000,
                notes: '',
              ),
              ProjectMeasurement(
                id: 'm-pending',
                projectId: 'p-2',
                projectName: 'Estrutura Sul',
                projectClient: 'Cliente Atlas',
                title: 'Medicao pendente',
                sequence: 2,
                status: ProjectMeasurementStatus.pending,
                measurementDate: DateTime(2026, 5, 1),
                grossAmount: 10000,
                discountAmount: 0,
                netAmount: 10000,
                accumulatedGrossAmount: 65000,
                measurementPercentage: 10,
                accumulatedPercentage: 65,
                contractBalance: 35000,
                notes: '',
              ),
            ],
          ),
        );
        await viewModel.load(auth);

        expect(viewModel.activeAccount?.id, 'client-1');
        expect(viewModel.projects, hasLength(2));
        expect(viewModel.projects.first.id, 'p-2');
        expect(viewModel.inProgressProjects, 1);
        expect(viewModel.completedProjects, 0);
        expect(viewModel.averageProgress, 32.5);
        expect(viewModel.totalApprovedMeasurements, 1);
        expect(viewModel.approvedMeasurementsAmount, 50000);
        expect(
          viewModel.approvedMeasurementsForProject('p-2').single.id,
          'm-1',
        );

        await authService.dispose();
      },
    );

    test('load agrupa diarios assinados por projeto', () async {
      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('u1', 'cliente@granith.com'),
        profile: const UserModel(
          uid: 'u1',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: [
          ClientAccount.empty().copyWith(
            id: 'client-1',
            name: 'Cliente Atlas',
            ownerEmail: 'cliente@granith.com',
            portalAccessStatus: ClientPortalAccessStatus.active,
          ),
        ],
      );
      final auth = AuthViewModel(service: authService);
      await _flushQueue();

      final dailyLogService =
          FakeDailyLogService()
            ..nextLogs = [
              DailyLogModel(
                id: 'log-1',
                projectId: 'p-1',
                projectName: 'Obra Alfa',
                date: DateTime(2026, 5, 3),
                activitiesDescription: 'Avanco estrutural',
                createdByUserId: 'u1',
                status: LogStatus.signed,
              ),
            ];

      final viewModel = ClientProjectsPortalViewModel(
        projectService: FakeProjectService(
          initialProjects: [
            Project(
              id: 'p-1',
              name: 'Obra Alfa',
              client: 'Cliente Atlas',
              description: '',
              status: ProjectStatus.inProgress,
              startDate: DateTime(2026),
              budget: 100000,
              currentCost: 10000,
              location: 'SP',
              tags: const [],
              teamSize: 3,
              clientAccountId: 'client-1',
            ),
          ],
        ),
        dailyLogService: dailyLogService,
        measurementService: FakeProjectMeasurementService(),
      );

      await viewModel.load(auth);

      expect(viewModel.totalSignedDailyLogs, 1);
      expect(viewModel.signedLogsForProject('p-1'), hasLength(1));

      await authService.dispose();
    });

    test('load sem conta vinculada retorna vazio sem erro', () async {
      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('u2', 'colab@granith.com'),
        profile: const UserModel(
          uid: 'u2',
          email: 'colab@granith.com',
          role: UserRole.employee,
        ),
      );
      final auth = AuthViewModel(service: authService);
      await _flushQueue();

      final viewModel = ClientProjectsPortalViewModel(
        projectService: FakeProjectService(),
        measurementService: FakeProjectMeasurementService(),
      );
      await viewModel.load(auth);

      expect(viewModel.activeAccount, isNull);
      expect(viewModel.projects, isEmpty);
      expect(viewModel.errorMessage, isNull);

      await authService.dispose();
    });

    test('load expõe mensagem quando a consulta falha', () async {
      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('u3', 'cliente@granith.com'),
        profile: const UserModel(
          uid: 'u3',
          email: 'cliente@granith.com',
          role: UserRole.client,
        ),
        ownedAccounts: [
          ClientAccount.empty().copyWith(
            id: 'client-2',
            name: 'Cliente Boreal',
            ownerEmail: 'cliente@granith.com',
            portalAccessStatus: ClientPortalAccessStatus.active,
          ),
        ],
      );
      final auth = AuthViewModel(service: authService);
      await _flushQueue();

      final projectService =
          FakeProjectService()
            ..getProjectsByClientAccountError = Exception('offline');
      final viewModel = ClientProjectsPortalViewModel(
        projectService: projectService,
        measurementService: FakeProjectMeasurementService(),
      );

      await viewModel.load(auth);

      expect(viewModel.projects, isEmpty);
      expect(
        viewModel.errorMessage,
        'Nao foi possivel carregar os projetos do cliente.',
      );

      await authService.dispose();
    });
  });
}
