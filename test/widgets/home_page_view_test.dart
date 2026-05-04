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
            dashboardGreetingSubtitle: 'Execucao, financeiro e clientes',
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
              label: 'RECEITA DO MES',
              value: 'R\$ 120k',
              delta: '+18%',
              deltaUp: true,
              accent: AppColors.green,
              icon: Icons.trending_up_rounded,
            ),
            StatItem(
              label: 'DESPESAS DO MES',
              value: 'R\$ 72k',
              delta: '-5%',
              deltaUp: false,
              accent: AppColors.red,
              icon: Icons.trending_down_rounded,
            ),
            StatItem(
              label: 'SALDO ATUAL',
              value: 'R\$ 48k',
              delta: '+12%',
              deltaUp: true,
              accent: AppColors.gold,
              icon: Icons.account_balance_wallet_rounded,
            ),
            StatItem(
              label: 'CLIENTES ATIVOS',
              value: '6',
              delta: '+2',
              deltaUp: true,
              accent: AppColors.blue,
              icon: Icons.people_outline_rounded,
            ),
          ],
          activities: [
            ActivityItem(
              icon: Icons.arrow_downward_rounded,
              iconColor: AppColors.green,
              title: 'Pagamento recebido',
              subtitle: 'Contrato Torre Norte',
              value: 'paid',
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
        expect(find.text('Execucao, financeiro e clientes'), findsOneWidget);
        expect(find.text('RECEITA DO MES'), findsOneWidget);
        expect(find.text('Pagamento recebido'), findsOneWidget);
        expect(find.textContaining('Transpar'), findsOneWidget);
        expect(homeViewModel.loadCalls, 1);
      },
    );
  });
}
