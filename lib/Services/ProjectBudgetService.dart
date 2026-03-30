import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

/// Dados financeiros calculados de um projeto específico.
/// Resultado da agregação das financial_transactions pelo projectId.
class ProjectBudgetSnapshot {
  final String projectId;
  final double budgetPrevisto;     // project.budget (orçamento inicial)
  final double totalDespesas;      // soma das despesas pagas
  final double totalReceitas;      // soma das receitas recebidas
  final double despesasPendentes;  // despesas ainda não pagas
  final double receitasPendentes;  // receitas ainda não recebidas

  // Breakdown por categoria de despesa
  final Map<TransactionCategory, double> despesasPorCategoria;

  // Breakdown por origem de despesa
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

  // ─── Computed ───────────────────────────────────────────────────────────────

  /// Custo realizado = despesas efetivamente pagas.
  double get custoRealizado => totalDespesas;

  /// Saldo disponível = orçamento - custo realizado.
  double get saldoDisponivel => budgetPrevisto - custoRealizado;

  /// Percentual consumido do orçamento (0–100+).
  double get percentualConsumido {
    if (budgetPrevisto == 0) return 0;
    return (custoRealizado / budgetPrevisto * 100).clamp(0, 999);
  }

  /// True se o custo realizado já ultrapassou o orçamento.
  bool get isOverBudget => custoRealizado > budgetPrevisto;

  /// True se está acima de 80% do orçamento (alerta amarelo).
  bool get isNearLimit => percentualConsumido >= 80 && !isOverBudget;

  /// Projeção de custo total considerando despesas pendentes.
  double get projecaoCustoTotal => custoRealizado + despesasPendentes;

  /// True se a projeção já ultrapassa o orçamento.
  bool get projecaoOverBudget => projecaoCustoTotal > budgetPrevisto;

  /// Margem = receitas - despesas (resultado financeiro do projeto).
  double get margem => totalReceitas - totalDespesas;

  /// Percentual de margem sobre receita.
  double get percentualMargem {
    if (totalReceitas == 0) return 0;
    return (margem / totalReceitas * 100);
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

/// Service responsável por agregar dados financeiros por projeto.
class ProjectBudgetService {
  final FirebaseFirestore _firestore;

  ProjectBudgetService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col =>
      _firestore.collection('financial_transactions');

  // ─── Stream reativo ──────────────────────────────────────────────────────────

  /// Stream que recalcula o snapshot sempre que uma transação do projeto muda.
  Stream<ProjectBudgetSnapshot> watchProjectBudget({
    required String projectId,
    required double budgetPrevisto,
  }) {
    return _col
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snap) {
      final transactions = snap.docs
          .map((d) => FinancialTransactionModel.fromMap(
              d.data() as Map<String, dynamic>, d.id))
          .toList();

      return _aggregate(
        projectId: projectId,
        budgetPrevisto: budgetPrevisto,
        transactions: transactions,
      );
    });
  }

  // ─── Consulta pontual ────────────────────────────────────────────────────────

  Future<ProjectBudgetSnapshot> getProjectBudget({
    required String projectId,
    required double budgetPrevisto,
  }) async {
    final snap = await _col
        .where('projectId', isEqualTo: projectId)
        .get();

    final transactions = snap.docs
        .map((d) => FinancialTransactionModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList();

    return _aggregate(
      projectId: projectId,
      budgetPrevisto: budgetPrevisto,
      transactions: transactions,
    );
  }

  /// Atualiza o campo `currentCost` do projeto no Firestore
  /// com o custo realizado calculado pelas transações.
  /// Chamado após cada nova transação de despesa vinculada ao projeto.
  Future<void> syncProjectCurrentCost(String projectId) async {
    final snap = await _col
        .where('projectId', isEqualTo: projectId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('status', isEqualTo: TransactionStatus.paid.name)
        .get();

    final totalPago = snap.docs.fold<double>(
        0, (sum, d) => sum + ((d.data() as Map)['amount'] ?? 0.0));

    await _firestore
        .collection('projects')
        .doc(projectId)
        .update({'currentCost': totalPago});
  }

  // ─── Múltiplos projetos (para dashboard) ─────────────────────────────────────

  /// Retorna snapshots de todos os projetos passados.
  /// Útil para o dashboard e relatórios.
  Future<List<ProjectBudgetSnapshot>> getMultipleProjectBudgets(
    List<({String id, double budget})> projects,
  ) async {
    final results = <ProjectBudgetSnapshot>[];

    for (final project in projects) {
      final snapshot = await getProjectBudget(
        projectId: project.id,
        budgetPrevisto: project.budget,
      );
      results.add(snapshot);
    }

    return results;
  }

  // ─── Agregação interna ───────────────────────────────────────────────────────

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
}