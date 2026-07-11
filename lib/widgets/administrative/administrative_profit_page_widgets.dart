import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/administrative_profit_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:provider/provider.dart';

class AdministrativeProfitPageView extends StatefulWidget {
  const AdministrativeProfitPageView({super.key});

  @override
  State<AdministrativeProfitPageView> createState() =>
      _AdministrativeProfitPageViewState();
}

class _AdministrativeProfitPageViewState
    extends State<AdministrativeProfitPageView> {
  bool _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) return;
    _requestedInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdministrativeProfitController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdministrativeProfitController>(
      builder: (context, controller, _) {
        final width = MediaQuery.sizeOf(context).width;
        final padding = ResponsiveLayout.pagePadding(width);
        final summary = controller.summary;
        final loading = controller.isLoading && summary == null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            top: false,
            child:
                loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGold,
                      ),
                    )
                    : RefreshIndicator(
                      color: AppColors.accentGold,
                      backgroundColor: AppColors.surfaceDark,
                      onRefresh: controller.load,
                      child: ListView(
                        padding: padding,
                        children: [
                          _AdministrativeProfitHeader(
                            summary: summary,
                            isLoading: controller.isLoading,
                            onRefresh: controller.load,
                          ),
                          const SizedBox(height: 14),
                          _AdministrativeProfitFilters(controller: controller),
                          if (controller.error != null) ...[
                            const SizedBox(height: 14),
                            _NoticeBanner(
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.accentRed,
                              text: controller.error!,
                            ),
                          ],
                          const SizedBox(height: 14),
                          if (summary == null) ...[
                            const SizedBox(height: 80),
                            const Center(
                              child: Text(
                                'Carregando resultado administrativo...',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ] else ...[
                            _AdministrativeMetricGrid(summary: summary),
                            const SizedBox(height: 14),
                            _AdministrativeProfitWorkspace(summary: summary),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
          ),
        );
      },
    );
  }
}

class _AdministrativeProfitHeader extends StatelessWidget {
  final AdministrativeProfitSummary? summary;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _AdministrativeProfitHeader({
    required this.summary,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final result = summary?.profit ?? 0;
    final positive = result >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: positive ? AppColors.accentGreen : AppColors.accentRed,
        emphasized: true,
        radius: 22,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: AppDecorations.iconTile(
                  positive ? AppColors.accentGreen : AppColors.accentRed,
                ),
                child: Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: positive ? AppColors.accentGreen : AppColors.accentRed,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultado Administrativo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _scopeSubtitle(summary),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _HeaderBadge(
                icon: Icons.account_balance_wallet_outlined,
                label: currency.format(result),
                color: positive ? AppColors.accentGreen : AppColors.accentRed,
              ),
              IconButton.filledTonal(
                tooltip: 'Atualizar analise',
                onPressed: isLoading ? null : onRefresh,
                icon:
                    isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh_rounded),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), actions],
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
      ),
    );
  }

  static String _scopeSubtitle(AdministrativeProfitSummary? summary) {
    if (summary == null) {
      return 'Despesas vs lucro por empresa, periodo ou obra.';
    }
    final period = '${_formatDate(summary.from)} a ${_formatDate(summary.to)}';
    if (summary.scope == AdministrativeProfitScope.project) {
      return '${summary.selectedProject?.label ?? 'Obra nao selecionada'} | $period';
    }
    return 'Empresa inteira | $period';
  }
}

class _AdministrativeProfitFilters extends StatelessWidget {
  final AdministrativeProfitController controller;

  const _AdministrativeProfitFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentBlue,
        elevated: false,
        radius: 18,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final scope = SegmentedButton<AdministrativeProfitScope>(
            segments: const [
              ButtonSegment(
                value: AdministrativeProfitScope.company,
                icon: Icon(Icons.apartment_rounded),
                label: Text('Empresa'),
              ),
              ButtonSegment(
                value: AdministrativeProfitScope.project,
                icon: Icon(Icons.business_rounded),
                label: Text('Obra'),
              ),
            ],
            selected: {controller.scope},
            onSelectionChanged: (selected) {
              if (selected.isEmpty) return;
              controller.setScope(selected.first);
            },
          );

