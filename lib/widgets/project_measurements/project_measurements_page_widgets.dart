import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/controllers/projects_controller.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/project_measurement_service.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/project_measurements/project_measurement_form_dialog.dart';
import 'package:provider/provider.dart';

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
  String? _selectedProjectId;
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
    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      return _measurements;
    }
    return _measurements
        .where((measurement) => measurement.projectId == _selectedProjectId)
        .toList();
  }

  Map<String, ProjectMeasurement> get _latestMeasurementByProject {
    final latest = <String, ProjectMeasurement>{};
    for (final measurement in _measurements) {
      latest[measurement.projectId] = measurement;
    }
    return latest;
  }

  double get _totalMeasuredAmount => _filteredMeasurements.fold<double>(
    0,
    (sum, measurement) => sum + measurement.netAmount,
  );

  double get _averageMeasuredProgress {
    final latest =
        _selectedProjectId == null || _selectedProjectId!.isEmpty
            ? _latestMeasurementByProject.values.toList()
            : _filteredMeasurements.isEmpty
            ? const <ProjectMeasurement>[]
            : <ProjectMeasurement>[_filteredMeasurements.last];

    if (latest.isEmpty) {
      return 0;
    }

    final total = latest.fold<double>(
      0,
      (sum, measurement) => sum + measurement.accumulatedPercentage,
    );
    return total / latest.length;
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

      final selectedExists =
          _selectedProjectId != null &&
          projects.any((project) => project.id == _selectedProjectId);

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = projects;
        _measurements = measurements;
        _errorMessage = null;
        _selectedProjectId = selectedExists ? _selectedProjectId : null;
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
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildSummaryStrip(),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...[
                      _buildMessageCard(
                        title: 'Falha ao consultar medicoes',
                        message: _errorMessage!,
                        color: AppColors.accentRed,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_filteredMeasurements.isEmpty)
                      _buildMessageCard(
                        title: 'Nenhuma medicao registrada',
                        message:
                            _selectedProjectId == null
                                ? 'Cadastre a primeira medicao para transformar valor executado em progresso estimado da obra.'
                                : 'Este projeto ainda nao recebeu medicoes. Registre a primeira para alimentar o andamento estimado.',
                        color: AppColors.accentGold,
                      )
                    else
                      ..._filteredMeasurements.map(
                        (measurement) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MeasurementCard(
                            measurement: measurement,
                            onEdit: () => _openMeasurementDialog(measurement),
                            onDelete: () => _deleteMeasurement(measurement),
                          ),
                        ),
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

  Widget _buildHeader(BuildContext context) {
    final filterItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('Todos os projetos'),
      ),
      ..._projects.map(
        (project) => DropdownMenuItem<String>(
          value: project.id,
          child: Text(project.name),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.accentBlue.withValues(alpha: 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.24)),
        boxShadow: AppColors.glowShadows(AppColors.accentBlue),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'MEDICOES DE OBRA',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Atribua andamento estimado a partir do valor medido',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Cada medicao atualiza o percentual acumulado da obra usando o valor contratado do projeto como base de referencia.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.55),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment:
                isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isWide ? 300 : double.infinity,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedProjectId ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Filtrar projeto',
                  ),
                  items: filterItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId =
                          value == null || value.isEmpty ? null : value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _loadData(showLoader: false),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [intro, const SizedBox(height: 18), actions],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryStrip() {
    final impactedProjects = _latestMeasurementByProject.length;
    final filteredProjects =
        _selectedProjectId == null || _selectedProjectId!.isEmpty
            ? impactedProjects
            : (_filteredMeasurements.isEmpty ? 0 : 1);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Medicoes',
          value: _filteredMeasurements.length.toString(),
          subtitle: 'registros no filtro atual',
          color: AppColors.accentBlue,
        ),
        _SummaryCard(
          title: 'Projetos impactados',
          value: filteredProjects.toString(),
          subtitle: 'obras com progresso por medicao',
          color: AppColors.accentGold,
        ),
        _SummaryCard(
          title: 'Total medido',
          value: NumberFormat.currency(
            locale: 'pt_BR',
            symbol: 'R\$ ',
          ).format(_totalMeasuredAmount),
          subtitle: 'valor liquido registrado',
          color: AppColors.accentGreen,
        ),
        _SummaryCard(
          title: 'Avanco medio',
          value: '${_averageMeasuredProgress.toStringAsFixed(1)}%',
          subtitle: 'percentual acumulado estimado',
          color: AppColors.auraCyan,
        ),
      ],
    );
  }

  Widget _buildMessageCard({
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: measurement.status.color.withValues(alpha: 0.24),
        ),
        boxShadow: AppColors.glowShadows(measurement.status.color),
      ),
      child: Column(
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
                      spacing: 10,
                      runSpacing: 10,
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
                    const SizedBox(height: 14),
                    Text(
                      measurement.title.isEmpty
                          ? '${measurement.sequence}a medicao'
                          : measurement.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${measurement.projectClient} • ${DateFormat('dd/MM/yyyy').format(measurement.measurementDate)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.surfaceDark,
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: AppColors.surfaceDark.withValues(
                      alpha: 0.70,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      measurement.status.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${measurement.clampedAccumulatedPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: measurement.status.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
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
                label: 'Saldo do contrato',
                value: money.format(measurement.contractBalance),
              ),
            ],
          ),
          if (measurement.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              measurement.notes,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
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
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        boxShadow: AppColors.glowShadows(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: resolvedColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color == null ? AppColors.textPrimary : resolvedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
