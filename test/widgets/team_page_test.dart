import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/screens/team_page.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_team_service.dart';

EmployeeModel _employee({
  required String id,
  required String name,
  required String email,
  required String sector,
  required EmployeeRole role,
}) {
  return EmployeeModel(
    id: id,
    name: name,
    email: email,
    phone: '11999999999',
    jobTitle: 'Supervisor',
    sector: sector,
    role: role,
    admissionDate: DateTime(2026, 1, 1),
    baseSalary: 3500,
    educationLevel: 'Superior',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Widget _buildHarness({
  required AuthViewModel auth,
  required TeamController controller,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: controller),
    ],
    child: const MaterialApp(home: TeamPage()),
  );
}

void main() {
  group('TeamPage', () {
    testWidgets('Supervisor RH consegue criar equipe', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('u1', 'rh@granith.com'),
        profile: const UserModel(
          uid: 'u1',
          email: 'rh@granith.com',
          role: UserRole.employee,
        ),
      );
      final auth = AuthViewModel(service: authService);
      final teamService = FakeTeamService(
        employees: [
          _employee(
            id: 'e1',
            name: 'Ana RH',
            email: 'rh@granith.com',
            sector: 'RH',
            role: EmployeeRole.supervisor,
          ),
        ],
      );
      final controller = TeamController(service: teamService);

      await tester.pumpWidget(
        _buildHarness(auth: auth, controller: controller),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nova equipe'), findsWidgets);

      await tester.tap(find.text('Nova equipe').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome da equipe'),
        'Equipe Alfa',
      );
      await tester.tap(find.text('Criar equipe'));
      await tester.pumpAndSettle();

      expect(teamService.lastCreatedTeam?.name, 'Equipe Alfa');

      await authService.dispose();
      await teamService.disposeControllers();
      controller.dispose();
    });

    testWidgets('colaborador comum visualiza sem botoes de gestao', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authService = FakeAuthService(
        currentUserValue: const FakeAuthUser('u2', 'colab@granith.com'),
        profile: const UserModel(
          uid: 'u2',
          email: 'colab@granith.com',
          role: UserRole.employee,
        ),
      );
      final auth = AuthViewModel(service: authService);
      final teamService = FakeTeamService(
        employees: [
          _employee(
            id: 'e2',
            name: 'Carlos',
            email: 'colab@granith.com',
            sector: 'Obras',
            role: EmployeeRole.funcionario,
          ),
        ],
      );
      final controller = TeamController(service: teamService);

      await tester.pumpWidget(
        _buildHarness(auth: auth, controller: controller),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nova equipe'), findsNothing);
      expect(find.textContaining('Visualizacao liberada'), findsOneWidget);

      await authService.dispose();
      await teamService.disposeControllers();
      controller.dispose();
    });
  });
}
