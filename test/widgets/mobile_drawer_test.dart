import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/widgets/navigation/mobile_drawer.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_system_settings_service.dart';

Widget _buildHarness({
  required AuthViewModel auth,
  required SystemSettingsViewModel settings,
  required ValueChanged<int> onItemSelected,
  required Future<void> Function() onLogout,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: settings),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: MobileDrawer(
          selectedIndex: 0,
          onItemSelected: onItemSelected,
          onLogout: onLogout,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renderiza drawer mobile e delega selecao/logout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authService = FakeAuthService(
      currentUserValue: const FakeAuthUser('u1', 'colab@granith.com'),
      profile: const UserModel(
        uid: 'u1',
        email: 'colab@granith.com',
        role: UserRole.employee,
      ),
    );
    final auth = AuthViewModel(service: authService);
    final settings = SystemSettingsViewModel(
      service: FakeSystemSettingsService(),
    );
    int? selectedIndex;
    var loggedOut = false;

    await tester.pumpWidget(
      _buildHarness(
        auth: auth,
        settings: settings,
        onItemSelected: (index) => selectedIndex = index,
        onLogout: () async => loggedOut = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GRANITH'), findsOneWidget);

    await tester.tap(find.text('Projetos'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);

    await tester.scrollUntilVisible(
      find.text('colab@granith.com'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('colab@granith.com'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);

    await authService.dispose();
  });
}
