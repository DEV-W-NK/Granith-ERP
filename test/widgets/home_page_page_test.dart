import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/widgets/QuickActionsGrid.dart';
import 'package:project_granith/widgets/home/home_page_page_widgets.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_system_settings_service.dart';

void main() {
  testWidgets('HomePage dispara carga inicial e renderiza blocos principais', (
    tester,
  ) async {
    final viewModel = HomeViewModel(
      listLoader: (table, {columns = '*'}) async {
        switch (table) {
          case 'material_requisitions':
            return <Map<String, dynamic>>[];
          case 'financial_transactions':
            return <Map<String, dynamic>>[];
          case 'employees':
            return <Map<String, dynamic>>[];
          default:
            return <Map<String, dynamic>>[];
        }
      },
      projectsLoader: () async => <Map<String, dynamic>>[],
      recentActivitiesLoader: () async => <Map<String, dynamic>>[],
      nowProvider: () => DateTime(2026, 5, 3),
    );
    final settingsViewModel = SystemSettingsViewModel(
      service: FakeSystemSettingsService(),
      bootstrapOnInit: false,
    );
    await settingsViewModel.loadSettings();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeViewModel>.value(value: viewModel),
          ChangeNotifierProvider<SystemSettingsViewModel>.value(
            value: settingsViewModel,
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.textContaining('Pulso positivo'), findsNothing);
    expect(find.byType(QuickActionsGrid), findsOneWidget);
  });
}
