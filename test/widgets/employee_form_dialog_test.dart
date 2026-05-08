import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/models/sector_model.dart';
import 'package:project_granith/services/job_role_service.dart';
import 'package:project_granith/services/sector_service.dart';
import 'package:project_granith/widgets/employee/employee_form_dialog.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_team_service.dart';

class _FakeJobRoleService extends JobRoleService {
  _FakeJobRoleService(this.roles);

  final List<JobRoleModel> roles;

  @override
  Stream<List<JobRoleModel>> getJobRoles() => Stream.value(roles);
}

class _FakeSectorService extends SectorService {
  _FakeSectorService(this.sectors);

  final List<SectorModel> sectors;

  @override
  Stream<List<SectorModel>> getSectors() => Stream.value(sectors);
}

Widget _buildHarness({
  required TeamController controller,
  required JobRoleService jobRoleService,
  required SectorService sectorService,
  EmployeeModel? employee,
  bool canViewSalary = true,
}) {
  return ChangeNotifierProvider<TeamController>.value(
    value: controller,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => showDialog<void>(
                      context: context,
                      builder:
                          (_) => EmployeeFormDialog(
                            employee: employee,
                            canViewSalary: canViewSalary,
                            jobRoleService: jobRoleService,
                            sectorService: sectorService,
                          ),
                    ),
                child: const Text('Abrir formulario'),
              ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('cadastro associa funcionario ao cargo selecionado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final teamService = FakeTeamService();
    final controller = TeamController(service: teamService);
    final jobRoleService = _FakeJobRoleService([
      JobRoleModel(
        id: 'role-bricklayer',
        title: 'Pedreiro',
        sector: 'Operacional',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final sectorService = _FakeSectorService([
      SectorModel(
        id: 'sector-operational',
        name: 'Operacional',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      _buildHarness(
        controller: controller,
        jobRoleService: jobRoleService,
        sectorService: sectorService,
      ),
    );

    await tester.tap(find.text('Abrir formulario'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Joao Silva');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'joao@granith.com',
    );

    await tester.tap(find.byKey(const ValueKey('employee-job-role-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedreiro').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('employee-sector-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Operacional').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(5), '4550');
    await tester.enterText(find.byType(TextFormField).at(6), 'Ensino medio');
    await tester.tap(find.text('Cadastrar').last);
    await tester.pumpAndSettle();

    final saved = teamService.lastSavedEmployee;
    expect(saved?.jobRoleId, 'role-bricklayer');
    expect(saved?.jobTitle, 'Pedreiro');
    expect(saved?.sector, 'Operacional');
    expect(saved?.baseSalary, 4550);

    controller.dispose();
    await teamService.disposeControllers();
  });

  testWidgets('edicao sem permissao nao mostra nem altera salario', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final teamService = FakeTeamService();
    final controller = TeamController(service: teamService);
    final employee = EmployeeModel(
      id: 'employee-1',
      name: 'Maria Souza',
      email: 'maria@granith.com',
      phone: '11999999999',
      jobTitle: 'Pedreiro',
      jobRoleId: 'role-bricklayer',
      sector: 'Operacional',
      role: EmployeeRole.funcionario,
      status: EmployeeStatus.ativo,
      admissionDate: DateTime(2026, 1, 1),
      baseSalary: 8123,
      educationLevel: 'Ensino medio',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final jobRoleService = _FakeJobRoleService([
      JobRoleModel(
        id: 'role-bricklayer',
        title: 'Pedreiro',
        sector: 'Operacional',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
    final sectorService = _FakeSectorService([
      SectorModel(
        id: 'sector-operational',
        name: 'Operacional',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      _buildHarness(
        controller: controller,
        jobRoleService: jobRoleService,
        sectorService: sectorService,
        employee: employee,
        canViewSalary: false,
      ),
    );

    await tester.tap(find.text('Abrir formulario'));
    await tester.pumpAndSettle();

    expect(find.text('8123.00'), findsNothing);
    expect(find.text('Restrito por permissao'), findsOneWidget);

    await tester.tap(find.textContaining('Salvar').last);
    await tester.pumpAndSettle();

    expect(teamService.lastSavedEmployee?.baseSalary, 8123);

    controller.dispose();
    await teamService.disposeControllers();
  });
}
