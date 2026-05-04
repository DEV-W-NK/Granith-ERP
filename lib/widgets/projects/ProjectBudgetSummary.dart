import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/ProjectBudgetService.dart';
import 'package:project_granith/themes/app_theme.dart';

/// Widget que exibe o resumo financeiro de um projeto:
/// orçamento previsto vs custo realizado, com barra de progresso
/// e breakdown por categoria.
///
/// Uso simples (em qualquer tela que tenha um Project):
///   ProjectBudgetSummary(project: project)
///
/// Uso expandido (com breakdown):
///   ProjectBudgetSummary(project: project, showBreakdown: true)
class ProjectBudgetSummary extends StatelessWidget {
  final Project project;
  final bool showBreakdown;
  final bool compact;
  final ProjectBudgetService? budgetService;

  const ProjectBudgetSummary({
    super.key,
    required this.project,
    this.showBreakdown = false,
    this.compact = false,
    this.budgetService,
  });

  @override
  Widget build(BuildContext context) {
    if (project.id.isEmpty) return const SizedBox.shrink();

    final service = budgetService ?? ProjectBudgetService();

    return StreamBuilder<ProjectBudgetSnapshot>(
      stream: service.watchProjectBudget(
        projectId: project.id,
        budgetPrevisto: project.budget,
      ),
      builder: (context, snap) {
        final snapshot =
            snap.data ??
            ProjectBudgetSnapshot.empty(project.id, project.budget);

        if (compact) return _CompactView(snapshot: snapshot);

        return _FullView(snapshot: snapshot, showBreakdown: showBreakdown);
      },
    );
  }
}

// ─── Visão compacta (para usar dentro de cards de projeto) ────────────────────

class _CompactView extends StatelessWidget {
  final ProjectBudgetSnapshot snapshot;

  const _CompactView({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final pct = snapshot.percentualConsumido.clamp(0.0, 100.0) / 100;
    final barColor =
        snapshot.isOverBudget
            ? Colors.redAccent
            : snapshot.isNearLimit
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${snapshot.percentualConsumido.toStringAsFixed(1)}% do orçamento',
              style: TextStyle(
                color: barColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${currency.format(snapshot.custoRealizado)} / ${currency.format(snapshot.budgetPrevisto)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 5,
          ),
        ),
        if (snapshot.isOverBudget) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 11,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 3),
              Text(
                'Orçamento estourado em ${currency.format(snapshot.custoRealizado - snapshot.budgetPrevisto)}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 10),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Visão completa (para usar em tela de detalhes do projeto) ────────────────

class _FullView extends StatelessWidget {
  final ProjectBudgetSnapshot snapshot;
  final bool showBreakdown;

  const _FullView({required this.snapshot, required this.showBreakdown});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final pct = snapshot.percentualConsumido.clamp(0.0, 100.0) / 100;
    final barColor =
        snapshot.isOverBudget
            ? Colors.redAccent
            : snapshot.isNearLimit
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              snapshot.isOverBudget
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + badge de alerta
          Row(
            children: [
              const Text(
                'Budget vs Realizado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (snapshot.isOverBudget)
                _Badge('Estourado', Colors.redAccent)
              else if (snapshot.isNearLimit)
                _Badge('Atenção', Colors.orangeAccent)
              else if (snapshot.percentualConsumido > 0)
                _Badge(
                  '${snapshot.percentualConsumido.toStringAsFixed(0)}%',
                  Colors.greenAccent,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 8,
            ),
          ),

          // Projeção (se tiver pendentes)
          if (snapshot.despesasPendentes > 0) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (snapshot.projecaoCustoTotal / snapshot.budgetPrevisto)
                    .clamp(0.0, 1.0),
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orangeAccent.withOpacity(0.4),
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Projeção com pendentes: ${currency.format(snapshot.projecaoCustoTotal)}',
              style: TextStyle(
                color: Colors.orangeAccent.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Métricas em grid
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Orçamento',
                  value: currency.format(snapshot.budgetPrevisto),
                  color: AppColors.textMuted,
                  icon: Icons.account_balance_outlined,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Realizado',
                  value: currency.format(snapshot.custoRealizado),
                  color: barColor,
                  icon: Icons.payments_outlined,
                ),
              ),
              Expanded(
                child: _Metric(
                  label:
                      snapshot.saldoDisponivel >= 0
                          ? 'Disponível'
                          : 'Excedente',
                  value: currency.format(snapshot.saldoDisponivel.abs()),
                  color:
                      snapshot.saldoDisponivel >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  icon:
                      snapshot.saldoDisponivel >= 0
                          ? Icons.savings_outlined
                          : Icons.trending_up,
                ),
              ),
            ],
          ),

          // Receitas
          if (snapshot.totalReceitas > 0) ...[
            const SizedBox(height: 10),
            const Divider(color: Colors.white10),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Receitas',
                    value: currency.format(snapshot.totalReceitas),
                    color: Colors.greenAccent,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Margem',
                    value: '${snapshot.percentualMargem.toStringAsFixed(1)}%',
                    color:
                        snapshot.margem >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                    icon: Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'A receber',
                    value: currency.format(snapshot.receitasPendentes),
                    color: Colors.lightGreenAccent,
                    icon: Icons.hourglass_bottom_outlined,
                  ),
                ),
              ],
            ),
          ],

          // Breakdown por categoria
          if (showBreakdown && snapshot.despesasPorCategoria.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            const Text(
              'Despesas por categoria',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...(() {
              final entries =
                  snapshot.despesasPorCategoria.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
              return entries
                  .take(5)
                  .map(
                    (entry) => _CategoryRow(
                      category: entry.key,
                      amount: entry.value,
                      total: snapshot.custoRealizado,
                      currency: currency,
                    ),
                  );
            })(),
          ],
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final TransactionCategory category;
  final double amount;
  final double total;
  final NumberFormat currency;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              _label(category),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.toDouble(),
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentGold,
                ),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currency.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _label(TransactionCategory c) => switch (c) {
    TransactionCategory.material => 'Material',
    TransactionCategory.labor => 'M. de obra',
    TransactionCategory.equipment => 'Equipamento',
    TransactionCategory.administrative => 'Adm.',
    TransactionCategory.measurement => 'Medição',
    TransactionCategory.tax => 'Imposto',
    TransactionCategory.other => 'Outro',
  };
}
