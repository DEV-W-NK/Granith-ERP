import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/project_labor_cost_analysis_model.dart';
import 'package:project_granith/models/team_model.dart';

void main() {
  group('ProjectLaborCostCalculator', () {
    test(
      'usa apontamento aprovado do app e evita dupla contagem do diario',
      () {
        final employee = _employee(
          id: 'emp-1',
          name: 'Joao Silva',
          jobTitle: 'Pedreiro',
          salary: 2200,
        );
        final report = const ProjectLaborCostCalculator().build(
          projectId: 'project-1',
          dailyLogs: [
            _dailyLog(
              date: DateTime(2026, 5, 1),
              manpower: const {'Pedreiro': 2},
            ),
            _dailyLog(
              date: DateTime(2026, 5, 2),
              manpower: const {'Pedreiro': 1},
            ),
          ],
          mobileEntries: [
            ProjectLaborWorkHourEntry(
              id: 'entry-1',
              projectId: 'project-1',
              employeeId: 'emp-1',
              employeeName: 'Joao Silva',
              startAt: DateTime(2026, 5, 1, 8),
              endAt: DateTime(2026, 5, 1, 9),
              durationMinutes: 60,
              status: 'approved',
              reason: 'Apontamento de campo',
              source: 'mobile',
            ),
          ],
          employees: [employee],
          teams: [
            _team(memberIds: const ['emp-1']),
          ],
        );

        expect(report.approvedMobileCost, 10);
        expect(report.dailyEstimateRawCost, 240);
        expect(report.dailyEstimateUsedCost, 80);
        expect(report.consolidatedCost, 90);
        expect(report.approvedMobileHours, 1);
        expect(report.roleCosts.single.totalCost, 90);
      },
    );

    test('mantem apontamentos pendentes separados do custo consolidado', () {
      final employee = _employee(
        id: 'emp-1',
        name: 'Maria Souza',
        jobTitle: 'Servente',
        salary: 2200,
      );
      final report = const ProjectLaborCostCalculator().build(
        projectId: 'project-1',
        dailyLogs: [
          _dailyLog(date: DateTime(2026, 5, 1), manpower: const {'Equipe': 1}),
        ],
        mobileEntries: [
          ProjectLaborWorkHourEntry(
            id: 'entry-1',
            projectId: 'project-1',
            employeeId: 'emp-1',
            employeeName: 'Maria Souza',
            startAt: DateTime(2026, 5, 1, 8),
            endAt: DateTime(2026, 5, 1, 10),
            durationMinutes: 120,
            status: 'pending',
            reason: 'Aguardando aprovacao',
            source: 'mobile',
          ),
        ],
        employees: [employee],
        teams: [
          _team(memberIds: const ['emp-1']),
        ],
      );

      expect(report.pendingMobileCost, 20);
      expect(report.pendingMobileHours, 2);
      expect(report.dailyEstimateRawCost, 80);
      expect(report.dailyEstimateUsedCost, 0);
      expect(report.consolidatedCost, 0);
    });
  });
}

DailyLogModel _dailyLog({
  required DateTime date,
  required Map<String, int> manpower,
}) {
  return DailyLogModel(
    id: 'log-${date.day}',
    projectId: 'project-1',
    projectName: 'Obra Alfa',
    date: date,
    manpower: manpower,
    activitiesDescription: 'Atividade em campo',
    createdByUserId: 'user-1',
  );
}

EmployeeModel _employee({
  required String id,
  required String name,
  required String jobTitle,
  required double salary,
}) {
  final now = DateTime(2026, 5, 1);
  return EmployeeModel(
    id: id,
    name: name,
    email: '',
    phone: '',
    jobTitle: jobTitle,
    sector: 'Obra',
    role: EmployeeRole.funcionario,
    admissionDate: now,
    baseSalary: salary,
    educationLevel: '',
    createdAt: now,
    updatedAt: now,
  );
}

TeamModel _team({required List<String> memberIds}) {
  final now = DateTime(2026, 5, 1);
  return TeamModel(
    id: 'team-1',
    name: 'Equipe Alfa',
    memberIds: memberIds,
    projectId: 'project-1',
    createdAt: now,
    updatedAt: now,
  );
}