          final projectField = DropdownButtonFormField<String>(
            initialValue:
                controller.projects.any(
                      (project) => project.id == controller.selectedProjectId,
                    )
                    ? controller.selectedProjectId
                    : null,
            decoration: const InputDecoration(
              labelText: 'Obra',
              prefixIcon: Icon(Icons.business_center_outlined),
            ),
            dropdownColor: AppColors.surfaceDark,
            isExpanded: true,
            items: controller.projects
                .map(
                  (project) => DropdownMenuItem(
                    value: project.id,
                    child: Text(
                      project.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged:
                controller.scope == AdministrativeProfitScope.project
                    ? controller.selectProject
                    : null,
          );

          final periodButtons = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PeriodChip(
                label: 'Mes',
                selected: controller.isCurrentMonth,
                onTap: controller.setCurrentMonth,
              ),
              _PeriodChip(
                label: '90 dias',
                selected: controller.isLastNinetyDays,
                onTap: controller.setLastNinetyDays,
              ),
              _PeriodChip(
                label: 'Ano',
                selected: controller.isCurrentYear,
                onTap: controller.setCurrentYear,
              ),
              _PeriodChip(
                label: 'Personalizado',
                icon: Icons.date_range_rounded,
                selected:
                    !controller.isCurrentMonth &&
                    !controller.isLastNinetyDays &&
                    !controller.isCurrentYear,
                onTap: () => _pickRange(context, controller),
              ),
            ],
          );

          if (wide) {
            return Row(
              children: [
                SizedBox(width: 260, child: scope),
                const SizedBox(width: 12),
                Expanded(child: projectField),
                const SizedBox(width: 12),
                periodButtons,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              scope,
              const SizedBox(height: 12),
              projectField,
              const SizedBox(height: 12),
              periodButtons,
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    AdministrativeProfitController controller,
  ) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 3, 12, 31),
      initialDateRange: DateTimeRange(
        start: controller.periodFrom,
        end: controller.periodTo,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGold,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range == null) return;
    controller.setPeriod(range.start, range.end);
  }
}

class _AdministrativeMetricGrid extends StatelessWidget {
  final AdministrativeProfitSummary summary;

  const _AdministrativeMetricGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final metrics = [
      _Metric(
        label: 'Receita paga',
        value: currency.format(summary.income),
        detail: 'Entradas confirmadas',
        icon: Icons.south_west_rounded,
        color: AppColors.accentGreen,
      ),
      _Metric(
        label: 'Despesas pagas',
        value: currency.format(summary.expense),
        detail:
            '${(summary.expenseRatio * 100).toStringAsFixed(1)}% da receita',
        icon: Icons.north_east_rounded,
        color: AppColors.accentRed,
      ),
      _Metric(
        label: 'Lucro',
        value: currency.format(summary.profit),
        detail: 'Margem ${(summary.margin * 100).toStringAsFixed(1)}%',
        icon:
            summary.profit >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
        color: summary.profit >= 0 ? AppColors.accentGold : AppColors.accentRed,
      ),
      _Metric(
        label: 'Em aberto',
        value: currency.format(summary.pendingIncome - summary.pendingExpense),
        detail:
            'Receber ${currency.format(summary.pendingIncome)} | pagar ${currency.format(summary.pendingExpense)}',
        icon: Icons.pending_actions_rounded,
        color: AppColors.accentBlue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1120
                ? 4
                : constraints.maxWidth >= 620
                ? 2
                : 1;
        const gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: itemWidth,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _AdministrativeProfitWorkspace extends StatelessWidget {
  final AdministrativeProfitSummary summary;

  const _AdministrativeProfitWorkspace({required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;

        final chart = _ProfitExpenseChart(summary: summary);
        final side = Column(
          children: [
            _CategoryBreakdown(summary: summary),
            const SizedBox(height: 14),
            _InterpretationPanel(summary: summary),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: chart),
              const SizedBox(width: 14),
              Expanded(flex: 4, child: side),
            ],
          );
        }

        return Column(children: [chart, const SizedBox(height: 14), side]);
      },
    );
  }
}

class _ProfitExpenseChart extends StatelessWidget {
  final AdministrativeProfitSummary summary;

