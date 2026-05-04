import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/widgets/components/login_logo.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_system_settings_service.dart';

void main() {
  testWidgets('LoginLogo exibe branding configurado', (tester) async {
    final service = FakeSystemSettingsService(
      settings: const SystemSettings(
        workspaceName: 'Skyforge',
        workspaceTagline: 'Construcao com previsibilidade',
      ),
    );
    final viewModel = SystemSettingsViewModel(
      service: service,
      bootstrapOnInit: false,
    );
    await viewModel.loadSettings();

    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 300),
    )..value = 1;

    await tester.pumpWidget(
      ChangeNotifierProvider<SystemSettingsViewModel>.value(
        value: viewModel,
        child: MaterialApp(
          home: Scaffold(body: LoginLogo(parentController: controller)),
        ),
      ),
    );

    expect(find.text('SKYFORGE'), findsOneWidget);
    expect(find.text('Construcao com previsibilidade'), findsOneWidget);
    expect(find.byIcon(Icons.home_work_outlined), findsOneWidget);

    controller.dispose();
  });
}
