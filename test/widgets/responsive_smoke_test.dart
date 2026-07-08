import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/controllers/subscription_controller.dart';
import 'package:project_granith/features/client_portal/presentation/pages/client_projects_portal_page.dart';
import 'package:project_granith/features/client_portal/presentation/viewmodels/client_projects_portal_view_model.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/screens/main_layout.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/home_page/home_page_view.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';
import 'package:project_granith/widgets/projects/projects_page_widgets.dart';
import 'package:project_granith/widgets/subscription/subscription_dashboard.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_project_budget_service.dart';
import '../helpers/fake_project_measurement_service.dart';
import '../helpers/fake_project_service.dart';
import '../helpers/fake_service_projetos.dart';
import '../helpers/fake_system_settings_service.dart';
import '../helpers/fake_usage_service.dart';

const _responsiveSizes = <Size>[
  Size(390, 900),
  Size(430, 900),
  Size(768, 1024),
];

class _FakeHomeViewModel extends HomeViewModel {
  @override
  bool get isLoading => false;

  @override
  List<StatItem> get stats => [
    StatItem(
      label: 'ULTIMO CONTRATADO COM LABEL EXTENSO',
      value: 'Ana Carolina do Nascimento',
      delta: 'Entrou hoje no time operacional',
      deltaUp: true,
      accent: AppColors.green,
      icon: Icons.person_add_alt_1_rounded,
    ),
    StatItem(
      label: 'ULTIMA OBRA FECHADA',
      value: 'Residencial Alto da Serra',
      delta: 'Concluida nesta semana',
      deltaUp: true,
      accent: AppColors.gold,
      icon: Icons.task_alt_rounded,
    ),
    StatItem(
      label: 'EQUIPE EM CAMPO HOJE',
      value: '128 pessoas',
      delta: 'Diarios em andamento',
      deltaUp: true,
      accent: AppColors.blue,
      icon: Icons.engineering_rounded,
    ),
    StatItem(
      label: 'RELATORIOS LIBERADOS',
      value: '24 assinados',
      delta: 'Visiveis no portal do cliente',
      deltaUp: true,
      accent: AppColors.auraCyan,
      icon: Icons.verified_rounded,
    ),
  ];

  @override
  List<ActivityItem> get recentActivities => [
    ActivityItem(
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.green,
      title: 'Obra fechada com descricao muito longa',
      subtitle: 'Projeto Residencial Alto da Serra - Etapa de acabamento',
      value: 'Hoje',
      time: 'Hoje',
      isPositive: true,
    ),
  ];

  @override
  Future<void> loadDashboardData() async {}
}

Future<SystemSettingsViewModel> _settingsViewModel() async {
  final viewModel = SystemSettingsViewModel(
    service: FakeSystemSettingsService(
      settings: const SystemSettings(
        dashboardGreetingTitle: 'Panorama operacional de hoje',
        dashboardGreetingSubtitle:
            'Equipe, obras e entregas em uma visao consolidada',
        aiAssistantPreviewEnabled: true,
      ),
    ),
    bootstrapOnInit: false,
  );
  await viewModel.loadSettings();
  return viewModel;
}

Project _project({
  required String id,
  String? clientAccountId,
  ProjectStatus status = ProjectStatus.inProgress,
}) {
  return Project(
    id: id,
    name: 'Residencial Alto da Serra - Torre Norte - Pavimento Tecnico $id',
    client: 'Cliente Corporativo com Nome Comercial Bastante Extenso',
    description:
        'Projeto com descricao extensa para validar quebra de texto em cards.',
    status: status,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 1),
    budget: 123456789,
    currentCost: 45678912,
    location: 'Avenida Brigadeiro Faria Lima, Sao Paulo',
    tags: const ['estrutura', 'acabamento', 'cliente-prioritario'],
    teamSize: 48,
    clientAccountId: clientAccountId,
    estimatedProgress: 64,
    measuredAmount: 6543210,
    measurementCount: 12,
  );
}

UsageStatsModel _usage() {
  return UsageStatsModel(
    tenantId: 'granith',
    projectRef: 'project-ref-with-long-readable-name',
    totalApiRequests: 1234567,
    databaseUsedMB: 32768,
    storageUsedMB: 8192,
    periodStart: DateTime(2026, 5, 1),
    periodEnd: DateTime(2026, 5, 5),
    sourceLabel: 'Snapshot oficial sincronizado com detalhamento operacional',
    lastSyncedAt: DateTime(2026, 5, 5, 10, 30),
    dailyOperations: const {
      '2026-05-01': 1200,
      '2026-05-02': 1800,
      '2026-05-03': 2600,
      '2026-05-04': 3100,
      '2026-05-05': 2900,
    },
    hasSnapshot: true,
  );
}

void _expectNoResponsiveException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

