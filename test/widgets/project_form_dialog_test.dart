import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/widgets/projects/project_form_dialog.dart';

import '../helpers/fake_client_account_service.dart';
import '../helpers/fake_service_projetos.dart';
import '../helpers/fake_team_service.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

EmployeeModel _employee({
  required String id,
  required String name,
  EmployeeRole role = EmployeeRole.coordenador,
}) {
  final now = DateTime(2026, 5, 5);
  return EmployeeModel(
    id: id,
    name: name,
    email: '$id@granith.com',
    phone: '',
    jobTitle: role.label,
    sector: 'obras',
    role: role,
    admissionDate: now,
    baseSalary: 0,
    educationLevel: '',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ProjectFormDialog', () {
    testWidgets('valida campos obrigatorios antes de avancar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final teamService = FakeTeamService(
        employees: [_employee(id: 'coord-1', name: 'Ana Coordenadora')],
      );
      addTearDown(teamService.disposeControllers);

      await tester.pumpWidget(
        _buildHarness(
          ProjectFormDialog(
            onSave: (_) {},
            projectService: FakeServiceProjetos(),
            clientAccountService: FakeClientAccountService(),
            teamService: teamService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('obrigat'), findsNWidgets(2));
    });

    testWidgets('cria projeto ao concluir wizard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectService = FakeServiceProjetos();
      final teamService = FakeTeamService(
        employees: [_employee(id: 'coord-1', name: 'Ana Coordenadora')],
      );
      addTearDown(teamService.disposeControllers);
      final clientService = FakeClientAccountService(
        accounts: const [
          ClientAccount(
            id: 'client-1',
            name: 'Cliente Atlas',
            ownerEmail: 'cliente@atlas.com',
            contactEmail: 'contato@atlas.com',
            contactPhone: '11999990000',
          ),
        ],
      );
      dynamic savedProject;

      await tester.pumpWidget(
        _buildHarness(
          ProjectFormDialog(
            onSave: (project) => savedProject = project,
            projectService: projectService,
            clientAccountService: clientService,
            teamService: teamService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Obra Atlas');
      await tester.enterText(find.byType(TextFormField).at(1), 'Cliente Atlas');

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Criar'));
      await tester.tap(find.textContaining('Criar'));
      await tester.pumpAndSettle();

      expect(projectService.lastAddedProject?.name, 'Obra Atlas');
      expect(projectService.lastAddedProject?.coordinatorId, 'coord-1');
      expect(savedProject?.clientAccountId, 'client-1');
    });

    testWidgets('salva coordenador responsavel selecionado', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final projectService = FakeServiceProjetos();
      final teamService = FakeTeamService(
        employees: [
          _employee(id: 'coord-1', name: 'Ana Coordenadora'),
          _employee(
            id: 'sup-1',
            name: 'Bruno Supervisor',
            role: EmployeeRole.supervisor,
          ),
        ],
      );
      addTearDown(teamService.disposeControllers);

      await tester.pumpWidget(
        _buildHarness(
          ProjectFormDialog(
            onSave: (_) {},
            projectService: projectService,
            clientAccountService: FakeClientAccountService(),
            teamService: teamService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Obra Delta');
      await tester.enterText(find.byType(TextFormField).at(1), 'Cliente Delta');

      await tester.tap(
        find.byKey(const ValueKey('project-coordinator-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Coordenadora').last);
      await tester.pumpAndSettle();
      expect(find.text('Bruno Supervisor'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('Criar'));
      await tester.tap(find.textContaining('Criar'));
      await tester.pumpAndSettle();

      expect(projectService.lastAddedProject?.coordinatorId, 'coord-1');
      expect(
        projectService.lastAddedProject?.coordinatorName,
        'Ana Coordenadora',
      );
    });
  });
}
