import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:project_granith/constants/GranitTokens.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/widgets/components/GranitCard.dart';
import 'package:project_granith/widgets/components/GranitSectionHeader.dart';


// =============================================================================
// HOME PAGE WIDGETS
// Cada widget é um card independente, stateless, alimentado pelo HomeController.
// Arquivo único para facilitar importação; separe em arquivos individuais
// quando a pasta home_page/ crescer além de 5 widgets.
//
// Widgets exportados:
//   - ProjectsCard
//   - AlertsCard
//   - MiniChartCard
//   - TeamCard
//   - QuickActionsCard
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// PROJECTS CARD — barras de progresso reativas por projeto
// ─────────────────────────────────────────────────────────────────────────────

class ProjectsCard extends StatelessWidget {
  final List<ProjectProgress> projects;

  const ProjectsCard({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GranitCardTitle('Projetos em andamento'),
          if (projects.isEmpty)
            _empty('Nenhum projeto ativo no momento')
          else
            ...projects.map((p) => _ProjectRow(project: p)),
        ],
      ),
    );
  }

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(msg, style: GranitTokens.bodySmall),
        ),
      );
}

class _ProjectRow extends StatelessWidget {
  final ProjectProgress project;

  const _ProjectRow({required this.project});

  Color get _barColor {
    if (project.isOverBudget) return GranitTokens.red;
    if (project.progressPct > 0.85) return GranitTokens.orange;
    if (project.progressPct > 0.6)  return GranitTokens.gold;
    return GranitTokens.green;
  }

