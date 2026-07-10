import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/project_labor_cost_analysis_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:printing/printing.dart';

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
  StreamSubscription<List<ProjectLaborTimeClockEvent>>? _timeClockEventsSub;
  StreamSubscription<List<EmployeeModel>>? _employeesSub;
  StreamSubscription<List<TeamModel>>? _teamsSub;

  List<DailyLogModel>? _dailyLogs;
  List<ProjectLaborWorkHourEntry>? _workHourEntries;
  List<ProjectLaborTimeClockEvent>? _timeClockEvents;
  List<EmployeeModel>? _employees;
  List<TeamModel>? _teams;
  bool _exportingPdf = false;

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
      timeClockEvents: _timeClockEvents ?? const [],
      employees: _employees ?? const [],
      teams: _teams ?? const [],
    );

    return ListView(
      padding: padding,
      children: [
        _LaborHeader(
          project: widget.project,
          report: report,
          exportingPdf: _exportingPdf,
          onExportProjectPdf: () => _exportPdf(report, _LaborPdfScope.project),
          onExportCoordinatorPdf:
              () => _exportPdf(report, _LaborPdfScope.coordinator),
        ),
        const SizedBox(height: 14),
        _LaborDataQualityPanel(report: report, sourceErrors: _sourceErrors),
        const SizedBox(height: 14),
        _LaborMetricGrid(report: report),
        const SizedBox(height: 14),
        _EmployeeBreakdownPanel(report: report),
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
      _timeClockEvents == null ||
      _employees == null ||
      _teams == null;

  void _subscribe() {
    _cancelSubscriptions();
    _sourceErrors.clear();
    _dailyLogs = null;
    _workHourEntries = null;
    _timeClockEvents = null;
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

    _timeClockEventsSub = AppSupabase.client
        .from('time_clock_afd_events')
        .stream(primaryKey: ['id'])
        .eq('projectId', widget.project.id)
        .order('eventAt', ascending: false)
        .map(
          (rows) =>
              rows.map((row) {
                final data = Map<String, dynamic>.from(row);
                return ProjectLaborTimeClockEvent.fromMap(
                  data,
                  data['id']?.toString() ?? '',
                );
              }).toList(),
        )
        .listen(
          (events) => _setSourceData(
            source: 'time_clock_afd_events',
            update: () => _timeClockEvents = events,
          ),
          onError:
              (error) => _setSourceError(
                source: 'time_clock_afd_events',
                label: 'Pontos do app mobile',
                error: error,
                fallback: () => _timeClockEvents = const [],
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
    _timeClockEventsSub?.cancel();
    _employeesSub?.cancel();
    _teamsSub?.cancel();
    _dailyLogsSub = null;
    _workHoursSub = null;
    _timeClockEventsSub = null;
    _employeesSub = null;
    _teamsSub = null;
  }

  Future<void> _exportPdf(
    ProjectLaborCostReport report,
    _LaborPdfScope scope,
  ) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    try {
      final bytes = await _buildLaborCostPdf(report, scope);
      await Printing.layoutPdf(
        name: _pdfFileName(scope),
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nao foi possivel gerar o PDF: $error'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<Uint8List> _buildLaborCostPdf(
    ProjectLaborCostReport report,
    _LaborPdfScope scope,
  ) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final generatedAt = DateFormat(
      'dd/MM/yyyy HH:mm',
      'pt_BR',
    ).format(DateTime.now());
    final title =
        scope == _LaborPdfScope.project
            ? 'Relatorio de mao de obra por obra'
            : 'Relatorio de mao de obra por coordenador';
    final coordinator =
        widget.project.coordinatorName?.trim().isNotEmpty == true
            ? widget.project.coordinatorName!.trim()
            : 'Sem coordenador definido';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build:
            (context) => [
              _pdfHeader(
                title: title,
                projectName: widget.project.name,
                coordinator: coordinator,
                generatedAt: generatedAt,
              ),
              pw.SizedBox(height: 18),
              _pdfMetricGrid(report, currency),
              pw.SizedBox(height: 18),
              _pdfSectionTitle('Funcionarios por tempo em obra'),
              _pdfEmployeeTable(report, currency),
              pw.SizedBox(height: 18),
              _pdfSectionTitle('Custo por funcao'),
              _pdfRoleTable(report, currency),
              pw.SizedBox(height: 18),
              _pdfSectionTitle('Linha do tempo'),
              _pdfDayTable(report, currency),
              pw.SizedBox(height: 18),
              pw.Text(
                'Metodo: salario base / 220. Pontos de entrada e saida do app formam jornadas aprovadas. Apontamentos manuais pendentes ficam separados do custo consolidado.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
      ),
    );

    return pdf.save();
  }

  String _pdfFileName(_LaborPdfScope scope) {
    final slug = widget.project.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final prefix =
        scope == _LaborPdfScope.project
            ? 'mao-de-obra-obra'
            : 'mao-de-obra-coordenador';
    return '$prefix-${slug.isEmpty ? widget.project.id : slug}.pdf';
  }
}

enum _LaborPdfScope { project, coordinator }

pw.Widget _pdfHeader({
  required String title,
  required String projectName,
  required String coordinator,
  required String generatedAt,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey900,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Granith',
          style: pw.TextStyle(
            color: PdfColors.amber,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Obra: $projectName',
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
        ),
        pw.Text(
          'Coordenador: $coordinator',
          style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
        ),
        pw.Text(
          'Gerado em: $generatedAt',
          style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 9),
        ),
      ],
    ),
  );
}

