import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/project_measurement_service.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/project_measurements/project_measurement_form_dialog.dart';
import 'package:provider/provider.dart';

enum _MeasurementStatusFilter { all, pending, approved, paid }

enum _MeasurementSort { recent, oldest, valueDesc, progressDesc, project }

class ProjectMeasurementsPageView extends StatefulWidget {
  const ProjectMeasurementsPageView({
    super.key,
    ServiceProjetos? projectService,
    ProjectMeasurementService? measurementService,
  }) : _projectService = projectService,
       _measurementService = measurementService;

  final ServiceProjetos? _projectService;
  final ProjectMeasurementService? _measurementService;

  @override
  State<ProjectMeasurementsPageView> createState() =>
      _ProjectMeasurementsPageViewState();
}

class _ProjectMeasurementsPageViewState
    extends State<ProjectMeasurementsPageView> {
  late final ServiceProjetos _projectService;
  late final ProjectMeasurementService _measurementService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  final TextEditingController _projectSearchController =
      TextEditingController();
  String _projectSearchQuery = '';
  _MeasurementStatusFilter _statusFilter = _MeasurementStatusFilter.all;
  _MeasurementSort _sort = _MeasurementSort.recent;
  List<Project> _projects = const <Project>[];
  List<ProjectMeasurement> _measurements = const <ProjectMeasurement>[];

  @override
  void initState() {
    super.initState();
    _projectService = widget._projectService ?? ServiceProjetos();
    _measurementService =
        widget._measurementService ?? ProjectMeasurementService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  List<ProjectMeasurement> get _filteredMeasurements {
    final query = _projectSearchQuery.trim().toLowerCase();
    final projectsById = <String, Project>{
      for (final project in _projects) project.id: project,
    };

    final filtered =
        _measurements.where((measurement) {
          final matchesStatus = switch (_statusFilter) {
            _MeasurementStatusFilter.all => true,
            _MeasurementStatusFilter.pending =>
              measurement.status == ProjectMeasurementStatus.pending,
            _MeasurementStatusFilter.approved =>
              measurement.status == ProjectMeasurementStatus.approved,
            _MeasurementStatusFilter.paid =>
              measurement.status == ProjectMeasurementStatus.paid,
          };
          if (!matchesStatus) return false;

          if (query.isEmpty) return true;
          return _measurementMatchesProjectSearch(
            measurement,
            projectsById[measurement.projectId],
            query,
          );
        }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        _MeasurementSort.recent => _compareMeasurementRecency(b, a),
        _MeasurementSort.oldest => _compareMeasurementRecency(a, b),
        _MeasurementSort.valueDesc => b.netAmount.compareTo(a.netAmount),
        _MeasurementSort.progressDesc => b.accumulatedPercentage.compareTo(
          a.accumulatedPercentage,
        ),
        _MeasurementSort.project => a.projectName.compareTo(b.projectName),
      };
    });

    return filtered;
  }

  Map<String, ProjectMeasurement> get _latestMeasurementByProject {
    return _latestByProject(_measurements);
  }

  Map<String, ProjectMeasurement> get _latestFilteredMeasurementByProject {
    return _latestByProject(_filteredMeasurements);
  }

  bool _measurementMatchesProjectSearch(
    ProjectMeasurement measurement,
    Project? project,
    String query,
  ) {
    final fields = <String>[
      measurement.projectName,
      measurement.projectClient,
      project?.name ?? '',
      project?.client ?? '',
      project?.location ?? '',
      project?.coordinatorName ?? '',
      project?.tags.join(' ') ?? '',
    ];

    return fields.any((field) => field.toLowerCase().contains(query));
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        _projectService.getProjects(),
        _measurementService.getMeasurements(),
      ]);

      final projects = List<Project>.from(results[0] as List<Project>)
        ..sort((a, b) => a.name.compareTo(b.name));
      final measurements = List<ProjectMeasurement>.from(
        results[1] as List<ProjectMeasurement>,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
        _measurements = measurements;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Nao foi possivel carregar as medicoes das obras.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _projectSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final filteredMeasurements = _filteredMeasurements;
    final summary = _MeasurementSummary.from(
      filtered: filteredMeasurements,
      all: _measurements,
      latestByProject:
          _projectSearchQuery.trim().isEmpty &&
                  _statusFilter == _MeasurementStatusFilter.all
              ? _latestMeasurementByProject
              : _latestFilteredMeasurementByProject,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RefreshIndicator(
        onRefresh: () => _loadData(showLoader: false),
        color: AppColors.accentBlue,
        backgroundColor: AppColors.surfaceDark,
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                )
                : ListView(
                  padding: ResponsiveLayout.pagePadding(
                    width,
                  ).add(const EdgeInsets.only(bottom: 68)),
                  children: [
                    _buildHeader(context, summary),
                    const SizedBox(height: 12),
                    _buildToolbar(filteredMeasurements.length),
                    const SizedBox(height: 12),
                    _buildSummaryStrip(summary),
                    const SizedBox(height: 14),
                    if (_errorMessage != null) ...[
                      _buildMessageCard(
                        title: 'Falha ao consultar medicoes',
                        message: _errorMessage!,
                        color: AppColors.accentRed,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (filteredMeasurements.isEmpty)
                      _buildMessageCard(
                        title: 'Nenhuma medicao registrada',
                        message:
                            _projectSearchQuery.trim().isEmpty &&
                                    _statusFilter ==
                                        _MeasurementStatusFilter.all
                                ? 'Cadastre a primeira medicao para transformar valor executado em progresso estimado da obra.'
                                : 'Nenhuma medicao foi encontrada para os filtros atuais.',
                        color: AppColors.accentGold,
                      )
                    else
                      _MeasurementsBoard(
                        measurements: filteredMeasurements,
                        onEdit: _openMeasurementDialog,
                        onDelete: _deleteMeasurement,
                      ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _projects.isEmpty || _isSaving ? null : _openMeasurementDialog,
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textPrimary,
        icon:
            _isSaving
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textPrimary,
                    ),
                  ),
                )
                : const Icon(Icons.add_chart_rounded),
        label: Text(_isSaving ? 'Salvando...' : 'Nova medicao'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _MeasurementSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentBlue,
        radius: 14,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isWide ? 48 : 42,
                    height: isWide ? 48 : 42,
                    decoration: AppDecorations.iconTile(AppColors.accentBlue),
                    child: const Icon(
                      Icons.query_stats_rounded,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEDICOES DE OBRA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Evolucao medida dos projetos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.totalCount} medicao${summary.totalCount == 1 ? '' : 'es'} registradas em ${summary.projectCount} projeto${summary.projectCount == 1 ? '' : 's'}.',
                maxLines: isWide ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final badges = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: isWide ? WrapAlignment.end : WrapAlignment.start,
            children: [
              _HeaderBadge(
                icon: Icons.payments_outlined,
                label:
                    '${summary.filteredCount} no filtro de ${summary.totalCount}',
                color: AppColors.accentGreen,
              ),
              _HeaderBadge(
                icon: Icons.verified_rounded,
                label:
                    '${summary.pendingCount} pendentes, ${summary.approvedCount + summary.paidCount} liberadas',
                color:
                    summary.pendingCount == 0
                        ? AppColors.accentBlue
                        : AppColors.accentGold,
              ),
              _HeaderBadge(
                icon: Icons.trending_up_rounded,
                label: '${summary.averageProgress.toStringAsFixed(1)}% medio',
                color: AppColors.auraCyan,
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [intro, const SizedBox(height: 12), badges],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 18),
              Flexible(child: badges),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(int resultCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.cardInnerSurface(
        accent: AppColors.accentBlue,
        radius: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          final search = _ProjectMeasurementSearchField(
            controller: _projectSearchController,
            query: _projectSearchQuery,
            projectCount: _projects.length,
            resultCount: resultCount,
            onChanged: (value) {
              setState(() {
                _projectSearchQuery = value;
              });
            },
            onClear: () {
              _projectSearchController.clear();
              setState(() {
                _projectSearchQuery = '';
              });
            },
          );
          final statusField = DropdownButtonFormField<_MeasurementStatusFilter>(
            initialValue: _statusFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Status',
            ),
            items:
                _MeasurementStatusFilter.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_measurementStatusFilterLabel(option)),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _statusFilter = value);
              }
            },
          );
          final sortField = DropdownButtonFormField<_MeasurementSort>(
            initialValue: _sort,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Ordenar',
            ),
            items:
                _MeasurementSort.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_measurementSortLabel(option)),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _sort = value);
              }
            },
          );
          final refreshButton = Tooltip(
            message: 'Atualizar',
            child: IconButton.filledTonal(
              onPressed: _isSaving ? null : () => _loadData(showLoader: false),
              icon: const Icon(Icons.refresh_rounded),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: statusField),
                    const SizedBox(width: 8),
                    Expanded(child: sortField),
                    const SizedBox(width: 8),
                    refreshButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 10),
              SizedBox(width: 180, child: statusField),
              const SizedBox(width: 10),
              SizedBox(width: 190, child: sortField),
              const SizedBox(width: 8),
              refreshButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryStrip(_MeasurementSummary summary) {
    final cards = [
      _SummaryCard(
        title: 'Medicoes',
        value: summary.filteredCount.toString(),
        subtitle: 'registros no filtro atual',
        color: AppColors.accentBlue,
      ),
      _SummaryCard(
        title: 'Projetos impactados',
        value: summary.filteredProjectCount.toString(),
        subtitle: 'obras no filtro atual',
        color: AppColors.accentGold,
      ),
      _SummaryCard(
        title: 'Total medido',
        value: NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$ ',
        ).format(summary.filteredNetAmount),
        subtitle: 'valor liquido registrado',
        color: AppColors.accentGreen,
      ),
      _SummaryCard(
        title: 'Avanco medio',
        value: '${summary.averageProgress.toStringAsFixed(1)}%',
        subtitle: 'percentual acumulado estimado',
        color: AppColors.auraCyan,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 880) {
          return SizedBox(
            height: 94,
            child: Row(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(child: cards[index]),
                ],
              ],
            ),
          );
        }

        return SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder:
                (context, index) => SizedBox(width: 230, child: cards[index]),
          ),
        );
      },
    );
  }

  Widget _buildMessageCard({
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardSurface(
        accent: color,
        elevated: false,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _openMeasurementDialog([ProjectMeasurement? measurement]) async {
    final draft = await showDialog<ProjectMeasurement>(
      context: context,
      builder:
          (context) => ProjectMeasurementFormDialog(
            projects: _projects,
            measurement: measurement,
          ),
    );

    if (draft == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (measurement == null) {
        await _measurementService.addMeasurement(draft);
      } else {
        await _measurementService.updateMeasurement(draft);
      }

      await _loadData(showLoader: false);
      if (!mounted) {
        return;
      }

      await context.read<ProjectsController>().loadProjects(forceRefresh: true);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            measurement == null
                ? 'Medicao registrada com sucesso.'
                : 'Medicao atualizada com sucesso.',
          ),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar medicao: $error'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteMeasurement(ProjectMeasurement measurement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Excluir medicao',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Deseja excluir a medicao "${measurement.title.isEmpty ? '${measurement.sequence}a medicao' : measurement.title}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm != true) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _measurementService.deleteMeasurement(measurement.id);
      await _loadData(showLoader: false);
      if (!mounted) {
        return;
      }

      await context.read<ProjectsController>().loadProjects(forceRefresh: true);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicao excluida com sucesso.'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir medicao: $error'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _MeasurementSummary {
  final int totalCount;
  final int filteredCount;
  final int projectCount;
  final int filteredProjectCount;
  final int pendingCount;
  final int approvedCount;
  final int paidCount;
  final double filteredNetAmount;
  final double averageProgress;

  const _MeasurementSummary({
    required this.totalCount,
    required this.filteredCount,
    required this.projectCount,
    required this.filteredProjectCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.paidCount,
    required this.filteredNetAmount,
    required this.averageProgress,
  });

  factory _MeasurementSummary.from({
    required List<ProjectMeasurement> filtered,
    required List<ProjectMeasurement> all,
    required Map<String, ProjectMeasurement> latestByProject,
  }) {
    final averageProgress =
        latestByProject.isEmpty
            ? 0.0
            : latestByProject.values.fold<double>(
                  0,
                  (sum, measurement) => sum + measurement.accumulatedPercentage,
                ) /
                latestByProject.length;

    return _MeasurementSummary(
      totalCount: all.length,
      filteredCount: filtered.length,
      projectCount: _projectCount(all),
      filteredProjectCount: _projectCount(filtered),
      pendingCount:
          filtered
              .where((item) => item.status == ProjectMeasurementStatus.pending)
              .length,
      approvedCount:
          filtered
              .where((item) => item.status == ProjectMeasurementStatus.approved)
              .length,
      paidCount:
          filtered
              .where((item) => item.status == ProjectMeasurementStatus.paid)
              .length,
      filteredNetAmount: filtered.fold<double>(
        0,
        (sum, item) => sum + item.netAmount,
      ),
      averageProgress: averageProgress,
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMeasurementSearchField extends StatelessWidget {
  const _ProjectMeasurementSearchField({
    required this.controller,
    required this.query,
    required this.projectCount,
    required this.resultCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final int projectCount;
  final int resultCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Buscar projeto',
        hintText: 'Nome, cliente ou local',
        helperText:
            hasQuery
                ? '$resultCount medicoes encontradas'
                : '$projectCount projetos carregados',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon:
            hasQuery
                ? IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                )
                : null,
        filled: true,
        fillColor: AppColors.surfaceDark.withValues(alpha: 0.62),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
        ),
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MeasurementsBoard extends StatelessWidget {
  const _MeasurementsBoard({
    required this.measurements,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProjectMeasurement> measurements;
  final ValueChanged<ProjectMeasurement> onEdit;
  final ValueChanged<ProjectMeasurement> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 1120;
        if (!useTwoColumns) {
          return Column(
            children: [
              for (var index = 0; index < measurements.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                _MeasurementCard(
                  measurement: measurements[index],
                  onEdit: () => onEdit(measurements[index]),
                  onDelete: () => onDelete(measurements[index]),
                ),
              ],
            ],
          );
        }

        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final measurement in measurements)
              SizedBox(
                width: cardWidth,
                child: _MeasurementCard(
                  measurement: measurement,
                  onEdit: () => onEdit(measurement),
                  onDelete: () => onDelete(measurement),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    required this.measurement,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectMeasurement measurement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    final progress = (measurement.clampedAccumulatedPercentage / 100).clamp(
      0.0,
      1.0,
    );
    final title =
        measurement.title.isEmpty
            ? '${measurement.sequence}a medicao'
            : measurement.title;
    final measurementDate = DateFormat(
      'dd/MM/yyyy',
    ).format(measurement.measurementDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: measurement.status.color,
        emphasized: measurement.status != ProjectMeasurementStatus.paid,
        radius: 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final metrics = [
            _MetricTile(
              label: 'Valor bruto',
              value: money.format(measurement.grossAmount),
            ),
            _MetricTile(
              label: 'Liquido',
              value: money.format(measurement.netAmount),
            ),
            _MetricTile(
              label: 'Acumulado',
              value: money.format(measurement.accumulatedGrossAmount),
            ),
            _MetricTile(
              label: 'Saldo',
              value: money.format(measurement.contractBalance),
            ),
          ];

          final progressPanel = Container(
            padding: const EdgeInsets.all(12),
            decoration: AppDecorations.cardInnerSurface(
              accent: measurement.status.color,
              radius: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Progresso acumulado',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${measurement.clampedAccumulatedPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: measurement.status.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: AppColors.surfaceDark.withValues(
                      alpha: 0.70,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      measurement.status.color,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${measurement.measurementPercentage.toStringAsFixed(1)}% nesta medicao',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              icon: Icons.business_rounded,
                              label: measurement.projectName,
                            ),
                            _InfoPill(
                              icon: Icons.flag_rounded,
                              label: measurement.status.displayName,
                              color: measurement.status.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${measurement.projectClient} - $measurementDate',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Acoes',
                    color: AppColors.surfaceDark,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (compact)
                progressPanel
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: progressPanel),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _MetricTile(
                        label: 'Valor liquido',
                        value: money.format(measurement.netAmount),
                        emphasized: true,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    metrics
                        .map(
                          (metric) => SizedBox(
                            width:
                                compact
                                    ? (constraints.maxWidth - 8) / 2
                                    : (constraints.maxWidth - 24) / 4,
                            child: metric,
                          ),
                        )
                        .toList(),
              ),
              if (measurement.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: AppDecorations.cardInnerSurface(radius: 8),
                  child: Text(
                    measurement.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 94,
      padding: const EdgeInsets.all(11),
      decoration: AppDecorations.statCardSurface(color, radius: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
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
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: AppDecorations.cardInnerSurface(
        accent: emphasized ? AppColors.accentGreen : null,
        radius: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasized ? AppColors.accentGreen : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: emphasized ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.textSecondary;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: resolvedColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color == null ? AppColors.textPrimary : resolvedColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int _projectCount(Iterable<ProjectMeasurement> measurements) {
  return measurements.map((item) => item.projectId).toSet().length;
}

Map<String, ProjectMeasurement> _latestByProject(
  Iterable<ProjectMeasurement> measurements,
) {
  final latest = <String, ProjectMeasurement>{};
  for (final measurement in measurements) {
    final current = latest[measurement.projectId];
    if (current == null ||
        _compareMeasurementRecency(measurement, current) > 0) {
      latest[measurement.projectId] = measurement;
    }
  }
  return latest;
}

int _compareMeasurementRecency(ProjectMeasurement a, ProjectMeasurement b) {
  final date = a.measurementDate.compareTo(b.measurementDate);
  if (date != 0) return date;

  final sequence = a.sequence.compareTo(b.sequence);
  if (sequence != 0) return sequence;

  final createdA = a.createdAt;
  final createdB = b.createdAt;
  if (createdA != null && createdB != null) {
    return createdA.compareTo(createdB);
  }
  if (createdA != null) return 1;
  if (createdB != null) return -1;
  return a.id.compareTo(b.id);
}

String _measurementStatusFilterLabel(_MeasurementStatusFilter filter) {
  return switch (filter) {
    _MeasurementStatusFilter.all => 'Todos',
    _MeasurementStatusFilter.pending => 'Pendentes',
    _MeasurementStatusFilter.approved => 'Aprovadas',
    _MeasurementStatusFilter.paid => 'Pagas',
  };
}

String _measurementSortLabel(_MeasurementSort sort) {
  return switch (sort) {
    _MeasurementSort.recent => 'Mais recentes',
    _MeasurementSort.oldest => 'Mais antigas',
    _MeasurementSort.valueDesc => 'Maior valor',
    _MeasurementSort.progressDesc => 'Maior avanco',
    _MeasurementSort.project => 'Projeto',
  };
}