void main() {
  group('Responsive smoke', () {
    for (final size in _responsiveSizes) {
      testWidgets('home renderiza sem overflow em ${size.width}px', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<HomeViewModel>.value(
                value: _FakeHomeViewModel(),
              ),
              ChangeNotifierProvider<SystemSettingsViewModel>.value(
                value: await _settingsViewModel(),
              ),
            ],
            child: const MaterialApp(home: HomePageView()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Panorama operacional de hoje'), findsOneWidget);
        _expectNoResponsiveException(tester);
      });

      testWidgets('projetos renderiza sem overflow em ${size.width}px', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final controller = ProjectsController(
          FakeServiceProjetos(projects: [_project(id: 'p-1')]),
          searchDebounceDelay: Duration.zero,
        );
        await controller.loadProjects();
        controller.setViewMode(false);

        await tester.pumpWidget(
          ChangeNotifierProvider<ProjectsController>.value(
            value: controller,
            child: MaterialApp(
              home: ProjectsPageView(budgetService: FakeProjectBudgetService()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Projetos'), findsOneWidget);
        _expectNoResponsiveException(tester);
      });

      testWidgets(
        'portal do cliente renderiza sem overflow em ${size.width}px',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final authService = FakeAuthService(
            currentUserValue: const FakeAuthUser(
              'client-uid',
              'cliente@test.com',
            ),
            profile: const UserModel(
              uid: 'client-uid',
              email: 'cliente@test.com',
              role: UserRole.client,
            ),
            ownedAccounts: const [
              ClientAccount(
                id: 'client-1',
                name: 'Cliente Corporativo com Nome Comercial Bastante Extenso',
                ownerEmail: 'cliente@test.com',
                contactEmail: 'financeiro@cliente-extenso.com',
                contactPhone: '11999990000',
                portalAccessStatus: ClientPortalAccessStatus.active,
              ),
            ],
          );
          final auth = AuthViewModel(service: authService);
          final viewModel = ClientProjectsPortalViewModel(
            projectService: FakeProjectService(
              initialProjects: [
                _project(id: 'p-1', clientAccountId: 'client-1'),
              ],
            ),
            measurementService: FakeProjectMeasurementService(),
          );

          await tester.pumpWidget(
            ChangeNotifierProvider<AuthViewModel>.value(
              value: auth,
              child: MaterialApp(
                home: ClientProjectsPortalPage(viewModel: viewModel),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('ACOMPANHAMENTO DE OBRAS'), findsOneWidget);
          _expectNoResponsiveException(tester);
          await authService.dispose();
        },
      );

      testWidgets('assinatura renderiza sem overflow em ${size.width}px', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authService = FakeAuthService(
          currentUserValue: const FakeAuthUser('admin-uid', 'admin@test.com'),
          profile: const UserModel(
            uid: 'admin-uid',
            email: 'admin@test.com',
            role: UserRole.admin,
          ),
        );
        final usageService = FakeUsageService()..currentUsage = _usage();
        final auth = AuthViewModel(service: authService);
        final controller = SubscriptionController(usageService: usageService);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthViewModel>.value(value: auth),
              ChangeNotifierProvider<SubscriptionController>.value(
                value: controller,
              ),
            ],
            child: const MaterialApp(home: SubscriptionDashboard()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Uso da Plataforma'), findsOneWidget);
        _expectNoResponsiveException(tester);
        await authService.dispose();
      });

      testWidgets(
        'layout principal usa navegacao compacta em ${size.width}px',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final authService = FakeAuthService(
            currentUserValue: const FakeAuthUser('admin-uid', 'admin@test.com'),
            profile: const UserModel(
              uid: 'admin-uid',
              email: 'admin@test.com',
              role: UserRole.admin,
            ),
          );
          final auth = AuthViewModel(service: authService);

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AuthViewModel>.value(value: auth),
                ChangeNotifierProvider<SystemSettingsViewModel>.value(
                  value: await _settingsViewModel(),
                ),
              ],
              child: const MaterialApp(
                home: MainLayout(
                  pagesOverride: [
                    Scaffold(body: Text('dashboard-page')),
                    Scaffold(body: Text('projects-page')),
                  ],
                  pageTitlesOverride: [
                    'Granith ERP com titulo longo',
                    'Projetos operacionais',
                  ],
                  pageIconsOverride: [
                    Icons.dashboard_rounded,
                    Icons.business_rounded,
                  ],
                  navigationModulesOverride: [
                    NavigationModule(
                      index: 0,
                      title: 'Granith ERP com titulo longo',
                      section: 'Inicio',
                      icon: Icons.dashboard_rounded,
                      aliases: 'dashboard home',
                    ),
                    NavigationModule(
                      index: 1,
                      title: 'Projetos operacionais',
                      section: 'Operacional',
                      icon: Icons.business_rounded,
                      aliases: 'obras projetos',
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(SidebarMenu), findsNothing);
          expect(find.text('dashboard-page'), findsOneWidget);
          _expectNoResponsiveException(tester);
          await authService.dispose();
        },
      );
    }
  });
}