pw.Widget _pdfMetricGrid(ProjectLaborCostReport report, NumberFormat currency) {
  return pw.Row(
    children: [
      _pdfMetric('Custo consolidado', currency.format(report.consolidatedCost)),
      pw.SizedBox(width: 8),
      _pdfMetric('Horas aprovadas', _formatHours(report.approvedMobileHours)),
      pw.SizedBox(width: 8),
      _pdfMetric('Pendentes', _formatHours(report.pendingMobileHours)),
      pw.SizedBox(width: 8),
      _pdfMetric(
        'Equipe salario',
        '${report.linkedTeamMembersWithSalaryCount}/${report.linkedTeamMembersCount}',
      ),
    ],
  );
}

pw.Widget _pdfMetric(String label, String value) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 7),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.grey900,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _pdfSectionTitle(String title) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      ),
    ),
  );
}

pw.Widget _pdfEmployeeTable(
  ProjectLaborCostReport report,
  NumberFormat currency,
) {
  final rows = report.employeeCosts;
  if (rows.isEmpty) {
    return _pdfEmpty('Sem funcionarios com tempo apontado nesta obra.');
  }

  return _pdfTable(
    headers: const [
      'Funcionario',
      'Cargo',
      'Tempo',
      'Custo aprovado',
      'Pendente',
      'Reg.',
    ],
    rows:
        rows
            .map(
              (employee) => [
                employee.employeeName,
                employee.roleName,
                _formatMinutes(employee.totalMinutes),
                currency.format(employee.approvedCost),
                employee.pendingMinutes > 0
                    ? currency.format(employee.pendingCost)
                    : '-',
                employee.entriesCount.toString(),
              ],
            )
            .toList(),
  );
}

pw.Widget _pdfRoleTable(ProjectLaborCostReport report, NumberFormat currency) {
  final rows = report.roleCosts;
  if (rows.isEmpty) return _pdfEmpty('Sem custo por funcao para exibir.');

  return _pdfTable(
    headers: const ['Funcao', 'Horas app', 'Horas estimadas', 'Custo total'],
    rows:
        rows
            .map(
              (role) => [
                role.name,
                _formatHours(role.mobileHours),
                _formatHours(role.estimatedHours),
                currency.format(role.totalCost),
              ],
            )
            .toList(),
  );
}

pw.Widget _pdfDayTable(ProjectLaborCostReport report, NumberFormat currency) {
  final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  final rows = report.dayCosts.take(20).toList();
  if (rows.isEmpty) return _pdfEmpty('Sem dias com mao de obra registrada.');

  return _pdfTable(
    headers: const ['Data', 'Origem', 'Tempo aprovado', 'Pessoas', 'Custo'],
    rows:
        rows
            .map(
              (day) => [
                dateFormat.format(day.date),
                day.usesDailyEstimate ? 'Diario' : 'Mobile',
                _formatMinutes(day.approvedMobileMinutes),
                day.dailyEstimatedPeople.toString(),
                currency.format(day.consolidatedCost),
              ],
            )
            .toList(),
  );
}

pw.Widget _pdfTable({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final columnCount = headers.length;
  final widths = {
    for (var i = 0; i < columnCount; i++) i: const pw.FlexColumnWidth(),
  };

  return pw.Table(
    columnWidths: widths,
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children:
            headers
                .map(
                  (header) =>
                      _pdfCell(header, bold: true, color: PdfColors.grey900),
                )
                .toList(),
      ),
      ...rows.map(
        (row) => pw.TableRow(
          children:
              row.take(columnCount).map((cell) => _pdfCell(cell)).toList(),
        ),
      ),
    ],
  );
}

pw.Widget _pdfCell(
  String text, {
  bool bold = false,
  PdfColor color = PdfColors.grey800,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8,
        color: color,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _pdfEmpty(String text) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text(
      text,
      style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
    ),
  );
}

