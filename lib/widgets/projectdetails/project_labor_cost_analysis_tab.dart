import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/project_labor_cost_analysis_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class ProjectLaborCostAnalysisTab extends StatefulWidget {
  final Project project;

  const ProjectLaborCostAnalysisTab({super.key, required this.project});

  @override
  State<ProjectLaborCostAnalysisTab> createState() =>
      _ProjectLaborCostAnalysisTabState();
}

class _ProjectLaborCostAnalysisTabState
    extends State<ProjectLaborCostAnalysisTab> {
  final _calculator = const ProjectLaborCostCalculator();
  final _sourceErrors = <String, String>{};

  StreamSubscription<List<DailyLogModel>>? _dailyLogsSub;
  StreamSubscription<List<ProjectLaborWorkHourEntry>>? _workHoursSub;
  StreamSubscription<List<EmployeeModel>>? _employeesSub;
  StreamSubscription<List<TeamModel>>? _teamsSub;

  List<DailyLogModel>? _dailyLogs;
  List<ProjectLaborWorkHourEntry>? _workHourEntries;
  List<EmployeeModel>? _employees;
  List<TeamModel>? _teams;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant ProjectLaborCostAnalysisTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      _subscribe();
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveLayout.pagePadding(width);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    final report = _calculator.build(
      projectId: widget.project.id,
      coordinatorId: widget.project.coordinatorId,
      dailyLogs: _dailyLogs ?? const [],
      mobileEntries: _workHourEntries ?? const [],
      employees: _employees ?? const [],
      teams: _teams ?? const [],
    );

    return ListView(
      padding: padding,
      children: [
        _LaborHeader(project: widget.project, report: report),
        const SizedBox(height: 14),
        _LaborDataQualityPanel(report: report, sourceErrors: _sourceErrors),
        const SizedBox(height: 14),
        _LaborMetricGrid(report: report),
        const SizedBox(height: 14),
        _RoleBreakdownPanel(report: report),
        const SizedBox(height: 14),
        _DailyBreakdownPanel(report: report),
        const SizedBox(height: 14),
        const _LaborMethodologyPanel(),
      ],
    );
  }

  bool get _isLoading =>
      _dailyLogs == null ||
      _workHourEntries == null ||
      _employees == null ||
      _teams == null;

  void _subscribe() {
    _cancelSubscriptions();
    _sourceErrors.clear();
    _dailyLogs = null;
    _workHourEntries = null;
    _employees = null;
    _teams = null;

    _dailyLogsSub = AppSupabase.client
        .from('daily_logs')
        .stream(primaryKey: ['id'])
        .eq('projectId', widget.project.id)
        .order('date', ascending: false)
        .map(
          (rows) =>
              rows.map((row) {
                final data = Map<String, dynamic>.from(row);
                return DailyLogModel.fromMap(
                  data,
                  data['id']?.toString() ?? '',
                );
              }).toList(),
        )
        .listen(
          (logs) => _setSourceData(
            source: 'daily_logs',
            update: () => _dailyLogs = logs,
          ),
          onError:
              (error) => _setSourceError(
                source: 'daily_logs',
                label: 'Diarios de obra',
                error: error,
                fallback: () => _dailyLogs = const [],
              ),
        );

    _workHoursSub = AppSupabase.client
        .from('mobile_work_hour_entries')
        .stream(primaryKey: ['id'])
        .eq('projectId', widget.project.id)
        .order('startAt', ascending: false)
        .map(
          (rows) =>
              rows.map((row) {
                final data = Map<String, dynamic>.from(row);
                return ProjectLaborWorkHourEntry.fromMap(
                  data,
                  data['id']?.toString() ?? '',
                );
              }).toList(),
        )
        .listen(
          (entries) => _setSourceData(
            source: 'mobile_work_hour_entries',
            update: () => _workHourEntries = entries,
          ),
          onError:
              (error) => _setSourceError(
                source: 'mobile_work_hour_entries',
                label: 'Apontamentos mobile',
                error: error,
                fallback: () => _workHourEntries = const [],
              ),
        );

    _employeesSub = AppSupabase.client
        .from('employees')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (rows) =>
              rows
                  .map(
                    (row) => EmployeeModel.fromMap(
                      Map<String, dynamic>.from(row),
                      row['id']?.toString() ?? '',
                    ),
                  )
                  .toList(),
        )
        .listen(
          (employees) => _setSourceData(
            source: 'employees',
            update: () => _employees = employees,
          ),
          onError:
              (error) => _setSourceError(
                source: 'employees',
                label: 'Funcionarios e salarios',
                error: error,
                fallback: () => _employees = const [],
              ),
        );

    _teamsSub = AppSupabase.client
        .from('teams')
        .stream(primaryKey: ['id'])
        .eq('projectId', widget.project.id)
        .map(
          (rows) =>
              rows
                  .map(
                    (row) => TeamModel.fromMap(
                      Map<String, dynamic>.from(row),
                      row['id']?.toString() ?? '',
                    ),
                  )
                  .toList(),
        )
        .listen(
          (teams) =>
              _setSourceData(source: 'teams', update: () => _teams = teams),
          onError:
              (error) => _setSourceError(
                source: 'teams',
                label: 'Equipes vinculadas',
                error: error,
                fallback: () => _teams = const [],
              ),
        );
  }

  void _setSourceData({required String source, required VoidCallback update}) {
    if (!mounted) return;
    setState(() {
      update();
      _sourceErrors.remove(source);
    });
  }

  void _setSourceError({
    required String source,
    required String label,
    required Object error,
    required VoidCallback fallback,
  }) {
    if (!mounted) return;
    setState(() {
      fallback();
      _sourceErrors[source] = '$label: $error';
    });
  }

  void _cancelSubscriptions() {
    _dailyLogsSub?.cancel();
    _workHoursSub?.cancel();
    _employeesSub?.cancel();
    _teamsSub?.cancel();
    _dailyLogsSub = null;
    _workHoursSub = null;
    _employeesSub = null;
    _teamsSub = null;
  }
}