  const _ProfitExpenseChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final values = <double>[
      for (final point in summary.points) ...[point.expense, point.profit],
    ];
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final minValue = values.isEmpty ? 0.0 : values.reduce(math.min);
    final upper = math.max(maxValue, 1.0) * 1.18;
    final lower = minValue < 0 ? minValue * 1.18 : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentGold,
        emphasized: true,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppDecorations.iconTile(AppColors.accentGold),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.accentGold,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Despesas vs Lucro',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Comparativo mensal com base em transacoes pagas.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const _LegendDot(color: AppColors.accentRed, label: 'Despesa'),
              const SizedBox(width: 10),
              const _LegendDot(color: AppColors.accentGold, label: 'Lucro'),
            ],
          ),
          const SizedBox(height: 18),
          if (!summary.hasData)
            const SizedBox(
              height: 310,
              child: Center(
                child: Text(
                  'Sem lancamentos pagos para este filtro.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 330,
              child: BarChart(
                BarChartData(
                  minY: lower,
                  maxY: upper,
                  groupsSpace: 16,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: AppColors.borderColor.withValues(alpha: 0.35),
                          strokeWidth: 1,
                        ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor:
                          (_) => AppColors.surfaceDark.withValues(alpha: 0.96),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = summary.points[group.x.toInt()];
                        final label = rodIndex == 0 ? 'Despesa' : 'Lucro';
                        return BarTooltipItem(
                          '$label\n${_currency(rod.toY)}',
                          const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          children: [
                            TextSpan(
                              text: '\n${point.label}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 58,
                        getTitlesWidget:
                            (value, meta) => Text(
                              _compactCurrency(value),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= summary.points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              summary.points[index].label,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < summary.points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 5,
                        barRods: [
                          _rod(summary.points[i].expense, AppColors.accentRed),
                          _rod(summary.points[i].profit, AppColors.accentGold),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  BarChartRodData _rod(double value, Color color) {
    return BarChartRodData(
      toY: value,
      width: 12,
      borderRadius: BorderRadius.circular(5),
      gradient: LinearGradient(
        begin: value >= 0 ? Alignment.bottomCenter : Alignment.topCenter,
        end: value >= 0 ? Alignment.topCenter : Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.55), color],
      ),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: 0,
        color: AppColors.surfaceDark.withValues(alpha: 0.34),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final AdministrativeProfitSummary summary;

  const _CategoryBreakdown({required this.summary});

  @override
  Widget build(BuildContext context) {
    final entries =
        summary.expensesByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final total = summary.expense;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentRed,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Composicao das despesas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Categorias pagas no filtro atual.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Text(
              'Nenhuma despesa paga encontrada.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...entries.take(6).map((entry) {
              final percent = total <= 0 ? 0.0 : entry.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryLine(
                  label: _categoryLabel(entry.key),
                  value: entry.value,
                  percent: percent,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InterpretationPanel extends StatelessWidget {
  final AdministrativeProfitSummary summary;

  const _InterpretationPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final category = summary.mainExpenseCategory;
    final resultColor =
        summary.profit >= 0 ? AppColors.accentGreen : AppColors.accentRed;
    final message =
        summary.profit >= 0
            ? 'O filtro esta operando com lucro positivo. Use a margem para comparar obras e periodos sem distorcer por volume.'
            : 'O filtro esta consumindo mais caixa do que gera. Priorize receitas pendentes, revisao de custos e classificacao correta por obra.';
    final categoryText =
        category == null
            ? 'Ainda nao ha categoria dominante de despesa.'
            : '${_categoryLabel(category)} concentra ${_currency(summary.mainExpenseCategoryValue)} em despesas pagas.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: resultColor,
        elevated: false,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: resultColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Leitura rapida',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            categoryText,
            style: const TextStyle(
              color: AppColors.textMuted,
              height: 1.35,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(15),
      decoration: AppDecorations.statCardSurface(metric.color, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppDecorations.iconTile(metric.color),
                child: Icon(metric.icon, color: metric.color, size: 18),
              ),
              const Spacer(),
              Icon(Icons.auto_graph_rounded, color: metric.color, size: 17),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CategoryLine extends StatelessWidget {
  final String label;
  final double value;
  final double percent;

  const _CategoryLine({
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              _currency(value),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            minHeight: 7,
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.72),
            color: AppColors.accentRed,
          ),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(icon ?? Icons.calendar_month_rounded, size: 17),
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _NoticeBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: AppDecorations.formHintPanel(color: color),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

String _formatDate(DateTime date) {
  final formatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  return formatter.format(date);
}

String _currency(double value) {
  return NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);
}

String _compactCurrency(double value) {
  final abs = value.abs();
  final signal = value < 0 ? '-' : '';
  if (abs >= 1000000) {
    return '${signal}R\$ ${(abs / 1000000).toStringAsFixed(1)}M';
  }
  if (abs >= 1000) {
    return '${signal}R\$ ${(abs / 1000).toStringAsFixed(0)}k';
  }
  return '${signal}R\$ ${abs.toStringAsFixed(0)}';
}

String _categoryLabel(TransactionCategory category) {
  return switch (category) {
    TransactionCategory.material => 'Materiais',
    TransactionCategory.labor => 'Mao de obra',
    TransactionCategory.equipment => 'Equipamentos',
    TransactionCategory.administrative => 'Administrativo',
    TransactionCategory.measurement => 'Medicoes',
    TransactionCategory.tax => 'Impostos e taxas',
    TransactionCategory.other => 'Outros',
  };
}
