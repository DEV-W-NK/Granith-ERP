import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/project_model.dart';

void main() {
  group('Project', () {
    test('validate retorna erros para dados invalidos', () {
      final project = Project(
        name: '',
        client: '',
        description: 'obra',
        status: ProjectStatus.planning,
        startDate: DateTime(2026, 5, 10),
        endDate: DateTime(2026, 5, 1),
        budget: -10,
        currentCost: -5,
        location: 'SP',
        tags: const [],
        teamSize: -1,
      );

      final errors = project.validate();

      expect(errors, contains('Nome do projeto e obrigatorio'));
      expect(errors, contains('Cliente e obrigatorio'));
      expect(errors, contains('Orcamento nao pode ser negativo'));
      expect(errors, contains('Custo atual nao pode ser negativo'));
      expect(errors, contains('Tamanho da equipe nao pode ser negativo'));
      expect(
        errors,
        contains('Data de termino nao pode ser anterior a data de inicio'),
      );
      expect(project.isValid, isFalse);
    });

    test('toMap inclui chaves de cliente e ignora id nao UUID', () {
      final project = Project(
        id: '123',
        name: 'Obra Centro',
        client: 'Cliente XPTO',
        description: 'Reforma completa',
        status: ProjectStatus.inProgress,
        startDate: DateTime.utc(2026, 1, 1),
        endDate: DateTime.utc(2026, 6, 1),
        budget: 1000,
        currentCost: 250,
        location: 'Sao Paulo',
        tags: const ['reforma'],
        teamSize: 4,
        clientAccountId: 'client-7',
        clientAccountName: 'Conta XPTO',
        coordinatorId: 'coord-1',
        coordinatorName: 'Ana Coordenadora',
      );

      final map = project.toMap();
      final restored = Project.fromMap('project-1', map);

      expect(map.containsKey('id'), isFalse);
      expect(map['clientAccountId'], 'client-7');
      expect(map['client_account_id'], 'client-7');
      expect(map['clientAccountName'], 'Conta XPTO');
      expect(map['client_account_name'], 'Conta XPTO');
      expect(map['coordinatorId'], 'coord-1');
      expect(map['coordinator_id'], 'coord-1');
      expect(map['coordinatorName'], 'Ana Coordenadora');
      expect(map['coordinator_name'], 'Ana Coordenadora');
      expect(map['projectKey'], 'obra centro_cliente xpto');
      expect(restored.coordinatorId, 'coord-1');
      expect(restored.coordinatorName, 'Ana Coordenadora');
    });

    test('statistics consolida totais da lista', () {
      final projects = [
        Project(
          name: 'A',
          client: 'Cliente A',
          description: '',
          status: ProjectStatus.inProgress,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 30),
          budget: 100,
          currentCost: 120,
          location: '',
          tags: const [],
          teamSize: 2,
        ),
        Project(
          name: 'B',
          client: 'Cliente B',
          description: '',
          status: ProjectStatus.planning,
          startDate: DateTime(2026, 2, 1),
          budget: 200,
          currentCost: 50,
          location: '',
          tags: const [],
          teamSize: 4,
        ),
      ];

      final stats = projects.statistics;

      expect(stats['total'], 2);
      expect(stats['totalBudget'], 300.0);
      expect(stats['totalCost'], 170.0);
      expect(stats['averageTeamSize'], 3);
      expect(stats['overBudgetCount'], 1);
      expect((stats['statusCounts'] as Map<String, int>)['inProgress'], 1);
      expect((stats['statusCounts'] as Map<String, int>)['planning'], 1);
    });

    test('progressPercentage prioriza a medicao quando existir', () {
      final project = Project(
        name: 'Obra Torre Norte',
        client: 'Cliente Atlas',
        description: 'Execucao da estrutura',
        status: ProjectStatus.inProgress,
        startDate: DateTime(2026, 1, 1),
        budget: 1000,
        currentCost: 150,
        location: 'Campinas',
        tags: const [],
        teamSize: 8,
        estimatedProgress: 42.5,
        measuredAmount: 425,
        measurementCount: 2,
      );

      expect(project.financialProgressPercentage, 15);
      expect(project.progressPercentage, 42.5);
      expect(project.formattedProgress, '42.5%');
      expect(project.hasMeasuredProgress, isTrue);
    });
  });
}
