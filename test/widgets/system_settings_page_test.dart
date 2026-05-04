import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/screens/system_settings_page.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_system_settings_service.dart';

void main() {
  group('SystemSettingsPage', () {
    testWidgets('carrega configuracoes, permite editar e salva com feedback', (
      tester,
    ) async {
      final service = FakeSystemSettingsService(
        settings: const SystemSettings(
          workspaceName: 'Granith Base',
          workspaceTagline: 'Operacao conectada',
          dashboardGreetingTitle: 'Boa noite',
          dashboardGreetingSubtitle: 'Tudo sob controle',
          supportEmail: 'suporte@granith.com',
          compactNavigation: false,
        ),
      );

      final viewModel = SystemSettingsViewModel(
        service: service,
        bootstrapOnInit: false,
      );
      await viewModel.loadSettings();

      await tester.pumpWidget(
        ChangeNotifierProvider<SystemSettingsViewModel>.value(
          value: viewModel,
          child: const MaterialApp(home: SystemSettingsPage()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Central de Configuracoes'), findsOneWidget);
      expect(find.text('Granith Base'), findsWidgets);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome do workspace'),
        'Granith Enterprise',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Tagline operacional'),
        'Execucao com governanca',
      );

      await tester.ensureVisible(find.text('Menu lateral compacto'));
      await tester.tap(find.text('Menu lateral compacto'));
      await tester.pump();

      await tester.ensureVisible(find.text('Salvar configuracoes'));
      await tester.tap(find.text('Salvar configuracoes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(service.lastSavedSettings, isNotNull);
      expect(service.lastSavedSettings?.workspaceName, 'Granith Enterprise');
      expect(
        service.lastSavedSettings?.workspaceTagline,
        'Execucao com governanca',
      );
      expect(service.lastSavedSettings?.compactNavigation, isTrue);
      expect(find.text('Configuracoes salvas com sucesso.'), findsOneWidget);
    });
  });
}
