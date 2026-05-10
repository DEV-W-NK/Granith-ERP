import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/home_page/home_page_view.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_system_settings_service.dart';

class _FakeHomeViewModel extends HomeViewModel {
  _FakeHomeViewModel({
    required this.loading,
    required this.items,
    required this.activities,
  });

  final bool loading;
  final List<StatItem> items;
  final List<ActivityItem> activities;
  int loadCalls = 0;

  @override
  bool get isLoading => loading;

  @override
  List<StatItem> get stats => items;

  @override
  List<ActivityItem> get recentActivities => activities;

  @override
  Future<void> loadDashboardData() async {
    loadCalls++;
  }
}

void main() {
  group('HomePageView', () {
    Future<SystemSettingsViewModel> buildSettingsViewModel() async {
      final viewModel = SystemSettingsViewModel(
        service: FakeSystemSettingsService(
          settings: const SystemSettings(
            dashboardGreetingTitle: 'Panorama do dia',
            dashboardGreetingSubtitle: 'Equipe, obras e entregas em destaque',
            aiAssistantPreviewEnabled: true,
          ),
        ),
        bootstrapOnInit: false,
      );
      await viewModel.loadSettings();
      return viewModel;
    }

    testWidgets(
      'mostra loading enquanto dashboard ainda nao terminou de carregar',
      (tester) async {
        final homeViewModel = _FakeHomeViewModel(
          loading: true,
          items: const [],
          activities: const [],
        );
        final settingsViewModel = await buildSettingsViewModel();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
              ChangeNotifierProvider<SystemSettingsViewModel>.value(
                value: settingsViewModel,
              ),
            ],
            child: const MaterialApp(home: HomePageView()),
          ),
        );

        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(homeViewModel.loadCalls, 1);
      },
    );

    testWidgets(
      'renderiza cabecalho, estatisticas e atividades quando carregado',
      (tester) async {
        final homeViewModel = _FakeHomeViewModel(
          loading: false,
          items: [
            StatItem(
              label: 'ULTIMO CONTRATADO',
              value: 'Ana Costa',
              delta: 'Entrou hoje',
              deltaUp: true,
              accent: AppColors.green,
              icon: Icons.person_add_alt_1_rounded,
            ),
            StatItem(
              label: 'ULTIMA OBRA FECHADA',
              value: 'Obra Centro',
              delta: 'Concluida hoje',
              deltaUp: true,
              accent: AppColors.gold,
              icon: Icons.task_alt_rounded,
            ),
            StatItem(
              label: 'EQUIPE EM CAMPO HOJE',
              value: '8 pessoas',
              delta: 'Diarios em ordem',
              deltaUp: true,
              accent: AppColors.blue,
              icon: Icons.engineering_rounded,
            ),
            StatItem(
              label: 'RELATORIOS LIBERADOS',
              value: '3 assinados',
              delta: 'Ultimo hoje',
              deltaUp: true,
              accent: AppColors.auraCyan,
              icon: Icons.verified_rounded,
            ),
          ],
          activities: [
            ActivityItem(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.green,
              title: 'Obra fechada com sucesso',
              subtitle: 'Contrato Torre Norte',
              value: 'Hoje',
              time: 'Hoje',
              isPositive: true,
            ),
          ],
        );
        final settingsViewModel = await buildSettingsViewModel();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
              ChangeNotifierProvider<SystemSettingsViewModel>.value(
                value: settingsViewModel,
              ),
            ],
            child: const MaterialApp(home: HomePageView()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Panorama do dia'), findsOneWidget);
        expect(
          find.text('Equipe, obras e entregas em destaque'),
          findsOneWidget,
        );
        expect(find.text('ULTIMO CONTRATADO'), findsOneWidget);
        expect(find.text('Obra fechada com sucesso'), findsOneWidget);
        expect(find.textContaining('Pulso positivo'), findsNothing);
        expect(find.text('Uso da plataforma'), findsNothing);
        expect(homeViewModel.loadCalls, 1);
      },
    );
  });
}