class _LaborHeader extends StatelessWidget {
  final Project project;
  final ProjectLaborCostReport report;
  final bool exportingPdf;
  final VoidCallback onExportProjectPdf;
  final VoidCallback onExportCoordinatorPdf;

  const _LaborHeader({
    required this.project,
    required this.report,
    required this.exportingPdf,
    required this.onExportProjectPdf,
    required this.onExportCoordinatorPdf,
  });

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
          final actions = _LaborPdfActions(
            exporting: exportingPdf,
            onExportProject: onExportProjectPdf,
            onExportCoordinator: onExportCoordinatorPdf,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 16),
                budgetBlock,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 24),
              SizedBox(width: 260, child: budgetBlock),
              const SizedBox(width: 14),
              SizedBox(width: 210, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _LaborPdfActions extends StatelessWidget {
  final bool exporting;
  final VoidCallback onExportProject;
  final VoidCallback onExportCoordinator;

  const _LaborPdfActions({
    required this.exporting,
    required this.onExportProject,
    required this.onExportCoordinator,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _LaborPdfButton(
          label: 'PDF obra',
          icon: Icons.picture_as_pdf_outlined,
          onPressed: exporting ? null : onExportProject,
        ),
        _LaborPdfButton(
          label: 'PDF coord.',
          icon: Icons.supervisor_account_outlined,
          onPressed: exporting ? null : onExportCoordinator,
        ),
      ],
    );
  }
}

class _LaborPdfButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _LaborPdfButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentGold,
        side: BorderSide(color: AppColors.accentGold.withValues(alpha: 0.46)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

class _EmployeeBreakdownPanel extends StatelessWidget {
  final ProjectLaborCostReport report;

  const _EmployeeBreakdownPanel({required this.report});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
    final employees = report.employeeCosts;

    return _LaborSectionPanel(
      title: 'Tempo e custo por funcionario',
      subtitle:
          'Ordenado por quem passou menos tempo na obra, com custo calculado por salario.',
      icon: Icons.badge_outlined,
      child:
          employees.isEmpty
              ? const _LaborEmptyInline(
                text:
                    'Nenhum ponto ou apontamento de horas por funcionario nesta obra.',
              )
              : Column(
                children: [
                  ...employees.map(
                    (employee) => _EmployeeCostRow(
                      employee: employee,
                      currency: currency,
                      dateFormat: dateFormat,
                    ),
                  ),
                  if (report.timeClockEventsCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _LaborSmallNote(
                        icon: Icons.access_time_rounded,
                        text:
                            '${report.timeClockEventsCount} eventos de ponto analisados, '
                            '${report.timeClockPairedEntriesCount} jornadas formadas.',
                      ),
                    ),
                ],
              ),
    );
  }
}

class _EmployeeCostRow extends StatelessWidget {
  final ProjectLaborEmployeeCost employee;
  final NumberFormat currency;
  final DateFormat dateFormat;

  const _EmployeeCostRow({
    required this.employee,
    required this.currency,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = employee.pendingMinutes > 0;
    final statusColor = hasPending ? AppColors.orange : AppColors.accentGreen;
    final first = employee.firstAt;
    final last = employee.lastAt;
    final period =
        first == null || last == null
            ? 'Sem periodo'
            : '${dateFormat.format(first)} - ${dateFormat.format(last)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: hasPending ? 0.28 : 0.18),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final identity = Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppDecorations.iconTile(statusColor),
                child: Center(
                  child: Text(
                    _initials(employee.employeeName),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${employee.roleName} | $period',
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
            ],
          );

          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _EmployeeMiniMetric(
                label: 'Tempo',
                value: _formatMinutes(employee.totalMinutes),
                color: AppColors.accentBlue,
              ),
              _EmployeeMiniMetric(
                label: 'Aprovado',
                value: currency.format(employee.approvedCost),
                color: AppColors.accentGold,
              ),
              if (hasPending)
                _EmployeeMiniMetric(
                  label: 'Pendente',
                  value: currency.format(employee.pendingCost),
                  color: AppColors.orange,
                ),
              _EmployeeMiniMetric(
                label: 'Registros',
                value: '${employee.entriesCount}',
                color: statusColor,
              ),
            ],
          );

          final source = Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              if (employee.timeClockEntriesCount > 0)
                _SourceChip(
                  label: 'Ponto ${employee.timeClockEntriesCount}',
                  color: AppColors.accentGreen,
                ),
              if (employee.manualEntriesCount > 0)
                _SourceChip(
                  label: 'Manual ${employee.manualEntriesCount}',
                  color: AppColors.accentBlue,
                ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 12),
                metrics,
                const SizedBox(height: 8),
                source,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [metrics, const SizedBox(height: 8), source],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmployeeMiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EmployeeMiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
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

class _LaborSmallNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LaborSmallNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
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

String _initials(String value) {
  final parts =
      value
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