class _LaborHeader extends StatelessWidget {
  final Project project;
  final ProjectLaborCostReport report;

  const _LaborHeader({required this.project, required this.report});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final budgetImpact =
        project.budget > 0 ? report.consolidatedCost / project.budget : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentGold,
        emphasized: true,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: AppDecorations.iconTile(AppColors.accentGold),
                    child: const Icon(
                      Icons.engineering_rounded,
                      color: AppColors.accentGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analise de gasto com mao de obra',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Consolida dados do app mobile, diarios de obra e salarios cadastrados.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

          final budgetBlock = _BudgetImpactBlock(
            value: budgetImpact.clamp(0, 1).toDouble(),
            label:
                project.budget > 0
                    ? '${(budgetImpact * 100).toStringAsFixed(1)}% do budget da obra'
                    : 'Budget da obra nao informado',
            amount: currency.format(report.consolidatedCost),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleBlock, const SizedBox(height: 16), budgetBlock],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 24),
              SizedBox(width: 280, child: budgetBlock),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetImpactBlock extends StatelessWidget {
  final double value;
  final String label;
  final String amount;

  const _BudgetImpactBlock({
    required this.value,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.accentGold,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: AppColors.accentGold,
            backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.76),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _LaborDataQualityPanel extends StatelessWidget {
  final ProjectLaborCostReport report;
  final Map<String, String> sourceErrors;

  const _LaborDataQualityPanel({
    required this.report,
    required this.sourceErrors,
  });

  @override
  Widget build(BuildContext context) {
    final messages = <_QualityMessage>[];

    if (!report.hasAnySource) {
      messages.add(
        const _QualityMessage(
          icon: Icons.info_outline_rounded,
          color: AppColors.accentBlue,
          text:
              'Nenhum diario ou apontamento mobile encontrado para esta obra.',
        ),
      );
    }

    if (sourceErrors.isNotEmpty) {
      messages.addAll(
        sourceErrors.values.map(
          (error) => _QualityMessage(
            icon: Icons.warning_amber_rounded,
            color: AppColors.accentRed,
            text: error,
          ),
        ),
      );
    }

    if (report.averageHourlyRate <= 0 && report.hasAnySource) {
      messages.add(
        const _QualityMessage(
          icon: Icons.payments_outlined,
          color: AppColors.accentGold,
          text:
              'Cadastre salario nos funcionarios da equipe para estimar custo real.',
        ),
      );
    } else if (report.missingSalaryNames.isNotEmpty) {
      final names = report.missingSalaryNames.take(3).join(', ');
      messages.add(
        _QualityMessage(
          icon: Icons.manage_accounts_outlined,
          color: AppColors.accentGold,
          text: 'Funcionarios sem salario na base: $names.',
        ),
      );
    }

    if (report.pendingMobileCost > 0) {
      messages.add(
        const _QualityMessage(
          icon: Icons.pending_actions_outlined,
          color: AppColors.orange,
          text:
              'Ha apontamentos mobile pendentes. Eles aparecem separados e nao entram no custo consolidado.',
        ),
      );
    }

    if (messages.isEmpty) {
      messages.add(
        const _QualityMessage(
          icon: Icons.verified_outlined,
          color: AppColors.accentGreen,
          text:
              'Base pronta: apontamentos aprovados e estimativas do diario estao consolidados sem dupla contagem por dia.',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardInnerSurface(
        accent:
            messages.any((m) => m.color == AppColors.accentRed)
                ? AppColors.accentRed
                : AppColors.accentGold,
      ),
      child: Column(
        children:
            messages
                .map(
                  (message) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(message.icon, color: message.color, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message.text,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _QualityMessage {
  final IconData icon;
  final Color color;
  final String text;

  const _QualityMessage({
    required this.icon,
    required this.color,
    required this.text,
  });
}

class _LaborMetricGrid extends StatelessWidget {
  final ProjectLaborCostReport report;

  const _LaborMetricGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final metrics = [
      _LaborMetricData(
        icon: Icons.price_check_rounded,
        label: 'Custo consolidado',
        value: currency.format(report.consolidatedCost),
        detail: 'Aprovado no app + estimativa sem dupla contagem',
        color: AppColors.accentGold,
      ),
      _LaborMetricData(
        icon: Icons.timer_outlined,
        label: 'Horas aprovadas',
        value: _formatHours(report.approvedMobileHours),
        detail: currency.format(report.approvedMobileCost),
        color: AppColors.accentGreen,
      ),
      _LaborMetricData(
        icon: Icons.pending_actions_outlined,
        label: 'Pendentes mobile',
        value: _formatHours(report.pendingMobileHours),
        detail: currency.format(report.pendingMobileCost),
        color: AppColors.orange,
      ),
      _LaborMetricData(
        icon: Icons.groups_2_outlined,
        label: 'Equipe com salario',
        value:
            '${report.linkedTeamMembersWithSalaryCount}/${report.linkedTeamMembersCount}',
        detail:
            report.linkedTeamMembersCount == 0
                ? 'Sem equipe vinculada'
                : '${(report.salaryCoverage * 100).toStringAsFixed(0)}% de cobertura',
        color: AppColors.accentBlue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 960
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
          children:
              metrics
                  .map(
                    (metric) => SizedBox(
                      width: itemWidth,
                      child: _LaborMetricCard(data: metric),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _LaborMetricData {
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _LaborMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });
}

class _LaborMetricCard extends StatelessWidget {
  final _LaborMetricData data;

  const _LaborMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.statCardSurface(data.color, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppDecorations.iconTile(data.color),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const Spacer(),
              Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: data.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              maxLines: 1,
              style: TextStyle(
                color: data.color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBreakdownPanel extends StatelessWidget {
  final ProjectLaborCostReport report;

  const _RoleBreakdownPanel({required this.report});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final roles = report.roleCosts.take(8).toList();
    final maxCost = roles.fold<double>(
      0,
      (maxValue, role) => math.max(maxValue, role.totalCost),
    );

    return _LaborSectionPanel(
      title: 'Custo por funcao ou cargo',
      subtitle: 'Quebra consolidada entre horas aprovadas e estimativa diaria.',
      icon: Icons.stacked_bar_chart_rounded,
      child:
          roles.isEmpty
              ? const _LaborEmptyInline(
                text: 'Sem custo por funcao para exibir ainda.',
              )
              : Column(
                children:
                    roles
                        .map(
                          (role) => _RoleCostRow(
                            role: role,
                            maxCost: maxCost,
                            currency: currency,
                          ),
                        )
                        .toList(),
              ),
    );
  }
}

class _RoleCostRow extends StatelessWidget {
  final ProjectLaborRoleCost role;
  final double maxCost;
  final NumberFormat currency;

  const _RoleCostRow({
    required this.role,
    required this.maxCost,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxCost <= 0 ? 0.0 : (role.totalCost / maxCost);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  role.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                currency.format(role.totalCost),
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 8,
              color: AppColors.accentGold,
              backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_formatHours(role.mobileHours)} app aprovado'
            ' | ${_formatHours(role.estimatedHours)} estimado por diario',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DailyBreakdownPanel extends StatelessWidget {
  final ProjectLaborCostReport report;

  const _DailyBreakdownPanel({required this.report});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
    final days = report.dayCosts.take(12).toList();

    return _LaborSectionPanel(
      title: 'Linha do tempo da obra',
      subtitle: 'Dias com apontamento mobile prevalecem sobre estimativa.',
      icon: Icons.calendar_month_outlined,
      child:
          days.isEmpty
              ? const _LaborEmptyInline(
                text: 'Nenhum dia com mao de obra registrado.',
              )
              : Column(
                children:
                    days
                        .map(
                          (day) => _DailyCostRow(
                            day: day,
                            currency: currency,
                            dateFormat: dateFormat,
                          ),
                        )
                        .toList(),
              ),
    );
  }
}

class _DailyCostRow extends StatelessWidget {
  final ProjectLaborDayCost day;
  final NumberFormat currency;
  final DateFormat dateFormat;

  const _DailyCostRow({
    required this.day,
    required this.currency,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final sourceColor =
        day.usesDailyEstimate ? AppColors.accentBlue : AppColors.accentGreen;
    final sourceLabel = day.usesDailyEstimate ? 'Diario estimado' : 'Mobile';
    final detail =
        day.usesDailyEstimate
            ? '${day.dailyEstimatedPeople} pessoas estimadas'
            : '${_formatMinutes(day.approvedMobileMinutes)} aprovadas';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.54),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: AppDecorations.iconTile(sourceColor),
            child: Icon(
              day.usesDailyEstimate
                  ? Icons.menu_book_outlined
                  : Icons.phone_android_rounded,
              color: sourceColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(day.date),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(day.consolidatedCost),
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              _SourceChip(label: sourceLabel, color: sourceColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaborMethodologyPanel extends StatelessWidget {
  const _LaborMethodologyPanel();

  @override
  Widget build(BuildContext context) {
    return _LaborSectionPanel(
      title: 'Metodo de calculo',
      subtitle: 'Regra aplicada para evitar dupla contagem.',
      icon: Icons.rule_folder_outlined,
      child: const Text(
        'O custo horario usa salario base / 220. Quando o app envia horas '
        'aprovadas em um dia, esse valor prevalece. Quando nao ha apontamento '
        'mobile no dia, o diario de obra estima 8h por pessoa informada em '
        'mao de obra. Apontamentos pendentes ficam separados ate aprovacao.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }
}

class _LaborSectionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _LaborSectionPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: AppDecorations.iconTile(AppColors.accentGold),
                child: Icon(icon, color: AppColors.accentGold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SourceChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LaborEmptyInline extends StatelessWidget {
  final String text;

  const _LaborEmptyInline({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatHours(double hours) {
  if (hours <= 0) return '0h';
  if (hours < 1) return '${(hours * 60).round()}min';
  final fixed = hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1);
  return '${fixed}h';
}

String _formatMinutes(int minutes) {
  if (minutes <= 0) return '0h';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '${remaining}min';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}min';
}
