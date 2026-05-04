import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

class ProjectBudgetSnapshot {
  final String projectId;
  final double budgetPrevisto;
  final double totalDespesas;
  final double totalReceitas;
  final double despesasPendentes;
  final double receitasPendentes;
  final Map<TransactionCategory, double> despesasPorCategoria;
  final Map<TransactionOrigin, double> despesasPorOrigem;

  const ProjectBudgetSnapshot({
    required this.projectId,
    required this.budgetPrevisto,
    required this.totalDespesas,
    required this.totalReceitas,
    required this.despesasPendentes,
    required this.receitasPendentes,
    required this.despesasPorCategoria,
    required this.despesasPorOrigem,
  });

  double get custoRealizado => totalDespesas;
  double get saldoDisponivel => budgetPrevisto - custoRealizado;

  double get percentualConsumido {
    if (budgetPrevisto == 0) return 0;
    return (custoRealizado / budgetPrevisto * 100).clamp(0, 999);
  }

  bool get isOverBudget => custoRealizado > budgetPrevisto;
  bool get isNearLimit => percentualConsumido >= 80 && !isOverBudget;
  double get projecaoCustoTotal => custoRealizado + despesasPendentes;
  bool get projecaoOverBudget => projecaoCustoTotal > budgetPrevisto;
  double get margem => totalReceitas - totalDespesas;

  double get percentualMargem {
    if (totalReceitas == 0) return 0;
    return margem / totalReceitas * 100;
  }

  static ProjectBudgetSnapshot empty(String projectId, double budget) {
    return ProjectBudgetSnapshot(
      projectId: projectId,
      budgetPrevisto: budget,
      totalDespesas: 0,
      totalReceitas: 0,
      despesasPendentes: 0,
      receitasPendentes: 0,
      despesasPorCategoria: {},
      despesasPorOrigem: {},
    );
  }
}

class ProjectBudgetService {
  static const _transactionsTable = 'financial_transactions';
  static const _projectsTable = 'projects';

  ProjectBudgetService();

  Stream<ProjectBudgetSnapshot> watchProjectBudget({
    required String projectId,
    required double budgetPrevisto,
  }) {
    return AppSupabase.client
        .from(_transactionsTable)
        .stream(primaryKey: ['id'])
        .eq('projectId', projectId)
        .map((rows) {
          final transactions = rows.map(_transactionFromRow).toList();
          return _aggregate(
            projectId: projectId,
            budgetPrevisto: budgetPrevisto,
            transactions: transactions,
          );
        });
  }

  Future<ProjectBudgetSnapshot> getProjectBudget({
    required String projectId,
    required double budgetPrevisto,
  }) async {
    final response = await AppSupabase.client
        .from(_transactionsTable)
        .select()
        .eq('projectId', projectId);

    final transactions = (response as List).map(_transactionFromRow).toList();

    return _aggregate(
      projectId: projectId,
      budgetPrevisto: budgetPrevisto,
      transactions: transactions,
    );
  }

  Future<void> syncProjectCurrentCost(String projectId) async {
    final response = await AppSupabase.client
        .from(_transactionsTable)
        .select('amount')
        .eq('projectId', projectId)
        .eq('type', TransactionType.expense.name)
        .eq('status', TransactionStatus.paid.name);

    final totalPaid = (response as List).fold<double>(0, (sum, row) {
      final data = Map<String, dynamic>.from(row as Map);
      return sum + (data['amount'] as num? ?? 0).toDouble();
    });

    await AppSupabase.client
        .from(_projectsTable)
        .update({'currentCost': totalPaid})
        .eq('id', projectId);
  }

  Future<List<ProjectBudgetSnapshot>> getMultipleProjectBudgets(
    List<({String id, double budget})> projects,
  ) async {
    final results = <ProjectBudgetSnapshot>[];

    for (final project in projects) {
      results.add(
        await getProjectBudget(
          projectId: project.id,
          budgetPrevisto: project.budget,
        ),
      );
    }

    return results;
  }

  ProjectBudgetSnapshot _aggregate({
    required String projectId,
    required double budgetPrevisto,
    required List<FinancialTransactionModel> transactions,
  }) {
    double totalDespesas = 0;
    double totalReceitas = 0;
    double despesasPendentes = 0;
    double receitasPendentes = 0;

    final despesasPorCategoria = <TransactionCategory, double>{};
    final despesasPorOrigem = <TransactionOrigin, double>{};

    for (final t in transactions) {
      if (t.status == TransactionStatus.cancelled) continue;

      if (t.type == TransactionType.expense) {
        if (t.status == TransactionStatus.paid) {
          totalDespesas += t.amount;
          despesasPorCategoria[t.category] =
              (despesasPorCategoria[t.category] ?? 0) + t.amount;
          despesasPorOrigem[t.origin] =
              (despesasPorOrigem[t.origin] ?? 0) + t.amount;
        } else {
          despesasPendentes += t.amount;
        }
      } else if (t.type == TransactionType.income) {
        if (t.status == TransactionStatus.paid) {
          totalReceitas += t.amount;
        } else {
          receitasPendentes += t.amount;
        }
      }
    }

    return ProjectBudgetSnapshot(
      projectId: projectId,
      budgetPrevisto: budgetPrevisto,
      totalDespesas: totalDespesas,
      totalReceitas: totalReceitas,
      despesasPendentes: despesasPendentes,
      receitasPendentes: receitasPendentes,
      despesasPorCategoria: despesasPorCategoria,
      despesasPorOrigem: despesasPorOrigem,
    );
  }

  FinancialTransactionModel _transactionFromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row as Map);
    return FinancialTransactionModel.fromMap(data, data['id'] as String? ?? '');
  }
}
