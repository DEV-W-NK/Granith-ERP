import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';

class _StubProjectBudgetService extends ProjectBudgetService {
  _StubProjectBudgetService(this.snapshotByProject);

  final Map<String, ProjectBudgetSnapshot> snapshotByProject;
  final List<String> requestedProjectIds = <String>[];

  @override
  Future<ProjectBudgetSnapshot> getProjectBudget({
    required String projectId,
    required double budgetPrevisto,
  }) async {
    requestedProjectIds.add(projectId);
    return snapshotByProject[projectId] ??
        ProjectBudgetSnapshot.empty(projectId, budgetPrevisto);
  }
}

void main() {
  group('ProjectBudgetSnapshot', () {
    test('calcula custo, saldo, margem e alertas derivados', () {
      const snapshot = ProjectBudgetSnapshot(
        projectId: 'project-1',
        budgetPrevisto: 100000,
        totalDespesas: 85000,
        totalReceitas: 120000,
        despesasPendentes: 10000,
        receitasPendentes: 5000,
        despesasPorCategoria: {
          TransactionCategory.material: 60000,
          TransactionCategory.labor: 25000,
        },
        despesasPorOrigem: {
          TransactionOrigin.purchase: 60000,
          TransactionOrigin.manual: 25000,
        },
      );

      expect(snapshot.custoRealizado, 85000);
      expect(snapshot.saldoDisponivel, 15000);
      expect(snapshot.percentualConsumido, 85);
      expect(snapshot.isNearLimit, isTrue);
      expect(snapshot.isOverBudget, isFalse);
      expect(snapshot.projecaoCustoTotal, 95000);
      expect(snapshot.projecaoOverBudget, isFalse);
      expect(snapshot.margem, 35000);
      expect(snapshot.percentualMargem, closeTo(29.16, 0.01));
    });

    test('empty cria snapshot zerado para projeto sem transacoes', () {
      final snapshot = ProjectBudgetSnapshot.empty('project-1', 50000);

      expect(snapshot.projectId, 'project-1');
      expect(snapshot.budgetPrevisto, 50000);
      expect(snapshot.totalDespesas, 0);
      expect(snapshot.totalReceitas, 0);
      expect(snapshot.percentualConsumido, 0);
    });

    test('getMultipleProjectBudgets consulta cada projeto informado', () async {
      final service = _StubProjectBudgetService({
        'project-1': const ProjectBudgetSnapshot(
          projectId: 'project-1',
          budgetPrevisto: 1000,
          totalDespesas: 100,
          totalReceitas: 200,
          despesasPendentes: 0,
          receitasPendentes: 0,
          despesasPorCategoria: {},
          despesasPorOrigem: {},
        ),
        'project-2': const ProjectBudgetSnapshot(
          projectId: 'project-2',
          budgetPrevisto: 2000,
          totalDespesas: 500,
          totalReceitas: 700,
          despesasPendentes: 50,
          receitasPendentes: 10,
          despesasPorCategoria: {},
          despesasPorOrigem: {},
        ),
      });

      final snapshots = await service.getMultipleProjectBudgets([
        (id: 'project-1', budget: 1000.0),
        (id: 'project-2', budget: 2000.0),
      ]);

      expect(service.requestedProjectIds, ['project-1', 'project-2']);
      expect(snapshots, hasLength(2));
      expect(snapshots.first.projectId, 'project-1');
      expect(snapshots.last.projecaoCustoTotal, 550);
    });
  });
}
