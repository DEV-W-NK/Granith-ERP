import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

enum _LaborPeriod {
  seven(days: 7, label: '7 dias'),
  thirty(days: 30, label: '30 dias'),
  ninety(days: 90, label: '90 dias');

  final int days;
  final String label;

  const _LaborPeriod({required this.days, required this.label});
}

class LaborFinanceAnalysisPageView extends StatefulWidget {
  const LaborFinanceAnalysisPageView({super.key});

  @override
  State<LaborFinanceAnalysisPageView> createState() =>
      _LaborFinanceAnalysisPageViewState();
}

class _LaborFinanceAnalysisPageViewState
    extends State<LaborFinanceAnalysisPageView> {
  static const _allFilterKey = '__all__';

  final _searchCtrl = TextEditingController();
  StreamSubscription<List<_LaborClockEvent>>? _eventsSub;
  StreamSubscription<List<EmployeeModel>>? _employeesSub;

  List<_LaborClockEvent>? _events;
  List<EmployeeModel>? _employees;
  Object? _eventsError;
  Object? _employeesError;
  _LaborPeriod _period = _LaborPeriod.thirty;
  String _employeeFilter = _allFilterKey;
  String _projectFilter = _allFilterKey;
  bool _exceptionsOnly = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _eventsSub?.cancel();
    _employeesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;

    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
      );
    }

    final canViewFinancial = PermissionCodes.canViewFinancial(
      isAdmin: auth.isAdminUser || (user?.isAdmin ?? false),
      permissions: user?.permissions ?? const <String>[],
    );

    if (!canViewFinancial) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Voce nao tem permissao para acessar esta analise financeira.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveLayout.pagePadding(width);
    final loading = _events == null || _employees == null;
    final baseEvents = _events ?? const [];
    final filterOptions = _LaborFilterOptions.fromEvents(
      _eventsInPeriod(baseEvents),
    );
    final selectedEmployeeFilter =
        filterOptions.hasEmployee(_employeeFilter)
            ? _employeeFilter
            : _allFilterKey;
    final selectedProjectFilter =
        filterOptions.hasProject(_projectFilter)
            ? _projectFilter
            : _allFilterKey;
    final filteredEvents = _filterEvents(
      baseEvents,
      employeeFilter: selectedEmployeeFilter,
      projectFilter: selectedProjectFilter,
    );
    final summary = _LaborFinanceSummary.build(
      events: filteredEvents,
      employees: _employees ?? const [],
      periodDays: _period.days,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child:
            loading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                )
                : RefreshIndicator(
                  onRefresh: _reload,
                  color: AppColors.accentGold,
                  backgroundColor: AppColors.surfaceDark,
                  child: ListView(
                    padding: padding,
                    children: [
                      _LaborFinanceHeader(summary: summary, period: _period),
                      const SizedBox(height: 14),
                      if (_eventsError != null || _employeesError != null) ...[
                        _LaborFinanceNotice(
                          icon: Icons.cloud_off_rounded,
                          color: Colors.orangeAccent,
                          text:
                              'Parte dos dados nao carregou agora. A analise usa o que estiver disponivel e atualiza ao recarregar.',
                        ),
                        const SizedBox(height: 14),
                      ],
                      _LaborFinanceFilters(
                        controller: _searchCtrl,
                        period: _period,
                        options: filterOptions,
                        selectedEmployeeKey: selectedEmployeeFilter,
                        selectedProjectKey: selectedProjectFilter,
                        exceptionsOnly: _exceptionsOnly,
                        exportingPdf: _exportingPdf,
                        onQueryChanged: (_) => setState(() {}),
                        onClear: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                        onPeriodChanged: (value) {
                          if (value == null) return;
                          setState(() => _period = value);
                        },
                        onEmployeeChanged: (value) {
                          if (value == null) return;
                          setState(() => _employeeFilter = value);
                        },
                        onProjectChanged: (value) {
                          if (value == null) return;
                          setState(() => _projectFilter = value);
                        },
                        onExceptionsOnlyChanged:
                            (value) => setState(() => _exceptionsOnly = value),
                        onExportPdf: () => _exportPdf(summary),
                      ),
                      const SizedBox(height: 14),
                      _LaborFinanceMetricGrid(summary: summary),
                      const SizedBox(height: 14),
                      _LaborFinanceDiagnosticsPanel(summary: summary),
                      const SizedBox(height: 14),
                      _LaborFinanceContentGrid(summary: summary),
                      const SizedBox(height: 14),
                      _LaborRecentExceptionsPanel(summary: summary),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      ),
    );
  }

  void _subscribe() {
    _eventsSub?.cancel();
    _employeesSub?.cancel();

    _eventsSub = AppSupabase.client
        .from('time_clock_afd_events')
        .stream(primaryKey: ['id'])
        .order('eventAt', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) =>
                    _LaborClockEvent.fromMap(Map<String, dynamic>.from(row)),
              )
              .where((event) => event.isPunchRelated)
              .toList(growable: false),
        )
        .listen(
          (events) {
            if (!mounted) return;
            setState(() {
              _events = events;
              _eventsError = null;
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _events = const [];
              _eventsError = error;
            });
          },
        );

    _employeesSub = AppSupabase.client
        .from('employees')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (rows) => rows
              .map(
                (row) => EmployeeModel.fromMap(
                  Map<String, dynamic>.from(row),
                  row['id']?.toString() ?? '',
                ),
              )
              .toList(growable: false),
        )
        .listen(
          (employees) {
            if (!mounted) return;
            setState(() {
              _employees = employees;
              _employeesError = null;
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _employees = const [];
              _employeesError = error;
            });
          },
        );
  }

  Future<void> _reload() async {
    setState(() {
      _events = null;
      _employees = null;
      _eventsError = null;
      _employeesError = null;
    });
    _subscribe();
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  List<_LaborClockEvent> _eventsInPeriod(List<_LaborClockEvent> events) {
    final cutoff = DateTime.now().subtract(Duration(days: _period.days));
    return events
        .where(
          (event) => event.eventAt != null && !event.eventAt!.isBefore(cutoff),
        )
        .toList(growable: false);
  }

  List<_LaborClockEvent> _filterEvents(
    List<_LaborClockEvent> events, {
    required String employeeFilter,
    required String projectFilter,
  }) {
    final query = _normalize(_searchCtrl.text);

    final filtered =
        _eventsInPeriod(events).where((event) {
          if (_exceptionsOnly && !event.isGeofenceException) return false;
          if (employeeFilter != _allFilterKey &&
              event.employeeFilterKey != employeeFilter) {
            return false;
          }
          if (projectFilter != _allFilterKey &&
              event.projectFilterKey != projectFilter) {
            return false;
          }
          if (query.isEmpty) return true;

          final searchable = _normalize(
            [
              event.employeeName,
              event.projectName,
              event.geofenceName,
              event.receiptCode,
              event.reason,
            ].join(' '),
          );
          return searchable.contains(query);
        }).toList();

    filtered.sort((a, b) {
      final aDate = a.eventAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.eventAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  Future<void> _exportPdf(_LaborFinanceSummary summary) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);

    try {
      final bytes = await _buildLaborFinancePdf(summary);
      await Printing.layoutPdf(
        name: _laborFinancePdfFileName(summary),
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

  Future<Uint8List> _buildLaborFinancePdf(_LaborFinanceSummary summary) async {
    final pdf = pw.Document();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final generatedAt = DateFormat(
      'dd/MM/yyyy HH:mm',
      'pt_BR',
    ).format(DateTime.now());
    final periodLabel =
        'Periodo: ${_period.label} | Eventos filtrados: ${summary.events.length}';
    final selectedEmployee = _labelForKey(
      _employeeFilter,
      _LaborFilterOptions.fromEvents(
        _eventsInPeriod(_events ?? const []),
      ).employees,
    );
    final selectedProject = _labelForKey(
      _projectFilter,
      _LaborFilterOptions.fromEvents(
        _eventsInPeriod(_events ?? const []),
      ).projects,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build:
            (context) => [
              _pdfHeader(
                title: 'Relatorio de ponto, cerca e custo',
                subtitle: periodLabel,
                generatedAt: generatedAt,
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Filtros: funcionario ${selectedEmployee ?? 'Todos'} | obra ${selectedProject ?? 'Todas'} | ${_exceptionsOnly ? 'somente excecoes de cerca' : 'todos os eventos'}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 16),
              _pdfLaborMetricGrid(summary, currency),
              pw.SizedBox(height: 16),
              _pdfSectionTitle('Funcionarios por tempo trabalhado'),
              _pdfEmployeeLaborTable(summary, currency),
              pw.SizedBox(height: 16),
              _pdfSectionTitle('Obras por custo e excecoes'),
              _pdfProjectLaborTable(summary, currency),
              pw.SizedBox(height: 16),
              _pdfSectionTitle('Eventos fora da cerca / rejeitados'),
              _pdfExceptionLaborTable(summary),
              pw.SizedBox(height: 16),
              _pdfSectionTitle('Diagnostico operacional'),
              _pdfDiagnosticsTable(summary),
              pw.SizedBox(height: 16),
              pw.Text(
                'Metodo: jornadas sao pareadas por entrada/saida no app. O custo estimado distribui o salario proporcional do periodo pelo total de horas reais do funcionario no filtro selecionado.',
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

  String _laborFinancePdfFileName(_LaborFinanceSummary summary) {
    final project =
        summary.projectSummaries.length == 1
            ? _slug(summary.projectSummaries.first.projectName)
            : 'consolidado';
    return 'ponto-custos-${_period.days}d-$project.pdf';
  }

  String? _labelForKey(String key, List<_LaborFilterOption> options) {
    if (key == _allFilterKey) return null;
    for (final option in options) {
      if (option.key == key) return option.label;
    }
    return null;
  }
}

class _LaborFinanceHeader extends StatelessWidget {
  final _LaborFinanceSummary summary;
  final _LaborPeriod period;

  const _LaborFinanceHeader({required this.summary, required this.period});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentGold,
        emphasized: true,
        radius: 22,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: _accentIconSurface(AppColors.accentGold, radius: 16),
            child: const Icon(
              Icons.price_check_rounded,
              color: AppColors.accentGold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ponto e Custos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Analise financeira de horas trabalhadas, custo estimado e excecoes de cerca no app mobile.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _LaborHeaderBadge(
                icon: Icons.calendar_month_rounded,
                label: period.label,
                color: AppColors.accentBlue,
              ),
              _LaborHeaderBadge(
                icon: Icons.payments_outlined,
                label: currency.format(summary.estimatedCost),
                color: AppColors.accentGold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaborFinanceFilters extends StatelessWidget {
  final TextEditingController controller;
  final _LaborPeriod period;
  final _LaborFilterOptions options;
  final String selectedEmployeeKey;
  final String selectedProjectKey;
  final bool exceptionsOnly;
  final bool exportingPdf;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final ValueChanged<_LaborPeriod?> onPeriodChanged;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<String?> onProjectChanged;
  final ValueChanged<bool> onExceptionsOnlyChanged;
  final VoidCallback onExportPdf;

  const _LaborFinanceFilters({
    required this.controller,
    required this.period,
    required this.options,
    required this.selectedEmployeeKey,
    required this.selectedProjectKey,
    required this.exceptionsOnly,
    required this.exportingPdf,
    required this.onQueryChanged,
    required this.onClear,
    required this.onPeriodChanged,
    required this.onEmployeeChanged,
    required this.onProjectChanged,
    required this.onExceptionsOnlyChanged,
    required this.onExportPdf,
  });

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
          final wide = constraints.maxWidth >= 900;
          final search = TextField(
            controller: controller,
            onChanged: onQueryChanged,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar funcionario, obra, recibo ou motivo',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  controller.text.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Limpar busca',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
            ),
          );
          final periodField = DropdownButtonFormField<_LaborPeriod>(
            initialValue: period,
            decoration: const InputDecoration(labelText: 'Periodo'),
            dropdownColor: AppColors.surfaceDark,
            items: _LaborPeriod.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(growable: false),
            onChanged: onPeriodChanged,
          );
          final employeeField = DropdownButtonFormField<String>(
            initialValue: selectedEmployeeKey,
            decoration: const InputDecoration(labelText: 'Funcionario'),
            dropdownColor: AppColors.surfaceDark,
            items: [
              const DropdownMenuItem(
                value: _LaborFinanceAnalysisPageViewState._allFilterKey,
                child: Text('Todos'),
              ),
              ...options.employees.map(
                (item) =>
                    DropdownMenuItem(value: item.key, child: Text(item.label)),
              ),
            ],
            onChanged: onEmployeeChanged,
          );
          final projectField = DropdownButtonFormField<String>(
            initialValue: selectedProjectKey,
            decoration: const InputDecoration(labelText: 'Obra'),
            dropdownColor: AppColors.surfaceDark,
            items: [
              const DropdownMenuItem(
                value: _LaborFinanceAnalysisPageViewState._allFilterKey,
                child: Text('Todas'),
              ),
              ...options.projects.map(
                (item) =>
                    DropdownMenuItem(value: item.key, child: Text(item.label)),
              ),
            ],
            onChanged: onProjectChanged,
          );
          final exceptionsToggle = FilterChip(
            selected: exceptionsOnly,
            showCheckmark: false,
            avatar: Icon(
              exceptionsOnly
                  ? Icons.wrong_location_rounded
                  : Icons.location_searching_rounded,
              size: 18,
            ),
            label: const Text('Somente excecoes'),
            onSelected: onExceptionsOnlyChanged,
          );
          final exportButton = FilledButton.icon(
            onPressed: exportingPdf ? null : onExportPdf,
            icon:
                exportingPdf
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(exportingPdf ? 'Gerando...' : 'PDF'),
          );

          if (wide) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 3, child: search),
                    const SizedBox(width: 12),
                    SizedBox(width: 170, child: periodField),
                    const SizedBox(width: 12),
                    SizedBox(width: 130, child: exportButton),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: employeeField),
                    const SizedBox(width: 12),
                    Expanded(child: projectField),
                    const SizedBox(width: 12),
                    exceptionsToggle,
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 12),
              periodField,
              const SizedBox(height: 12),
              employeeField,
              const SizedBox(height: 12),
              projectField,
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [exceptionsToggle, exportButton],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LaborFinanceMetricGrid extends StatelessWidget {
  final _LaborFinanceSummary summary;

  const _LaborFinanceMetricGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final metrics = [
      _LaborMetric(
        label: 'Horas trabalhadas',
        value: _formatHours(summary.totalMinutes),
        detail: '${summary.shifts.length} jornadas pareadas',
        icon: Icons.schedule_rounded,
        color: AppColors.accentBlue,
      ),
      _LaborMetric(
        label: 'Custo estimado',
        value: currency.format(summary.estimatedCost),
        detail: 'Salario proporcional / horas reais',
        icon: Icons.payments_outlined,
        color: AppColors.accentGold,
      ),
      _LaborMetric(
        label: 'Excecoes de cerca',
        value: summary.exceptionEvents.length.toString(),
        detail: '${summary.rejectedEvents} rejeitadas',
        icon: Icons.wrong_location_rounded,
        color: Colors.orangeAccent,
      ),
      _LaborMetric(
        label: 'Cobertura salarial',
        value: '${(summary.salaryCoverage * 100).toStringAsFixed(0)}%',
        detail: '${summary.missingSalaryEmployees.length} sem salario',
        icon: Icons.verified_user_outlined,
        color:
            summary.salaryCoverage >= 0.8
                ? Colors.greenAccent
                : Colors.orangeAccent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _LaborMetricCard(metric: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _LaborFinanceContentGrid extends StatelessWidget {
  final _LaborFinanceSummary summary;

  const _LaborFinanceContentGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 980) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _LaborEmployeePanel(summary: summary)),
              const SizedBox(width: 14),
              Expanded(child: _LaborProjectPanel(summary: summary)),
            ],
          );
        }
        return Column(
          children: [
            _LaborEmployeePanel(summary: summary),
            const SizedBox(height: 14),
            _LaborProjectPanel(summary: summary),
          ],
        );
      },
    );
  }
}

class _LaborEmployeePanel extends StatelessWidget {
  final _LaborFinanceSummary summary;

  const _LaborEmployeePanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final items = summary.employeeSummaries.take(8).toList(growable: false);
    return _LaborPanel(
      icon: Icons.badge_outlined,
      title: 'Funcionarios por tempo',
      subtitle: 'Ordem crescente de horas trabalhadas no periodo.',
      child:
          items.isEmpty
              ? const _LaborEmptyState(
                text:
                    'Sem jornadas pareadas. Registre entrada e saida no app para calcular horas.',
              )
              : Column(
                children: items
                    .map(
                      (item) => _LaborListRow(
                        leading: item.initials,
                        title: item.employeeName,
                        subtitle:
                            '${_formatHours(item.minutes)} | ${item.shifts} jornada(s)',
                        trailing: currency.format(item.cost),
                        color:
                            item.hasSalary
                                ? AppColors.accentBlue
                                : Colors.orangeAccent,
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }
}

class _LaborProjectPanel extends StatelessWidget {
  final _LaborFinanceSummary summary;

  const _LaborProjectPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final items = summary.projectSummaries.take(8).toList(growable: false);
    return _LaborPanel(
      icon: Icons.business_rounded,
      title: 'Obras por custo',
      subtitle: 'Custo estimado e excecoes de cerca por obra.',
      child:
          items.isEmpty
              ? const _LaborEmptyState(
                text: 'Sem obra com ponto sincronizado neste periodo.',
              )
              : Column(
                children: items
                    .map(
                      (item) => _LaborListRow(
                        leading:
                            item.projectName.isEmpty
                                ? '?'
                                : item.projectName.characters.first
                                    .toUpperCase(),
                        title: item.projectName,
                        subtitle:
                            '${_formatHours(item.minutes)} | ${item.exceptions} excecao(oes)',
                        trailing: currency.format(item.cost),
                        color:
                            item.exceptions == 0
                                ? Colors.greenAccent
                                : AppColors.accentGold,
                      ),
                    )
                    .toList(growable: false),
              ),
    );
  }
}

class _LaborRecentExceptionsPanel extends StatelessWidget {
  final _LaborFinanceSummary summary;

  const _LaborRecentExceptionsPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = summary.exceptionEvents.take(10).toList(growable: false);
    return _LaborPanel(
      icon: Icons.location_off_outlined,
      title: 'Registros com excecao de cerca',
      subtitle: 'Eventos fora da cerca, sem cerca sincronizada ou rejeitados.',
      child:
          items.isEmpty
              ? const _LaborEmptyState(
                text:
                    'Nenhuma excecao de cerca encontrada no periodo filtrado.',
              )
              : Column(
                children: items
                    .map((event) => _LaborExceptionRow(event: event))
                    .toList(growable: false),
              ),
    );
  }
}

class _LaborFinanceDiagnosticsPanel extends StatelessWidget {
  final _LaborFinanceSummary summary;

  const _LaborFinanceDiagnosticsPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final diagnostics = summary.qualityDiagnostics;
    final metrics = [
      _LaborMetric(
        label: 'Entradas abertas',
        value: diagnostics.openEntries.length.toString(),
        detail: 'Sem saida pareada',
        icon: Icons.login_rounded,
        color:
            diagnostics.openEntries.isEmpty
                ? Colors.greenAccent
                : Colors.orangeAccent,
      ),
      _LaborMetric(
        label: 'Saidas sem entrada',
        value: diagnostics.unpairedExitEvents.toString(),
        detail: 'Nao entram no custo',
        icon: Icons.logout_rounded,
        color:
            diagnostics.unpairedExitEvents == 0
                ? Colors.greenAccent
                : Colors.orangeAccent,
      ),
      _LaborMetric(
        label: 'Jornadas invalidas',
        value: diagnostics.invalidIntervals.toString(),
        detail: 'Duracao negativa ou acima de 18h',
        icon: Icons.timer_off_outlined,
        color:
            diagnostics.invalidIntervals == 0
                ? Colors.greenAccent
                : AppColors.accentRed,
      ),
      _LaborMetric(
        label: 'Sem obra',
        value: diagnostics.missingProjectEvents.toString(),
        detail: 'Pontos sem projeto vinculado',
        icon: Icons.business_outlined,
        color:
            diagnostics.missingProjectEvents == 0
                ? Colors.greenAccent
                : Colors.orangeAccent,
      ),
    ];

    return _LaborPanel(
      icon: Icons.health_and_safety_outlined,
      title: 'Qualidade dos registros',
      subtitle: 'Diagnostico do que pode distorcer horas, cerca e custo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!diagnostics.hasSignals) ...[
            const _LaborEmptyState(
              text:
                  'Nenhum problema estrutural encontrado nos pontos filtrados.',
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth >= 980
                      ? 4
                      : constraints.maxWidth >= 540
                      ? 2
                      : 1;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: width,
                        child: _LaborMetricCard(metric: metric),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          if (diagnostics.openEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...diagnostics.openEntries
                .take(3)
                .map(
                  (event) => _LaborListRow(
                    leading:
                        event.employeeName.isEmpty
                            ? '?'
                            : event.employeeName.characters.first.toUpperCase(),
                    title:
                        event.employeeName.isEmpty
                            ? 'Funcionario sem nome'
                            : event.employeeName,
                    subtitle:
                        '${event.projectNameOrFallback} | entrada sem saida',
                    trailing:
                        event.eventAt == null
                            ? 'sem hora'
                            : DateFormat(
                              'dd/MM HH:mm',
                              'pt_BR',
                            ).format(event.eventAt!),
                    color: Colors.orangeAccent,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _LaborExceptionRow extends StatelessWidget {
  static final _dateFormat = DateFormat('dd/MM HH:mm', 'pt_BR');
  final _LaborClockEvent event;

  const _LaborExceptionRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event.isRejected ? AppColors.accentRed : AppColors.accentGold;
    final time =
        event.eventAt == null
            ? 'Sem horario'
            : _dateFormat.format(event.eventAt!);
    final reason = event.reason.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            event.isRejected
                ? Icons.block_rounded
                : Icons.wrong_location_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.employeeName.isEmpty
                      ? 'Funcionario sem nome'
                      : event.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.projectNameOrFallback} | ${event.statusLabel} | $time',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            event.receiptCode.isEmpty
                ? event.punchTypeLabel
                : event.receiptCode,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaborPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _LaborPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentBlue,
        elevated: false,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentGold, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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

class _LaborMetricCard extends StatelessWidget {
  final _LaborMetric metric;

  const _LaborMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppDecorations.cardSurface(
        accent: metric.color,
        emphasized: true,
        radius: 18,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: _accentIconSurface(metric.color, radius: 14),
            child: Icon(metric.icon, color: metric.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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

class _LaborListRow extends StatelessWidget {
  final String leading;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;

  const _LaborListRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              leading,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
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

class _LaborHeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LaborHeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaborFinanceNotice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _LaborFinanceNotice({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaborFilterOption {
  final String key;
  final String label;

  const _LaborFilterOption({required this.key, required this.label});
}

class _LaborFilterOptions {
  final List<_LaborFilterOption> employees;
  final List<_LaborFilterOption> projects;

  const _LaborFilterOptions({required this.employees, required this.projects});

  bool hasEmployee(String key) {
    return key == _LaborFinanceAnalysisPageViewState._allFilterKey ||
        employees.any((option) => option.key == key);
  }

  bool hasProject(String key) {
    return key == _LaborFinanceAnalysisPageViewState._allFilterKey ||
        projects.any((option) => option.key == key);
  }

  factory _LaborFilterOptions.fromEvents(List<_LaborClockEvent> events) {
    final employeeLabels = <String, String>{};
    final projectLabels = <String, String>{};

    for (final event in events) {
      final employeeKey = event.employeeFilterKey;
      if (employeeKey.isNotEmpty) {
        employeeLabels.putIfAbsent(employeeKey, () => event.employeeNameLabel);
      }

      final projectKey = event.projectFilterKey;
      if (projectKey.isNotEmpty) {
        projectLabels.putIfAbsent(
          projectKey,
          () => event.projectNameOrFallback,
        );
      }
    }

    List<_LaborFilterOption> toOptions(Map<String, String> labels) {
      final items =
          labels.entries
              .map(
                (entry) =>
                    _LaborFilterOption(key: entry.key, label: entry.value),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label));
      return items;
    }

    return _LaborFilterOptions(
      employees: toOptions(employeeLabels),
      projects: toOptions(projectLabels),
    );
  }
}

class _LaborEmptyState extends StatelessWidget {
  final String text;

  const _LaborEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaborMetric {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _LaborMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class _LaborQualityDiagnostics {
  final List<_LaborClockEvent> openEntries;
  final int unpairedExitEvents;
  final int invalidIntervals;
  final int missingProjectEvents;

  const _LaborQualityDiagnostics({
    required this.openEntries,
    required this.unpairedExitEvents,
    required this.invalidIntervals,
    required this.missingProjectEvents,
  });

  bool get hasSignals =>
      openEntries.isNotEmpty ||
      unpairedExitEvents > 0 ||
      invalidIntervals > 0 ||
      missingProjectEvents > 0;
}

class _LaborFinanceSummary {
  final List<_LaborClockEvent> events;
  final List<_LaborShift> shifts;
  final List<_EmployeeLaborSummary> employeeSummaries;
  final List<_ProjectLaborSummary> projectSummaries;
  final List<_LaborClockEvent> exceptionEvents;
  final _LaborQualityDiagnostics qualityDiagnostics;
  final Set<String> missingSalaryEmployees;
  final int rejectedEvents;
  final int salaryCoveredMinutes;

  const _LaborFinanceSummary({
    required this.events,
    required this.shifts,
    required this.employeeSummaries,
    required this.projectSummaries,
    required this.exceptionEvents,
    required this.qualityDiagnostics,
    required this.missingSalaryEmployees,
    required this.rejectedEvents,
    required this.salaryCoveredMinutes,
  });

  int get totalMinutes =>
      shifts.fold(0, (total, shift) => total + shift.durationMinutes);
  double get estimatedCost =>
      shifts.fold(0, (total, shift) => total + shift.cost);
  double get salaryCoverage =>
      totalMinutes == 0 ? 0 : salaryCoveredMinutes / totalMinutes;

  static _LaborFinanceSummary build({
    required List<_LaborClockEvent> events,
    required List<EmployeeModel> employees,
    required int periodDays,
  }) {
    final employeesById = {for (final item in employees) item.id: item};
    final employeesByName = {
      for (final item in employees) _normalize(item.name): item,
    };
    final shifts = _buildShifts(
      events: events,
      employeesById: employeesById,
      employeesByName: employeesByName,
      periodDays: periodDays,
    );
    final qualityDiagnostics = _buildQualityDiagnostics(events);
    final employeeBuckets = <String, _EmployeeLaborAccumulator>{};
    final projectBuckets = <String, _ProjectLaborAccumulator>{};
    final missingSalaryEmployees = <String>{};
    var salaryCoveredMinutes = 0;

    for (final shift in shifts) {
      final employeeKey =
          shift.employeeId.isNotEmpty
              ? shift.employeeId
              : _normalize(shift.employeeName);
      final employeeBucket = employeeBuckets.putIfAbsent(
        employeeKey,
        () => _EmployeeLaborAccumulator(
          employeeName:
              shift.employeeName.isEmpty
                  ? 'Funcionario sem nome'
                  : shift.employeeName,
          hasSalary: shift.hasSalary,
        ),
      );
      employeeBucket.minutes += shift.durationMinutes;
      employeeBucket.cost += shift.cost;
      employeeBucket.shifts += 1;
      employeeBucket.hasSalary = employeeBucket.hasSalary || shift.hasSalary;

      final projectKey =
          shift.projectId.isNotEmpty
              ? shift.projectId
              : _normalize(shift.projectName);
      final projectBucket = projectBuckets.putIfAbsent(
        projectKey,
        () => _ProjectLaborAccumulator(
          projectName:
              shift.projectName.isEmpty
                  ? 'Sem obra vinculada'
                  : shift.projectName,
        ),
      );
      projectBucket.minutes += shift.durationMinutes;
      projectBucket.cost += shift.cost;
      projectBucket.shifts += 1;

      if (shift.hasSalary) {
        salaryCoveredMinutes += shift.durationMinutes;
      } else {
        missingSalaryEmployees.add(
          shift.employeeName.isEmpty
              ? 'Funcionario sem nome'
              : shift.employeeName,
        );
      }
    }

    final exceptionEvents = events
        .where(
          (event) =>
              event.isRejected ||
              event.geofenceStatus == 'outside' ||
              event.geofenceStatus == 'unknown',
        )
        .toList(growable: false);
    for (final event in exceptionEvents) {
      final projectKey =
          event.projectId.isNotEmpty
              ? event.projectId
              : _normalize(event.projectName);
      final projectBucket = projectBuckets.putIfAbsent(
        projectKey,
        () => _ProjectLaborAccumulator(
          projectName:
              event.projectName.isEmpty
                  ? 'Sem obra vinculada'
                  : event.projectName,
        ),
      );
      projectBucket.exceptions += 1;
    }

    final employeeSummaries =
        employeeBuckets.values.map((bucket) => bucket.toSummary()).toList()
          ..sort((a, b) {
            final byMinutes = a.minutes.compareTo(b.minutes);
            if (byMinutes != 0) return byMinutes;
            return a.employeeName.compareTo(b.employeeName);
          });

    final projectSummaries =
        projectBuckets.values.map((bucket) => bucket.toSummary()).toList()
          ..sort((a, b) {
            final byCost = b.cost.compareTo(a.cost);
            if (byCost != 0) return byCost;
            return b.exceptions.compareTo(a.exceptions);
          });

    return _LaborFinanceSummary(
      events: events,
      shifts: shifts,
      employeeSummaries: employeeSummaries,
      projectSummaries: projectSummaries,
      exceptionEvents: exceptionEvents,
      qualityDiagnostics: qualityDiagnostics,
      missingSalaryEmployees: missingSalaryEmployees,
      rejectedEvents: events.where((event) => event.isRejected).length,
      salaryCoveredMinutes: salaryCoveredMinutes,
    );
  }

  static _LaborQualityDiagnostics _buildQualityDiagnostics(
    List<_LaborClockEvent> events,
  ) {
    final ordered =
        events
            .where((event) => event.isAcceptedPunch)
            .where((event) => event.isEntry || event.isExit)
            .toList()
          ..sort((a, b) {
            final aDate = a.eventAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.eventAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aDate.compareTo(bDate);
          });

    final openEntries = <String, _LaborClockEvent>{};
    var unpairedExitEvents = 0;
    var invalidIntervals = 0;

    for (final event in ordered) {
      final key = event.shiftKey;
      if (key.isEmpty || event.eventAt == null) continue;

      if (event.isEntry) {
        openEntries[key] = event;
        continue;
      }

      final entry = openEntries.remove(key);
      if (entry == null || entry.eventAt == null) {
        unpairedExitEvents += 1;
        continue;
      }

      final durationMinutes =
          event.eventAt!.difference(entry.eventAt!).inMinutes;
      if (durationMinutes <= 0 || durationMinutes > 18 * 60) {
        invalidIntervals += 1;
      }
    }

    return _LaborQualityDiagnostics(
      openEntries: openEntries.values.toList(growable: false),
      unpairedExitEvents: unpairedExitEvents,
      invalidIntervals: invalidIntervals,
      missingProjectEvents:
          events
              .where((event) => event.isAcceptedPunch)
              .where(
                (event) =>
                    event.projectId.trim().isEmpty &&
                    event.projectName.trim().isEmpty,
              )
              .length,
    );
  }

  static List<_LaborShift> _buildShifts({
    required List<_LaborClockEvent> events,
    required Map<String, EmployeeModel> employeesById,
    required Map<String, EmployeeModel> employeesByName,
    required int periodDays,
  }) {
    final ordered =
        events
            .where((event) => event.isAcceptedPunch)
            .where((event) => event.isEntry || event.isExit)
            .toList()
          ..sort((a, b) {
            final aDate = a.eventAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.eventAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aDate.compareTo(bDate);
          });

    final openEntries = <String, _LaborClockEvent>{};
    final shifts = <_LaborShift>[];

    for (final event in ordered) {
      final key = event.shiftKey;
      if (key.isEmpty || event.eventAt == null) continue;

      if (event.isEntry) {
        openEntries[key] = event;
        continue;
      }

      final entry = openEntries.remove(key);
      if (entry == null || entry.eventAt == null) continue;

      final durationMinutes =
          event.eventAt!.difference(entry.eventAt!).inMinutes;
      if (durationMinutes <= 0 || durationMinutes > 18 * 60) continue;

      final employee =
          employeesById[entry.employeeId] ??
          employeesById[event.employeeId] ??
          employeesByName[_normalize(entry.employeeName)] ??
          employeesByName[_normalize(event.employeeName)];
      final proportionalSalary =
          employee == null || employee.baseSalary <= 0
              ? 0.0
              : employee.baseSalary * (periodDays / 30);
      final employeeName =
          employee?.name ??
          (entry.employeeName.isNotEmpty
              ? entry.employeeName
              : event.employeeName);

      shifts.add(
        _LaborShift(
          employeeId:
              employee?.id ??
              (entry.employeeId.isNotEmpty
                  ? entry.employeeId
                  : event.employeeId),
          employeeName: employeeName,
          projectId:
              entry.projectId.isNotEmpty ? entry.projectId : event.projectId,
          projectName:
              entry.projectName.isNotEmpty
                  ? entry.projectName
                  : event.projectName,
          startAt: entry.eventAt!,
          endAt: event.eventAt!,
          durationMinutes: durationMinutes,
          proportionalSalary: proportionalSalary,
          allocatedCost: 0,
          hasSalary: proportionalSalary > 0,
        ),
      );
    }

    final totalMinutesByEmployee = <String, int>{};
    for (final shift in shifts) {
      if (!shift.hasSalary) continue;
      totalMinutesByEmployee[shift.costAllocationKey] =
          (totalMinutesByEmployee[shift.costAllocationKey] ?? 0) +
          shift.durationMinutes;
    }

    return shifts
        .map((shift) {
          final totalEmployeeMinutes =
              totalMinutesByEmployee[shift.costAllocationKey] ?? 0;
          if (!shift.hasSalary || totalEmployeeMinutes <= 0) {
            return shift;
          }
          return shift.copyWithAllocatedCost(
            shift.proportionalSalary *
                (shift.durationMinutes / totalEmployeeMinutes),
          );
        })
        .toList(growable: false);
  }
}

class _LaborClockEvent {
  final String id;
  final String eventKind;
  final String punchType;
  final String employeeId;
  final String employeeName;
  final String projectId;
  final String projectName;
  final String geofenceName;
  final String geofenceStatus;
  final String reason;
  final String receiptCode;
  final DateTime? eventAt;

  const _LaborClockEvent({
    required this.id,
    required this.eventKind,
    required this.punchType,
    required this.employeeId,
    required this.employeeName,
    required this.projectId,
    required this.projectName,
    required this.geofenceName,
    required this.geofenceStatus,
    required this.reason,
    required this.receiptCode,
    required this.eventAt,
  });

  factory _LaborClockEvent.fromMap(Map<String, dynamic> map) {
    return _LaborClockEvent(
      id: map['id']?.toString() ?? '',
      eventKind: map['eventKind']?.toString() ?? '',
      punchType: map['punchType']?.toString() ?? 'unknown',
      employeeId: map['employeeId']?.toString() ?? '',
      employeeName: map['employeeName']?.toString() ?? '',
      projectId: map['projectId']?.toString() ?? '',
      projectName: map['projectName']?.toString() ?? '',
      geofenceName: map['geofenceName']?.toString() ?? '',
      geofenceStatus: map['geofenceStatus']?.toString() ?? 'unknown',
      reason: map['reason']?.toString() ?? '',
      receiptCode: map['receiptCode']?.toString() ?? '',
      eventAt: DbValue.toDateTime(map['eventAt']),
    );
  }

  bool get isPunchRelated =>
      eventKind == 'punch' || eventKind == 'rejected_punch';
  bool get isAcceptedPunch => eventKind == 'punch';
  bool get isRejected => eventKind == 'rejected_punch';
  bool get isEntry => punchType == 'entry';
  bool get isExit => punchType == 'exit';
  bool get isGeofenceException =>
      isRejected || geofenceStatus == 'outside' || geofenceStatus == 'unknown';
  String get employeeNameLabel =>
      employeeName.trim().isEmpty
          ? 'Funcionario sem nome'
          : employeeName.trim();
  String get projectNameOrFallback =>
      projectName.trim().isEmpty ? 'Sem obra vinculada' : projectName.trim();
  String get employeeFilterKey =>
      employeeId.trim().isNotEmpty
          ? employeeId.trim()
          : _normalize(employeeName);
  String get projectFilterKey =>
      projectId.trim().isNotEmpty ? projectId.trim() : _normalize(projectName);
  String get shiftKey {
    final employeeKey =
        employeeId.trim().isNotEmpty
            ? employeeId.trim()
            : _normalize(employeeName);
    final projectKey =
        projectId.trim().isNotEmpty
            ? projectId.trim()
            : _normalize(projectName);
    if (employeeKey.isEmpty || projectKey.isEmpty) return '';
    return '$employeeKey::$projectKey';
  }

  String get statusLabel {
    if (isRejected) return 'Rejeitado';
    return switch (geofenceStatus) {
      'inside' => 'Dentro',
      'outside' => 'Fora',
      'disabled' => 'Sem exigencia',
      _ => 'Sem cerca',
    };
  }

  String get punchTypeLabel {
    return switch (punchType) {
      'entry' => 'Entrada',
      'exit' => 'Saida',
      'interval_start' => 'Intervalo',
      'interval_end' => 'Retorno',
      _ => 'Ponto',
    };
  }
}

class _LaborShift {
  final String employeeId;
  final String employeeName;
  final String projectId;
  final String projectName;
  final DateTime startAt;
  final DateTime endAt;
  final int durationMinutes;
  final double proportionalSalary;
  final double allocatedCost;
  final bool hasSalary;

  const _LaborShift({
    required this.employeeId,
    required this.employeeName,
    required this.projectId,
    required this.projectName,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.proportionalSalary,
    required this.allocatedCost,
    required this.hasSalary,
  });

  String get costAllocationKey =>
      employeeId.isNotEmpty ? employeeId : _normalize(employeeName);
  double get cost => allocatedCost;

  _LaborShift copyWithAllocatedCost(double value) {
    return _LaborShift(
      employeeId: employeeId,
      employeeName: employeeName,
      projectId: projectId,
      projectName: projectName,
      startAt: startAt,
      endAt: endAt,
      durationMinutes: durationMinutes,
      proportionalSalary: proportionalSalary,
      allocatedCost: value,
      hasSalary: hasSalary,
    );
  }
}

class _EmployeeLaborAccumulator {
  final String employeeName;
  bool hasSalary;
  int minutes = 0;
  double cost = 0;
  int shifts = 0;

  _EmployeeLaborAccumulator({
    required this.employeeName,
    required this.hasSalary,
  });

  _EmployeeLaborSummary toSummary() {
    return _EmployeeLaborSummary(
      employeeName: employeeName,
      minutes: minutes,
      cost: cost,
      shifts: shifts,
      hasSalary: hasSalary,
    );
  }
}

class _EmployeeLaborSummary {
  final String employeeName;
  final int minutes;
  final double cost;
  final int shifts;
  final bool hasSalary;

  const _EmployeeLaborSummary({
    required this.employeeName,
    required this.minutes,
    required this.cost,
    required this.shifts,
    required this.hasSalary,
  });

  String get initials {
    final words = employeeName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }
}

class _ProjectLaborAccumulator {
  final String projectName;
  int minutes = 0;
  double cost = 0;
  int shifts = 0;
  int exceptions = 0;

  _ProjectLaborAccumulator({required this.projectName});

  _ProjectLaborSummary toSummary() {
    return _ProjectLaborSummary(
      projectName: projectName,
      minutes: minutes,
      cost: cost,
      shifts: shifts,
      exceptions: exceptions,
    );
  }
}

class _ProjectLaborSummary {
  final String projectName;
  final int minutes;
  final double cost;
  final int shifts;
  final int exceptions;

  const _ProjectLaborSummary({
    required this.projectName,
    required this.minutes,
    required this.cost,
    required this.shifts,
    required this.exceptions,
  });
}

BoxDecoration _accentIconSurface(Color color, {double radius = 14}) {
  return BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: color.withValues(alpha: 0.28)),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.10),
        blurRadius: 18,
        spreadRadius: -8,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _formatHours(int minutes) {
  final hours = minutes / 60;
  if (hours >= 10) return '${hours.toStringAsFixed(0)} h';
  return '${hours.toStringAsFixed(1)} h';
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàãâä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòõôö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _slug(String value) {
  final normalized = _normalize(value)
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return normalized.isEmpty ? 'sem-identificacao' : normalized;
}

pw.Widget _pdfHeader({
  required String title,
  required String subtitle,
  required String generatedAt,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#11181B'),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Granith',
          style: pw.TextStyle(
            color: PdfColor.fromHex('#E3B84A'),
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          title,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
        ),
        pw.Text(
          'Gerado em $generatedAt',
          style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 9),
        ),
      ],
    ),
  );
}

pw.Widget _pdfLaborMetricGrid(
  _LaborFinanceSummary summary,
  NumberFormat currency,
) {
  final diagnostics = summary.qualityDiagnostics;
  return pw.Row(
    children: [
      _pdfMetric('Horas', _formatHours(summary.totalMinutes)),
      pw.SizedBox(width: 8),
      _pdfMetric('Custo', currency.format(summary.estimatedCost)),
      pw.SizedBox(width: 8),
      _pdfMetric('Excecoes', summary.exceptionEvents.length.toString()),
      pw.SizedBox(width: 8),
      _pdfMetric(
        'Pendencias',
        (diagnostics.openEntries.length +
                diagnostics.unpairedExitEvents +
                diagnostics.invalidIntervals)
            .toString(),
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
              fontSize: 13,
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
        color: PdfColor.fromHex('#11181B'),
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _pdfEmployeeLaborTable(
  _LaborFinanceSummary summary,
  NumberFormat currency,
) {
  final rows = summary.employeeSummaries
      .take(24)
      .map(
        (item) => [
          item.employeeName,
          _formatHours(item.minutes),
          item.shifts.toString(),
          currency.format(item.cost),
          item.hasSalary ? 'Sim' : 'Nao',
        ],
      )
      .toList(growable: false);
  if (rows.isEmpty) return _pdfEmpty('Sem jornadas pareadas no filtro.');
  return _pdfTable(
    headers: const ['Funcionario', 'Horas', 'Jornadas', 'Custo', 'Salario'],
    rows: rows,
  );
}

pw.Widget _pdfProjectLaborTable(
  _LaborFinanceSummary summary,
  NumberFormat currency,
) {
  final rows = summary.projectSummaries
      .take(24)
      .map(
        (item) => [
          item.projectName,
          _formatHours(item.minutes),
          item.shifts.toString(),
          item.exceptions.toString(),
          currency.format(item.cost),
        ],
      )
      .toList(growable: false);
  if (rows.isEmpty) return _pdfEmpty('Sem obra com ponto no filtro.');
  return _pdfTable(
    headers: const ['Obra', 'Horas', 'Jornadas', 'Excecoes', 'Custo'],
    rows: rows,
  );
}

pw.Widget _pdfExceptionLaborTable(_LaborFinanceSummary summary) {
  final dateFormat = DateFormat('dd/MM HH:mm', 'pt_BR');
  final rows = summary.exceptionEvents
      .take(30)
      .map(
        (event) => [
          event.eventAt == null
              ? 'Sem horario'
              : dateFormat.format(event.eventAt!),
          event.employeeNameLabel,
          event.projectNameOrFallback,
          event.statusLabel,
          event.reason.trim().isEmpty
              ? event.punchTypeLabel
              : event.reason.trim(),
        ],
      )
      .toList(growable: false);
  if (rows.isEmpty) return _pdfEmpty('Sem eventos fora da cerca no filtro.');
  return _pdfTable(
    headers: const ['Data', 'Funcionario', 'Obra', 'Status', 'Motivo'],
    rows: rows,
  );
}

pw.Widget _pdfDiagnosticsTable(_LaborFinanceSummary summary) {
  final diagnostics = summary.qualityDiagnostics;
  return _pdfTable(
    headers: const ['Indicador', 'Valor', 'Impacto'],
    rows: [
      [
        'Entradas abertas',
        diagnostics.openEntries.length.toString(),
        'Sem saida pareada; nao entra no custo.',
      ],
      [
        'Saidas sem entrada',
        diagnostics.unpairedExitEvents.toString(),
        'Evento isolado; exige revisao de ponto.',
      ],
      [
        'Jornadas invalidas',
        diagnostics.invalidIntervals.toString(),
        'Duracao negativa ou acima de 18h.',
      ],
      [
        'Pontos sem obra',
        diagnostics.missingProjectEvents.toString(),
        'Nao permite rateio confiavel por obra.',
      ],
      [
        'Funcionarios sem salario',
        summary.missingSalaryEmployees.length.toString(),
        'Horas aparecem, mas custo fica incompleto.',
      ],
    ],
  );
}

pw.Widget _pdfTable({
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final columnCount = headers.length;
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: {
      for (var i = 0; i < columnCount; i++) i: const pw.FlexColumnWidth(),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: headers
            .map((header) => _pdfCell(header, bold: true))
            .toList(growable: false),
      ),
      ...rows.map(
        (row) => pw.TableRow(
          children: row.take(columnCount).map(_pdfCell).toList(growable: false),
        ),
      ),
    ],
  );
}

pw.Widget _pdfCell(String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    child: pw.Text(
      value,
      maxLines: 3,
      overflow: pw.TextOverflow.clip,
      style: pw.TextStyle(
        color: PdfColors.grey900,
        fontSize: 8,
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
