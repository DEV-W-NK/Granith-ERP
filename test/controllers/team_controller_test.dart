import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';

import '../helpers/fake_team_service.dart';

void main() {
  group('TeamController', () {
    EmployeeModel employee(String id, String name) {
      return EmployeeModel(
        id: id,
        name: name,
        email: '$id@test.com',
        phone: '11999999999',
        jobTitle: 'Pedreiro',
        sector: 'Operacoes',
        role: EmployeeRole.funcionario,
        admissionDate: DateTime(2026, 1, 1),
        baseSalary: 2500,
        educationLevel: 'Medio',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    TeamModel team({required String id, required List<String> members}) {
      return TeamModel(
        id: id,
        name: 'Equipe $id',
        memberIds: members,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test(
      'init carrega streams e helpers filtram membros disponiveis',
      () async {
        final service = FakeTeamService(
          employees: [employee('e1', 'Ana'), employee('e2', 'Bruno')],
          teams: [
            team(id: 't1', members: ['e1']),
          ],
        );
        final controller = TeamController(service: service);

        controller.init();
        await Future<void>.delayed(Duration.zero);

        expect(controller.employees, hasLength(2));
        expect(controller.teams, hasLength(1));
        expect(
          controller.getMembersOfTeam(controller.teams.first).single.name,
          'Ana',
        );
        expect(
          controller.getAvailableEmployees(controller.teams.first).single.id,
          'e2',
        );

        await service.disposeControllers();
        controller.dispose();
      },
    );

    test(
      'save, dismiss e criar equipe delegam para o service e limpam erro',
      () async {
        final service = FakeTeamService();
        final controller = TeamController(service: service);
        final collaborator = employee('e9', 'Carlos');

        await controller.saveEmployee(collaborator);
        final created = await controller.createTeam(
          name: 'Equipe Nova',
          projectId: 'p1',
        );
        await controller.dismissEmployee('e9');

        expect(service.lastSavedEmployee?.id, 'e9');
        expect(service.lastCreatedTeam?.projectId, 'p1');
        expect(created?.id, 'team-created');
        expect(service.lastDismissedEmployeeId, 'e9');
        expect(controller.error, isNull);

        await service.disposeControllers();
        controller.dispose();
      },
    );

    test(
      'addMember e setLeader expõem erro amigavel quando service falha',
      () async {
        final service =
            FakeTeamService()..addMemberError = Exception('offline');
        final controller = TeamController(service: service);

        await controller.addMember('t1', 'e1');
        expect(controller.error, contains('Erro ao adicionar membro'));

        service.addMemberError = null;
        service.setLeaderError = Exception('denied');
        await controller.setLeader('t1', 'e1');
        expect(controller.error, contains('Erro ao definir'));

        await service.disposeControllers();
        controller.dispose();
      },
    );
  });
}
