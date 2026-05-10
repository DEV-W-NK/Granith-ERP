import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/navigation/sidebar_menu.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_system_settings_service.dart';

Widget _buildHarness({
  required AuthViewModel auth,
  required SystemSettingsViewModel settings,
  required bool isExpanded,
  required ValueChanged<int> onItemSelected,
  required VoidCallback onToggle,
  required Future<void> Function() onLogout,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SidebarMenu(
          selectedIndex: 0,
          modules: const [
            NavigationModule(
              index: 0,
              title: 'Dashboard',
              section: 'Inicio',
              icon: Icons.dashboard_rounded,
              aliases: 'home painel',
            ),
            NavigationModule(
              index: 1,
              title: 'Projetos',
              section: 'Operacional',
              icon: Icons.business_rounded,
              aliases: 'obras contratos',
            ),
            NavigationModule(
              index: 17,
              title: 'Financeiro',
              section: 'Financeiro',
              icon: Icons.account_balance_rounded,
              aliases: 'financeiro caixa',
            ),
            NavigationModule(
              index: 18,
              title: 'Compras no Financeiro',
              section: 'Financeiro',
              icon: Icons.receipt_long_rounded,
              aliases: 'compras pagar',
            ),
            NavigationModule(
              index: 19,
              title: 'DRE Gerencial',
              section: 'Financeiro',
              icon: Icons.bar_chart_rounded,
              aliases: 'dre resultados',
            ),
            NavigationModule(
              index: 20,
              title: 'Permissoes e Clientes',
              section: 'Administrativo',
              icon: Icons.admin_panel_settings_rounded,
              aliases: 'acessos usuarios',
            ),
          ],
          isExpanded: isExpanded,
          onItemSelected: onItemSelected,
          onToggle: onToggle,
          onLogout: onLogout,
        ),
      ),
    ),
  );
}

void main() {
  group('SidebarMenu', () {
    testWidgets('renderiza modo expandido e delega selecao e logout', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('u1', 'gestor@granith.com'),
        profile: const UserModel(
          uid: 'u1',
          email: 'gestor@granith.com',
          role: UserRole.admin,
        ),
      );
      final auth = AuthViewModel(service: authService);
      final settings = SystemSettingsViewModel(
        service: FakeSystemSettingsService(),
      );
      int? selectedIndex;
      var toggled = false;
      var loggedOut = false;

      await tester.pumpWidget(
        _buildHarness(
          auth: auth,
          settings: settings,
          isExpanded: true,
          onItemSelected: (index) => selectedIndex = index,
          onToggle: () => toggled = true,
          onLogout: () async => loggedOut = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GRANITH'), findsOneWidget);
      expect(find.text('Projetos'), findsOneWidget);
      expect(find.text('Entradas e Saidas'), findsOneWidget);
      expect(find.text('Compras a Pagar'), findsOneWidget);
      expect(find.text('DRE'), findsOneWidget);
      expect(find.text('Permissoes'), findsNothing);
      expect(find.text('Acessos'), findsOneWidget);
      expect(find.text('gestor@granith.com'), findsOneWidget);

      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);

      await tester.tap(find.byIcon(Icons.menu_open_rounded));
      await tester.pumpAndSettle();
      expect(toggled, isTrue);

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(loggedOut, isTrue);

      await authService.dispose();
    });

    testWidgets('renderiza modo recolhido e expande menu', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final auth = AuthViewModel(
        service: FakeAuthService(),
        bootstrapOnInit: false,
      );
      final settings = SystemSettingsViewModel(
        service: FakeSystemSettingsService(),
      );
      var toggled = false;

      await tester.pumpWidget(
        _buildHarness(
          auth: auth,
          settings: settings,
          isExpanded: false,
          onItemSelected: (_) {},
          onToggle: () => toggled = true,
          onLogout: () async {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GRANITH'), findsNothing);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      expect(toggled, isTrue);
    });
  });
}