  @override
  Widget build(BuildContext context) {
    final pct  = project.progressPct.clamp(0.0, 1.0);
    final pctLabel = '${(project.progressPct * 100).toStringAsFixed(0)}%';
    final color = _barColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: GranitTokens.textPrimary,
                    fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GranitBadge(
                label: project.isOverBudget ? '⚠ $pctLabel' : pctLabel,
                color: color,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (project.dueDateLabel.isNotEmpty) project.dueDateLabel,
              if (project.budget > 0) GranitTokens.brlCompact(project.budget) + ' orçado',
            ].join(' · '),
            style: GranitTokens.bodySmall.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: GranitTokens.surface3,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALERTS CARD — notificações automáticas geradas pelo HomeController
// ─────────────────────────────────────────────────────────────────────────────

class AlertsCard extends StatelessWidget {
  final List<HomeAlert> alerts;

  const AlertsCard({super.key, required this.alerts});

  Color _color(HomeAlertType t) => switch (t) {
        HomeAlertType.critical => GranitTokens.red,
        HomeAlertType.warning  => GranitTokens.orange,
        HomeAlertType.info     => GranitTokens.blue,
        HomeAlertType.hint     => GranitTokens.purple,
      };

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GranitCardTitle('Alertas'),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: GranitTokens.green, size: 16),
                const SizedBox(width: 8),
                Text('Tudo em ordem por aqui.',
                    style: GranitTokens.bodySmall.copyWith(color: GranitTokens.green)),
              ]),
            )
          else
            ...alerts.map((a) => _AlertRow(alert: a, color: _color(a.type))),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final HomeAlert alert;
  final Color color;

  const _AlertRow({required this.alert, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7, height: 7,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message,
                    style: GranitTokens.bodySmall.copyWith(
                      color: GranitTokens.textSecondary,
                    )),
                const SizedBox(height: 2),
                Text(alert.subtitle,
                    style: GranitTokens.bodySmall.copyWith(
                      color: GranitTokens.textMuted, fontSize: 10,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI CHART CARD — bar chart de receita vs despesa (últimos 6 meses)
// ─────────────────────────────────────────────────────────────────────────────

class MiniChartCard extends StatefulWidget {
  final List<MonthlyMini> data;

  const MiniChartCard({super.key, required this.data});

  @override
  State<MiniChartCard> createState() => _MiniChartCardState();
}

class _MiniChartCardState extends State<MiniChartCard> {
  int _touched = -1;

  double get _maxY {
    if (widget.data.isEmpty) return 100;
    final vals = widget.data.expand((d) => [d.income, d.expense]);
    return vals.reduce((a, b) => a > b ? a : b) * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GranitCardTitle('Receita últimos 6 meses'),
          Row(children: [
            _dot(GranitTokens.green, 'Receita'),
            const SizedBox(width: 12),
            _dot(GranitTokens.red, 'Despesa'),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: widget.data.isEmpty
                ? Center(child: Text('Sem dados', style: GranitTokens.bodySmall))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        touchCallback: (evt, resp) => setState(() {
                          _touched = resp?.spot?.touchedBarGroupIndex ?? -1;
                        }),
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => GranitTokens.surface3,
                          getTooltipItem: (grp, _, rod, ri) {
                            final d      = widget.data[grp.x];
                            final labels = ['Receita', 'Despesa'];
                            final vals   = [d.income, d.expense];
                            return BarTooltipItem(
                              '${d.label}\n${labels[ri]}: ${GranitTokens.brlCompact(vals[ri])}',
                              const TextStyle(
                                  color: GranitTokens.textPrimary, fontSize: 10, height: 1.5),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true, reservedSize: 20,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= widget.data.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(widget.data[i].label,
                                    style: const TextStyle(
                                        color: GranitTokens.textMuted, fontSize: 9)),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true, drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: Color(0x0AFFFFFF), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(widget.data.length, (i) {
                        final d = widget.data[i];
                        final touched = i == _touched;
                        return BarChartGroupData(x: i, barRods: [
                          _rod(d.income, GranitTokens.green, touched),
                          _rod(d.expense, GranitTokens.red, touched),
                        ]);
                      }),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 300),
                  ),
          ),
        ],
      ),
    );
  }

  BarChartRodData _rod(double y, Color color, bool touched) => BarChartRodData(
        toY: y.clamp(0, double.infinity),
        color: color.withOpacity(touched ? 1.0 : 0.65),
        width: 7,
        borderRadius: BorderRadius.circular(3),
        backDrawRodData: BackgroundBarChartRodData(
          show: true, toY: _maxY, color: color.withOpacity(0.04),
        ),
      );

  Widget _dot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 5),
          Text(label, style: GranitTokens.bodySmall),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAM CARD — snapshot de RH para o dashboard
// ─────────────────────────────────────────────────────────────────────────────

class TeamCard extends StatelessWidget {
  final int activeEmployees;
  final int fieldToday;
  final int pendingDailyLogs;
  final int talentsPending;

  const TeamCard({
    super.key,
    required this.activeEmployees,
    required this.fieldToday,
    required this.pendingDailyLogs,
    required this.talentsPending,
  });

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GranitCardTitle('Equipe'),
          _row('Funcionários ativos', activeEmployees.toString(), GranitTokens.textPrimary),
          _row('Em campo hoje', fieldToday.toString(), GranitTokens.green),
          _row('Diários pendentes', pendingDailyLogs.toString(), GranitTokens.orange),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: GranitTokens.border, height: 1),
          ),
          _row('Talentos em triagem', talentsPending.toString(), GranitTokens.blue),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GranitTokens.bodySmall),
            Text(value,
                style: TextStyle(
                  color: valueColor, fontSize: 13, fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS CARD — atalhos de navegação
// ─────────────────────────────────────────────────────────────────────────────

class QuickActionItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class QuickActionsCard extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActionsCard({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GranitCardTitle('Ações rápidas'),
          ...actions.map((a) => _ActionRow(item: a)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final QuickActionItem item;

  const _ActionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: GranitTokens.surface2,
      customBorder: Border.all(color: GranitTokens.border2),
      borderRadius: GranitTokens.btnRadius,
      onTap: item.onTap,
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.color, size: 15),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.label,
                style: const TextStyle(
                  color: GranitTokens.textPrimary,
                  fontSize: 12, fontWeight: FontWeight.w500,
                )),
            Text(item.subtitle, style: GranitTokens.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios_rounded,
            color: GranitTokens.textMuted, size: 11),
      ]),
    );
  }
}