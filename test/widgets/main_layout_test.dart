import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/screens/main_layout.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_system_settings_service.dart';

Widget _buildHarness({
  required AuthViewModel auth,
  required SystemSettingsViewModel settings,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: MaterialApp(
      home: MainLayout(
        pagesOverride: const [
          Scaffold(body: Text('dashboard-page')),
          Scaffold(body: Text('projects-page')),
        ],
        pageTitlesOverride: const ['Granith ERP', 'Projetos'],
        pageIconsOverride: const [
          Icons.dashboard_rounded,
          Icons.business_rounded,
        ],
        navigationModulesOverride: const [
          NavigationModule(
            index: 0,
            title: 'Granith ERP',
            section: 'Inicio',
            icon: Icons.dashboard_rounded,
            aliases: 'dashboard home',
          ),
          NavigationModule(
            index: 1,
            title: 'Projetos',
            section: 'Operacional',
            icon: Icons.business_rounded,
            aliases: 'obras projetos',
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('MainLayout', () {
    testWidgets('permite navegar entre modulos no layout desktop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('employee-1', 'colab@granith.com'),
        profile: const UserModel(
          uid: 'employee-1',
          email: 'colab@granith.com',
          role: UserRole.employee,
        ),
      );
      final auth = AuthViewModel(service: authService);
      final settings = SystemSettingsViewModel(
        service: FakeSystemSettingsService(),
      );

      await tester.pumpWidget(_buildHarness(auth: auth, settings: settings));
      await tester.pumpAndSettle();

      expect(find.text('dashboard-page'), findsOneWidget);

      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();

      expect(find.text('projects-page'), findsOneWidget);
      await authService.dispose();
    });

    testWidgets('confirma logout e encerra sessao', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('admin-1', 'admin@granith.com'),
        profile: const UserModel(
          uid: 'admin-1',
          email: 'admin@granith.com',
          role: UserRole.admin,
        ),
      );
      final auth = AuthViewModel(service: authService);
      final settings = SystemSettingsViewModel(
        service: FakeSystemSettingsService(),
      );

      await tester.pumpWidget(_buildHarness(auth: auth, settings: settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sair').first);
      await tester.pumpAndSettle();

      expect(find.text('Encerrar sessao?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sair'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authService.signOutCalled, isTrue);
      await authService.dispose();
    });
  });
}
