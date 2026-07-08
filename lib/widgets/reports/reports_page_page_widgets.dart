import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/models/reports_chart_models.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class ReportsPageView extends StatefulWidget {
  const ReportsPageView({super.key});

  @override
  State<ReportsPageView> createState() => _ReportsPageViewState();
}

class _ReportsPageViewState extends State<ReportsPageView> {
  bool _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) return;
    _requestedInitialLoad = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<ReportsController>();
      if (controller.periodFrom == null && controller.periodTo == null) {
        controller.setCurrentYear();
      }
      controller.loadDreReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsController>(
      builder: (context, controller, _) {
        final width = MediaQuery.sizeOf(context).width;
        final padding = ResponsiveLayout.pagePadding(width);
        final gap = ResponsiveLayout.gap(width);
        final report = controller.dreReport;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (controller.isLoading && report == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.accentGold,
                  backgroundColor: AppColors.surfaceDark,
                  onRefresh: controller.loadDreReport,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          controller: controller,
                          report: report,
                          onReload: controller.loadDreReport,
                        ),
                        const SizedBox(height: 18),
                        if (controller.error != null)
                          _ErrorBanner(
                            message: controller.error!,
                            compact: false,
                          ),
                        if (report == null) ...[
                          const SizedBox(height: 80),
                          const Center(
                            child: Text(
                              'Carregando DRE gerencial...',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else ...[
                          _ExecutiveSignal(report: report, compact: false),
                          const SizedBox(height: 16),
                          _KpiGrid(report: report, compact: false),
                          SizedBox(height: gap),
                          _DreWorkspace(report: report, gap: gap),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DreWorkspace extends StatelessWidget {
  final DreExecutiveReport report;
  final double gap;

  const _DreWorkspace({required this.report, required this.gap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1220;
        final medium = constraints.maxWidth >= 900;

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 13,
                child: Column(
                  children: [
                    _DreTable(report: report, compact: false),
                    SizedBox(height: gap),
                    _CashRiskPanel(report: report, compact: false),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 8,
                child: Column(
                  children: [
                    _InsightPanel(report: report, compact: false),
                    SizedBox(height: gap),
                    _ExpenseBreakdown(report: report, compact: false),
                    SizedBox(height: gap),
                    _CompanyContextPanel(report: report, compact: false),
                  ],
                ),
              ),
            ],
          );
        }

        if (medium) {
          return Column(
            children: [
              _DreTable(report: report, compact: false),
              SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InsightPanel(report: report, compact: false),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _ExpenseBreakdown(report: report, compact: false),
                  ),
                ],
              ),
              SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CompanyContextPanel(report: report, compact: false),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _CashRiskPanel(report: report, compact: false),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            _DreTable(report: report, compact: false),
            SizedBox(height: gap),
            _InsightPanel(report: report, compact: false),
            SizedBox(height: gap),
            _ExpenseBreakdown(report: report, compact: false),
            SizedBox(height: gap),
            _CompanyContextPanel(report: report, compact: false),
            SizedBox(height: gap),
            _CashRiskPanel(report: report, compact: false),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ReportsController controller;
  final DreExecutiveReport? report;
  final Future<void> Function() onReload;

  const _Header({
    required this.controller,
    required this.report,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DRE Gerencial',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              report?.periodLabel ??
                  'Receitas, custos, materiais e operacao da empresa',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (report != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderSnapshotChip(
                    icon: Icons.payments_rounded,
                    label: 'Receita liquida',
                    value: _formatCurrency(report!.netRevenue),
                    color: AppColors.accentBlue,
                  ),
                  _HeaderSnapshotChip(
                    icon:
                        report!.operatingResult >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                    label: 'Resultado',
                    value: _formatCurrency(report!.operatingResult),
                    color:
                        report!.operatingResult >= 0
                            ? AppColors.accentGreen
                            : AppColors.accentRed,
                  ),
                  _HeaderSnapshotChip(
                    icon: Icons.percent_rounded,
                    label: 'Margem',
                    value: _formatPercent(report!.operatingMargin),
                    color:
                        report!.operatingMargin >= 0.12
                            ? AppColors.accentGreen
                            : AppColors.orange,
                  ),
                ],
              ),
            ],
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PeriodButton(
              label: 'Mes',
              icon: Icons.calendar_view_month_rounded,
              selected: _controllerPeriodIsCurrentMonth(controller),
              onPressed: () {
                controller.setCurrentMonth();
                controller.loadDreReport();
              },
            ),
            _PeriodButton(
              label: 'Ano',
              icon: Icons.date_range_rounded,
              selected: _controllerPeriodIsCurrentYear(controller),
              onPressed: () {
                controller.setCurrentYear();
                controller.loadDreReport();
              },
            ),
            _PeriodButton(
              label: 'Historico',
              icon: Icons.all_inclusive_rounded,
              selected:
                  controller.periodFrom == null && controller.periodTo == null,
              onPressed: () {
                controller.clearPeriod();
                controller.loadDreReport();
              },
            ),
            IconButton.filledTonal(
              tooltip: 'Atualizar DRE',
              onPressed: onReload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}

bool _controllerPeriodIsCurrentMonth(ReportsController controller) {
  final now = DateTime.now();
  return controller.periodFrom?.year == now.year &&
      controller.periodFrom?.month == now.month &&
      controller.periodTo?.year == now.year &&
      controller.periodTo?.month == now.month;
}

bool _controllerPeriodIsCurrentYear(ReportsController controller) {
  final now = DateTime.now();
  return controller.periodFrom?.year == now.year &&
      controller.periodFrom?.month == 1 &&
      controller.periodTo?.year == now.year &&
      controller.periodTo?.month == 12;
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _PeriodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        selected
            ? FilledButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            )
            : OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.72),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16), const SizedBox(width: 7), Text(label)],
    );

    return selected
        ? FilledButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class _HeaderSnapshotChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeaderSnapshotChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExecutiveSignal extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _ExecutiveSignal({required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final signal = _signalFor(report);
    final mainInsight =
        report.executiveInsights.isNotEmpty
            ? report.executiveInsights.first
            : 'DRE carregado. Mantenha os lancamentos por origem e projeto.';
    final situationLine =
        'Resultado ${_formatCurrency(report.operatingResult)} | Margem ${_formatPercent(report.operatingMargin)} | ${report.pendingIncome >= report.pendingExpense ? 'caixa coberto' : 'caixa pressionado'}';
    final cashCoverageText =
        report.pendingExpense <= 0
            ? 'Sem pressao'
            : _formatPercent(report.cashCoverage);
    final cashCoverageColor =
        report.pendingExpense <= 0 ||
                report.pendingIncome >= report.pendingExpense
            ? AppColors.accentGreen
            : AppColors.accentRed;

    return _Panel(
      accent: signal.color,
      padding: EdgeInsets.all(compact ? 11 : 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < (compact ? 540 : 700);
          final signalTile = Container(
            width: compact ? 42 : 52,
            height: compact ? 42 : 52,
            decoration: BoxDecoration(
              color: signal.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: signal.color.withValues(alpha: 0.36)),
            ),
            child: Icon(
              signal.icon,
              color: signal.color,
              size: compact ? 22 : 26,
            ),
          );
          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    signal.label,
                    style: TextStyle(
                      color: signal.color,
                      fontSize: compact ? 15.5 : 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _MiniPill(
                    label:
                        'Margem operacional ${_formatPercent(report.operatingMargin)}',
                    color: signal.color,
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 7),
              Text(
                situationLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: compact ? 12.4 : 14,
                  height: 1.24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: compact ? 3 : 6),
              Text(
                mainInsight,
                maxLines: compact ? 2 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: compact ? 12.4 : 14,
                  height: compact ? 1.28 : 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SignalStat(
                label: 'Lucro bruto',
                value: _formatPercent(report.grossMargin),
                color:
                    report.grossMargin >= 0.22
                        ? AppColors.accentGreen
                        : AppColors.orange,
                compact: compact,
              ),
              _SignalStat(
                label: 'Custos diretos',
                value: _formatPercent(report.directCostRatio),
                color: AppColors.accentGold,
                compact: compact,
              ),
              _SignalStat(
                label: 'Caixa',
                value: cashCoverageText,
                color: cashCoverageColor,
                compact: compact,
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    signalTile,
                    SizedBox(width: compact ? 12 : 14),
                    Expanded(child: headline),
                  ],
                ),
                SizedBox(height: compact ? 8 : 12),
                stats,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              signalTile,
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headline,
                    SizedBox(height: compact ? 8 : 12),
                    stats,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  _Signal _signalFor(DreExecutiveReport report) {
    if (!report.hasData) {
      return const _Signal(
        label: 'Sem base financeira suficiente',
        icon: Icons.info_outline_rounded,
        color: AppColors.textMuted,
      );
    }
    if (report.operatingResult < 0 || report.overdueExpense > 0) {
      return const _Signal(
        label: 'Atencao executiva',
        icon: Icons.warning_amber_rounded,
        color: AppColors.accentRed,
      );
    }
    if (report.operatingMargin < 0.12 ||
        report.pendingExpense > report.pendingIncome) {
      return const _Signal(
        label: 'Margem sob pressao',
        icon: Icons.trending_down_rounded,
        color: AppColors.orange,
      );
    }
    return const _Signal(
      label: 'Operacao saudavel',
      icon: Icons.trending_up_rounded,
      color: AppColors.green,
    );
  }
}

class _SignalStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _SignalStat({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 100 : 122),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: compact ? 10.2 : 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 12 : 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Signal {
  final String label;
  final IconData icon;
  final Color color;

  const _Signal({required this.label, required this.icon, required this.color});
}

class _KpiGrid extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _KpiGrid({required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            compact
                ? 4
                : constraints.maxWidth >= 1180
                ? 4
                : constraints.maxWidth >= 720
                ? 2
                : 1;
        final spacing = compact ? 10.0 : 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _MetricCard(
              width: width,
              title: 'Resultado operacional',
              value: report.operatingResult,
              detail: 'Depois de custos diretos e OPEX',
              icon: Icons.query_stats_rounded,
              compact: compact,
              color:
                  report.operatingResult >= 0
                      ? AppColors.accentGreen
                      : AppColors.accentRed,
            ),
            _MetricCard(
              width: width,
              title: 'Receita liquida',
              value: report.netRevenue,
              detail: 'Receita paga menos impostos',
              icon: Icons.payments_rounded,
              compact: compact,
              color: AppColors.accentBlue,
            ),
            _MetricCard(
              width: width,
              title: 'Materiais',
              value: report.materialCosts,
              detail:
                  '${_formatPercent(report.materialRatio)} da receita liquida',
              icon: Icons.inventory_2_rounded,
              compact: compact,
              color: AppColors.accentGold,
            ),
            _MetricCard(
              width: width,
              title: 'Despesas operacionais',
              value: report.operationalExpenses,
              detail:
                  '${_formatPercent(report.operationalExpenseRatio)} da receita liquida',
              icon: Icons.domain_rounded,
              compact: compact,
              color: AppColors.purple,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final String title;
  final double value;
  final String detail;
  final IconData icon;
  final Color color;
  final bool compact;

  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _Panel(
        accent: color,
        minHeight: compact ? 0 : 132,
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 28 : 34,
                  height: compact ? 28 : 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: compact ? 16 : 18),
                ),
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: compact ? 12.6 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 7 : 18),
            Text(
              _formatCurrency(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: compact ? 19.2 : 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: compact ? 3 : 5),
            Text(
              detail,
              maxLines: compact ? 2 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: compact ? 11.5 : 12,
                height: 1.26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DreTable extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _DreTable({required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final rows = report.lines
        .map((line) => _DreLineRow(line: line, compact: compact))
        .toList(growable: false);

    return _Panel(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.receipt_long_rounded,
            title: 'Demonstrativo de resultado',
            subtitle:
                'Base paga e classificada por origem, categoria e projeto',
            compact: compact,
          ),
          SizedBox(height: compact ? 9 : 14),
          _MarginBridge(report: report, compact: compact),
          SizedBox(height: compact ? 9 : 14),
          _DreColumnHeader(compact: compact),
          if (compact)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                child: SingleChildScrollView(child: Column(children: rows)),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              child: Column(children: rows),
            ),
        ],
      ),
    );
  }
}

class _MarginBridge extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _MarginBridge({required this.report, required this.compact});

  @override
  Widget build(BuildContext context) {
    final grossBase =
        report.grossRevenue.abs() < 0.01
            ? report.netRevenue.abs()
            : report.grossRevenue.abs();
    final netBase =
        report.netRevenue.abs() < 0.01 ? grossBase : report.netRevenue.abs();
    final resultColor =
        report.operatingResult >= 0
            ? AppColors.accentGreen
            : AppColors.accentRed;
    final steps = [
      _BridgeStep(
        label: 'Bruta',
        value: report.grossRevenue,
        ratio: _safeRatio(report.grossRevenue, grossBase),
        color: AppColors.accentBlue,
        icon: Icons.south_west_rounded,
      ),
      _BridgeStep(
        label: 'Impostos',
        value: -report.taxDeductions,
        ratio: _safeRatio(report.taxDeductions, grossBase),
        color: AppColors.orange,
        icon: Icons.remove_circle_outline_rounded,
      ),
      _BridgeStep(
        label: 'Liquida',
        value: report.netRevenue,
        ratio: _safeRatio(report.netRevenue, grossBase),
        color: AppColors.auraBlue,
        icon: Icons.check_circle_outline_rounded,
      ),
      _BridgeStep(
        label: 'Custos',
        value: -report.directCosts,
        ratio: _safeRatio(report.directCosts, netBase),
        color: AppColors.accentGold,
        icon: Icons.foundation_rounded,
      ),
      _BridgeStep(
        label: 'Lucro bruto',
        value: report.grossProfit,
        ratio: _safeRatio(report.grossProfit, netBase),
        color:
            report.grossProfit >= 0 ? AppColors.accentGreen : AppColors.orange,
        icon: Icons.stacked_line_chart_rounded,
      ),
      _BridgeStep(
        label: 'OPEX',
        value: -report.operationalExpenses,
        ratio: _safeRatio(report.operationalExpenses, netBase),
        color: AppColors.purple,
        icon: Icons.domain_rounded,
      ),
      _BridgeStep(
        label: 'Resultado',
        value: report.operatingResult,
        ratio: _safeRatio(report.operatingResult, netBase),
        color: resultColor,
        icon:
            report.operatingResult >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 9 : 12),
      decoration: AppDecorations.cardInnerSurface(
        accent: resultColor,
        radius: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                color: resultColor,
                size: compact ? 15 : 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Ponte de margem',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 12.2 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'base receita liquida',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: compact ? 10.2 : 10.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  compact
                      ? constraints.maxWidth >= 620
                          ? 4
                          : 2
                      : constraints.maxWidth >= 860
                      ? 4
                      : 2;
              final spacing = compact ? 7.0 : 9.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children:
                    steps
                        .map(
                          (step) => _BridgeNode(
                            step: step,
                            width: itemWidth,
                            compact: compact,
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BridgeStep {
  final String label;
  final double value;
  final double ratio;
  final Color color;
  final IconData icon;

  const _BridgeStep({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
    required this.icon,
  });
}

class _BridgeNode extends StatelessWidget {
  final _BridgeStep step;
  final double width;
  final bool compact;

  const _BridgeNode({
    required this.step,
    required this.width,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final progress = step.ratio.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(compact ? 8 : 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundMid.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: step.color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(step.icon, color: step.color, size: compact ? 14 : 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: compact ? 10.6 : 11.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 5 : 6),
            Text(
              _formatCurrency(step.value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    step.value < 0
                        ? AppColors.accentRed
                        : AppColors.textPrimary,
                fontSize: compact ? 11.8 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: compact ? 5 : 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: compact ? 4 : 5,
                value: progress,
                color: step.color,
                backgroundColor: AppColors.surfaceElevated.withValues(
                  alpha: 0.54,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatPercent(step.ratio),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: compact ? 9.8 : 10.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DreColumnHeader extends StatelessWidget {
  final bool compact;

  const _DreColumnHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.42),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.34),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text('Linha', style: _dreHeaderStyle(compact)),
          ),
          SizedBox(width: compact ? 6 : 10),
          SizedBox(
            width: compact ? 58 : 78,
            child: Text(
              '% base',
              textAlign: TextAlign.right,
              style: _dreHeaderStyle(compact),
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          SizedBox(
            width: compact ? 128 : 160,
            child: Text(
              'Valor',
              textAlign: TextAlign.right,
              style: _dreHeaderStyle(compact),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _dreHeaderStyle(bool compact) {
  return TextStyle(
    color: AppColors.textMuted,
    fontSize: compact ? 10.6 : 11.4,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

class _DreLineRow extends StatefulWidget {
  final DreLine line;
  final bool compact;

  const _DreLineRow({required this.line, this.compact = false});

  @override
  State<_DreLineRow> createState() => _DreLineRowState();
}

class _DreLineRowState extends State<_DreLineRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final compact = widget.compact;
    final isStrong = line.isHeader || line.isSubtotal || line.isResult;
    final color =
        line.value < 0
            ? AppColors.accentRed
            : line.isResult && line.value >= 0
            ? AppColors.accentGreen
            : AppColors.textPrimary;
    final rowAccent =
        line.isResult
            ? color
            : line.isSubtotal
            ? AppColors.accentGold
            : line.isHeader
            ? AppColors.accentBlue
            : AppColors.borderColor;
    final canExpand =
        compact && (line.detail != null || line.referenceValue != null);

    return Container(
      decoration: BoxDecoration(
        gradient:
            isStrong
                ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    rowAccent.withValues(alpha: line.isResult ? 0.16 : 0.10),
                    AppColors.surfaceElevated.withValues(alpha: 0.34),
                  ],
                )
                : null,
        color: isStrong ? null : AppColors.surfaceDark.withValues(alpha: 0.22),
        border: Border(
          left: BorderSide(
            color: rowAccent.withValues(alpha: isStrong ? 0.70 : 0.22),
            width: isStrong ? 3 : 1,
          ),
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.26),
          ),
        ),
      ),
      child: InkWell(
        onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 11,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                line.concept,
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      isStrong
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                  fontWeight:
                                      isStrong
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                  fontSize:
                                      compact
                                          ? (isStrong ? 13.3 : 12.9)
                                          : (isStrong ? 13.5 : 13),
                                ),
                              ),
                            ),
                            if (canExpand)
                              _DetailHint(
                                expanded: _expanded,
                                fontSize: 10.5,
                                iconSize: 16,
                              ),
                          ],
                        ),
                        if (!compact && line.detail != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            line.detail!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 10),
                  SizedBox(
                    width: compact ? 58 : 78,
                    child: Text(
                      line.referenceValue == null
                          ? '-'
                          : _formatPercent(line.referencePercent.abs() / 100),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: compact ? 12.3 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: compact ? 86 : 104,
                      maxWidth: compact ? 128 : 160,
                    ),
                    child: Text(
                      _formatCurrency(line.value),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight:
                            isStrong ? FontWeight.w900 : FontWeight.w700,
                        fontSize:
                            compact
                                ? (isStrong ? 13.7 : 13.2)
                                : (isStrong ? 14 : 13),
                      ),
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    [
                      if (line.detail != null) line.detail!,
                      if (line.referenceValue != null)
                        'Participacao: ${_formatPercent(line.referencePercent / 100)}',
                    ].join('  |  '),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.8,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _InsightPanel({required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final insights =
        compact
            ? report.executiveInsights.take(3).toList()
            : report.executiveInsights;
    final actions =
        compact
            ? report.managementActions.take(2).toList()
            : report.managementActions;

    final detailChildren = [
      ...insights.map(
        (item) => _BulletItem(
          icon: Icons.insights_rounded,
          color: AppColors.accentBlue,
          text: item,
          compact: compact,
        ),
      ),
      SizedBox(height: compact ? 3 : 10),
      if (!compact) const Divider(),
      SizedBox(height: compact ? 3 : 10),
      const Text(
        'Acoes sugeridas',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
      SizedBox(height: compact ? 6 : 10),
      ...actions.map(
        (item) => _BulletItem(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.accentGold,
          text: item,
          compact: compact,
        ),
      ),
    ];

    if (compact) {
      return _ExpandablePanel(
        icon: Icons.psychology_alt_rounded,
        title: 'Leitura para o CEO',
        subtitle: 'Sinais e acoes',
        initiallyExpanded: true,
        summary: _SummaryText(
          text:
              insights.isNotEmpty
                  ? insights.first
                  : 'Sem sinais executivos para este periodo.',
        ),
        detailChildren: detailChildren,
      );
    }

    return _Panel(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.psychology_alt_rounded,
            title: 'Leitura para o CEO',
            subtitle: 'Sinais que mudam decisao de preco, compra e caixa',
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          ...detailChildren,
        ],
      ),
    );
  }
}

class _ExpenseBreakdown extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _ExpenseBreakdown({required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final items =
        [
          _BreakdownItem(
            'Materiais',
            report.materialCosts,
            AppColors.accentGold,
          ),
          _BreakdownItem(
            'Mao de obra',
            report.laborCosts + report.operationalLaborCosts,
            AppColors.green,
          ),
          _BreakdownItem(
            'Equipamentos',
            report.equipmentCosts + report.operationalEquipmentCosts,
            AppColors.blue,
          ),
          _BreakdownItem(
            'Administrativo',
            report.administrativeExpenses,
            AppColors.purple,
          ),
          _BreakdownItem('Impostos', report.taxDeductions, AppColors.orange),
          _BreakdownItem(
            'Outros',
            report.otherProjectCosts + report.otherOperationalExpenses,
            AppColors.textMuted,
          ),
        ].where((item) => item.value > 0.01).toList();
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    if (compact) {
      return _ExpandablePanel(
        icon: Icons.donut_large_rounded,
        title: 'Gastos por natureza',
        subtitle: 'Clique para detalhar',
        summary:
            items.isEmpty
                ? const _SummaryText(
                  text: 'Nenhuma despesa paga classificada no periodo.',
                )
                : _ExpenseSummary(items: items, total: total),
        detailChildren:
            items.isEmpty
                ? const [
                  _SummaryText(
                    text: 'Nenhuma despesa paga classificada no periodo.',
                  ),
                ]
                : items
                    .map(
                      (item) => _ProgressLine(
                        label: item.label,
                        value: _formatCurrency(item.value),
                        percent: total <= 0 ? 0 : item.value / total,
                        color: item.color,
                        compact: true,
                      ),
                    )
                    .toList(),
      );
    }

    return _Panel(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.donut_large_rounded,
            title: 'Gastos por natureza',
            subtitle: 'Onde o dinheiro saiu dentro do periodo',
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          if (items.isEmpty)
            const Text(
              'Nenhuma despesa paga classificada no periodo.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...items.map(
              (item) => _ProgressLine(
                label: item.label,
                value: _formatCurrency(item.value),
                percent: total <= 0 ? 0 : item.value / total,
                color: item.color,
                compact: compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanyContextPanel extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _CompanyContextPanel({required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final contextData = report.companyContext;

    final metrics = [
      _ContextData(
        'Projetos ativos',
        '${contextData.activeProjectCount}/${contextData.projectCount}',
        _formatCurrency(contextData.projectBudgetTotal),
      ),
      _ContextData(
        'Custo das obras',
        _formatPercent(contextData.projectCostBurnPercent / 100),
        _formatCurrency(contextData.projectCurrentCostTotal),
      ),
      _ContextData(
        'Medicoes',
        _formatCurrency(contextData.measurementsInPeriod),
        'A receber ${_formatCurrency(contextData.measurementsReceivable)}',
      ),
      _ContextData(
        'Equipe ativa',
        '${contextData.activeEmployeeCount}',
        'Folha ${_formatCurrency(contextData.monthlyPayrollBase)}',
      ),
      _ContextData(
        'Estoque critico',
        '${contextData.criticalInventoryItemCount}/${contextData.inventoryItemCount}',
        'Itens no minimo',
      ),
      _ContextData(
        'Compras abertas',
        '${contextData.openPurchaseCount}',
        _formatCurrency(contextData.openPurchaseValue),
      ),
    ];

    if (compact) {
      return _ExpandablePanel(
        icon: Icons.apartment_rounded,
        title: 'Contexto geral',
        subtitle: 'Obras, equipe e estoque',
        summary: _CompactContextGrid(metrics: metrics.take(2).toList()),
        detailChildren: [_CompactContextGrid(metrics: metrics)],
      );
    }

    return _Panel(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.apartment_rounded,
            title: 'Contexto geral da empresa',
            subtitle: 'Obras, equipe, estoque e medicoes lidos do ERP',
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          if (compact)
            _CompactContextGrid(metrics: metrics)
          else
            ...metrics.map(
              (metric) => _ContextMetric(
                label: metric.label,
                value: metric.value,
                detail: metric.detail,
              ),
            ),
        ],
      ),
    );
  }
}

class _CashRiskPanel extends StatelessWidget {
  final DreExecutiveReport report;
  final bool compact;

  const _CashRiskPanel({required this.report, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final coverage =
        report.cashCoverage >= 999
            ? 1.0
            : report.cashCoverage.clamp(0.0, 1.0).toDouble();
    final coverageColor =
        report.pendingIncome >= report.pendingExpense
            ? AppColors.accentGreen
            : AppColors.accentRed;

    final cashTiles = [
      _CashTile(
        label: 'A receber',
        value: report.pendingIncome,
        color: AppColors.accentGreen,
        icon: Icons.arrow_downward_rounded,
        compact: compact,
      ),
      _CashTile(
        label: 'A pagar',
        value: report.pendingExpense,
        color: AppColors.accentGold,
        icon: Icons.arrow_upward_rounded,
        compact: compact,
      ),
      _CashTile(
        label: 'Vencido',
        value: report.overdueExpense,
        color: AppColors.accentRed,
        icon: Icons.priority_high_rounded,
        compact: compact,
      ),
    ];

    final coverageLine = _ProgressLine(
      label: 'Cobertura de contas a pagar por recebiveis',
      value:
          report.pendingExpense <= 0
              ? 'Sem pressao'
              : _formatPercent(report.cashCoverage),
      percent: coverage,
      color: coverageColor,
      compact: compact,
    );

    if (compact) {
      return _ExpandablePanel(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Perspectiva de caixa',
        subtitle: 'Receber, pagar e vencidos',
        summary: _CashTileRow(compact: true, children: cashTiles),
        detailChildren: [
          _CashTileRow(compact: true, children: cashTiles),
          const SizedBox(height: 8),
          coverageLine,
        ],
      );
    }

    return _Panel(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Perspectiva de caixa',
            subtitle: 'Contas abertas que pressionam os proximos ciclos',
            compact: compact,
          ),
          SizedBox(height: compact ? 8 : 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;

              if (narrow) {
                return Column(
                  children:
                      cashTiles
                          .map(
                            (child) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: child,
                            ),
                          )
                          .toList(),
                );
              }

              return _CashTileRow(compact: false, children: cashTiles);
            },
          ),
          SizedBox(height: compact ? 8 : 14),
          coverageLine,
        ],
      ),
    );
  }
}

class _ExpandablePanel extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget summary;
  final List<Widget> detailChildren;
  final bool initiallyExpanded;

  const _ExpandablePanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.detailChildren,
    this.initiallyExpanded = false,
  });

  @override
  State<_ExpandablePanel> createState() => _ExpandablePanelState();
}

class _ExpandablePanelState extends State<_ExpandablePanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(widget.icon, color: AppColors.accentGold, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _DetailHint(expanded: _expanded),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child:
                  _expanded
                      ? SingleChildScrollView(
                        key: const ValueKey('detail'),
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.detailChildren,
                        ),
                      )
                      : Align(
                        key: const ValueKey('summary'),
                        alignment: Alignment.topLeft,
                        child: widget.summary,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHint extends StatelessWidget {
  final bool expanded;
  final double fontSize;
  final double iconSize;

  const _DetailHint({
    required this.expanded,
    this.fontSize = 11,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          expanded ? 'ocultar' : 'ver detalhes',
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.88),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        Icon(
          expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMuted,
          size: iconSize,
        ),
      ],
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String text;

  const _SummaryText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.26,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ExpenseSummary extends StatelessWidget {
  final List<_BreakdownItem> items;
  final double total;

  const _ExpenseSummary({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final topItems = items.take(3).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          topItems.map((item) {
            final percent = total <= 0 ? 0.0 : item.value / total;
            return _SummaryPill(
              label: item.label,
              value: _formatPercent(percent),
              color: item.color,
            );
          }).toList(),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextData {
  final String label;
  final String value;
  final String detail;

  const _ContextData(this.label, this.value, this.detail);
}

class _CompactContextGrid extends StatelessWidget {
  final List<_ContextData> metrics;

  const _CompactContextGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final width = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              metrics
                  .map(
                    (metric) => SizedBox(
                      width: width,
                      child: _CompactContextMetric(metric: metric),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _CompactContextMetric extends StatelessWidget {
  final _ContextData metric;

  const _CompactContextMetric({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _CashTileRow extends StatelessWidget {
  final List<Widget> children;
  final bool compact;

  const _CashTileRow({required this.children, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right:
                    i == children.length - 1
                        ? 0
                        : compact
                        ? 6
                        : 10,
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

class _CashTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool compact;

  const _CashTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 9 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: compact ? 16 : 20),
          SizedBox(width: compact ? 7 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  _formatCurrency(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final double? minHeight;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  const _Panel({
    required this.child,
    this.minHeight,
    this.padding = const EdgeInsets.all(16),
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: AppDecorations.cardSurface(
        accent: accent ?? AppColors.accentBlue,
        radius: 12,
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accentGold, size: compact ? 16 : 19),
        SizedBox(width: compact ? 7 : 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 13 : 15,
                ),
              ),
              SizedBox(height: compact ? 1 : 3),
              Text(
                subtitle,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: compact ? 10.5 : 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool compact;

  const _BulletItem({
    required this.icon,
    required this.color,
    required this.text,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: compact ? 14 : 17),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Text(
              text,
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: compact ? 1.22 : 1.34,
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;
  final bool compact;

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 13),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: compact ? 11.5 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: compact ? 5 : 7,
              value: clamped,
              color: color,
              backgroundColor: AppColors.surfaceElevated.withValues(
                alpha: 0.48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextMetric extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const _ContextMetric({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool compact;

  const _ErrorBanner({required this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 9 : 13),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.accentRed.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final double value;
  final Color color;

  const _BreakdownItem(this.label, this.value, this.color);
}

double _safeRatio(double value, double base) {
  if (base.abs() < 0.01) return 0;
  return value.abs() / base.abs();
}

String _formatCurrency(double value) {
  final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  return currency.format(value);
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(1)}%';
}
