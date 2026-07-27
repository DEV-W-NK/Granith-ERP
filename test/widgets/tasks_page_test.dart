import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/granith_task.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/screens/tasks_page.dart';
import 'package:project_granith/services/granith_task_service.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_auth_service.dart';

void main() {
  testWidgets('administrador sem funcionario vinculado pode criar tarefa', (
    tester,
  ) async {
    final authService = FakeAuthService(
      currentUserValue: const FakeAuthUser('admin-1', 'admin@granith.com'),
      profile: const UserModel(
        uid: 'admin-1',
        email: 'admin@granith.com',
        role: UserRole.admin,
      ),
    );
    final auth = AuthViewModel(service: authService);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp(
          home: Scaffold(body: TasksPage(service: _FakeTaskService())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final createButton = find.ancestor(
      of: find.text('Nova tarefa'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(createButton, findsOneWidget);
    expect(tester.widget<FilledButton>(createButton).onPressed, isNotNull);

    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Criar tarefa'), findsOneWidget);
    expect(find.text('Responsavel / supervisor'), findsOneWidget);

    auth.dispose();
    await authService.dispose();
  });

  testWidgets('funcionario comum recebe explicacao ao nao poder criar', (
    tester,
  ) async {
    final authService = FakeAuthService(
      currentUserValue: const FakeAuthUser(
        'employee-1',
        'employee@granith.com',
      ),
      profile: const UserModel(
        uid: 'employee-1',
        email: 'employee@granith.com',
        role: UserRole.employee,
      ),
    );
    final auth = AuthViewModel(service: authService);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp(
          home: Scaffold(
            body: TasksPage(
              service: _FakeTaskService(
                currentEmployee: _employee(
                  id: 'employee-1',
                  role: EmployeeRole.funcionario,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final createButton = find.ancestor(
      of: find.text('Nova tarefa'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(tester.widget<FilledButton>(createButton).onPressed, isNull);
    expect(find.textContaining('people.manage'), findsOneWidget);

    auth.dispose();
    await authService.dispose();
  });
}

class _FakeTaskService extends GranithTaskService {
  _FakeTaskService({this.currentEmployee});

  final EmployeeModel? currentEmployee;

  @override
  Stream<List<GranithTask>> watchTasks() => Stream.value(const []);

  @override
  Future<List<EmployeeModel>> getActiveEmployees() async => [
    _employee(id: 'supervisor-1', role: EmployeeRole.supervisor),
    _employee(id: 'executor-1', role: EmployeeRole.funcionario),
  ];

  @override
  Future<List<Project>> getProjects() async => const [];

  @override
  Future<List<Budget>> getBudgets() async => const [];

  @override
  Future<EmployeeModel?> getCurrentEmployee() async => currentEmployee;
}

EmployeeModel _employee({required String id, required EmployeeRole role}) {
  return EmployeeModel(
    id: id,
    name: id,
    email: '$id@granith.com',
    phone: '11999999999',
    jobTitle: role.label,
    sector: 'Operacional',
    role: role,
    status: EmployeeStatus.ativo,
    admissionDate: DateTime(2026, 1, 1),
    baseSalary: 0,
    educationLevel: '',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}
