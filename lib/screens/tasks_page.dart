import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/granith_task.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/granith_task_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/components/GranitCard.dart';
import 'package:project_granith/widgets/components/GranitSectionHeader.dart';
import 'package:project_granith/widgets/components/GranitStatCard.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _service = GranithTaskService();
  late final Stream<List<GranithTask>> _tasksStream;
  late final Future<_TaskResources> _resources;
  String _query = '';
  GranithTaskStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tasksStream = _service.watchTasks();
    _resources = _loadResources();
  }

  Future<_TaskResources> _loadResources() async {
    final results = await Future.wait<dynamic>([
      _service.getActiveEmployees(),
      _service.getProjects(),
      _service.getBudgets(),
      _service.getCurrentEmployee(),
    ]);
    return _TaskResources(
      employees: results[0] as List<EmployeeModel>,
      projects: results[1] as List<Project>,
      budgets: results[2] as List<Budget>,
      currentEmployee: results[3] as EmployeeModel?,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GranithTask>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(
            message: _friendlyError(snapshot.error!),
            onRetry: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        final visible = _filter(tasks);
        final pending =
            tasks
                .where(
                  (task) =>
                      task.status == GranithTaskStatus.pending ||
                      task.status == GranithTaskStatus.paused,
                )
                .length;
        final urgent =
            tasks
                .where(
                  (task) =>
                      !task.isClosed &&
                      task.priority == GranithTaskPriority.urgent,
                )
                .length;
        final completed =
            tasks
                .where((task) => task.status == GranithTaskStatus.completed)
                .length;

        return FutureBuilder<_TaskResources>(
          future: _resources,
          builder: (context, resourcesSnapshot) {
            final resources = resourcesSnapshot.data;
            final currentEmployeeId = resources?.currentEmployee?.id;
            final active =
                tasks
                    .where(
                      (task) =>
                          task.isTimerRunning &&
                          task.assigneeId == currentEmployeeId,
                    )
                    .firstOrNull;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GranitSectionHeader(
                    icon: Icons.task_alt_rounded,
                    title: 'Tarefas',
                    subtitle:
                        'Responsaveis, prioridades e tempo executado em uma unica operacao.',
                    iconColor: AppColors.accentBlue,
                    trailing: FilledButton.icon(
                      onPressed:
                          resources == null ||
                                  resources.currentEmployee == null ||
                                  !resources
                                      .currentEmployee!
                                      .role
                                      .isSupervisorOrAbove
                              ? null
                              : () => _openEditor(resources),
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('Nova tarefa'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (active != null) ...[
                    _ActiveTaskPanel(
                      task: active,
                      busy: _busy,
                      onPause: () => _setTimer(active, 'pause'),
                      onComplete: () => _setTimer(active, 'complete'),
                    ),
                    const SizedBox(height: 18),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          constraints.maxWidth >= 900
                              ? (constraints.maxWidth - 36) / 4
                              : constraints.maxWidth >= 520
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: GranitStatCard(
                              label: 'TAREFAS VISIVEIS',
                              value: '${tasks.length}',
                              delta: 'sob sua responsabilidade',
                              deltaPositive: true,
                              accent: AppColors.accentBlue,
                              icon: Icons.assignment_outlined,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: GranitStatCard(
                              label: 'AGUARDANDO ACAO',
                              value: '$pending',
                              delta: 'pendentes ou pausadas',
                              deltaPositive: pending == 0,
                              accent: AppColors.accentGold,
                              icon: Icons.hourglass_top_rounded,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: GranitStatCard(
                              label: 'URGENTES',
                              value: '$urgent',
                              delta:
                                  urgent == 0
                                      ? 'nenhuma critica'
                                      : 'exigem atencao',
                              deltaPositive: urgent == 0,
                              accent: AppColors.accentRed,
                              icon: Icons.priority_high_rounded,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: GranitStatCard(
                              label: 'CONCLUIDAS',
                              value: '$completed',
                              delta: 'historico preservado',
                              deltaPositive: true,
                              accent: AppColors.accentGreen,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  GranitCard(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 300,
                          child: TextField(
                            onChanged:
                                (value) => setState(() => _query = value),
                            decoration: const InputDecoration(
                              hintText: 'Buscar tarefa, pessoa, obra...',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                          ),
                        ),
                        _FilterChip(
                          label: 'Todas',
                          selected: _status == null,
                          onTap: () => setState(() => _status = null),
                        ),
                        for (final status in GranithTaskStatus.values)
                          _FilterChip(
                            label: status.label,
                            selected: _status == status,
                            onTap: () => setState(() => _status = status),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (visible.isEmpty)
                    const _EmptyState()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth =
                            constraints.maxWidth >= 1160
                                ? (constraints.maxWidth - 14) / 2
                                : constraints.maxWidth;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final task in visible)
                              SizedBox(
                                width: cardWidth,
                                child: _TaskCard(
                                  task: task,
                                  canControl:
                                      resources?.currentEmployee?.id ==
                                      task.assigneeId,
                                  canManage:
                                      resources?.currentEmployee?.id ==
                                          task.supervisorId ||
                                      (resources
                                              ?.currentEmployee
                                              ?.role
                                              .isManager ??
                                          false),
                                  busy: _busy,
                                  onStart: () => _setTimer(task, 'start'),
                                  onPause: () => _setTimer(task, 'pause'),
                                  onComplete: () => _setTimer(task, 'complete'),
                                  onEdit:
                                      resources == null
                                          ? null
                                          : () => _openEditor(
                                            resources,
                                            task: task,
                                          ),
                                  onCancel: () => _cancelTask(task),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<GranithTask> _filter(List<GranithTask> tasks) {
    final query = _query.trim().toLowerCase();
    return tasks
        .where((task) {
          if (_status != null && task.status != _status) return false;
          if (query.isEmpty) return true;
          return [
            task.title,
            task.description,
            task.assigneeName,
            task.supervisorName,
            task.sourceName,
          ].any((value) => value.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  Future<void> _openEditor(
    _TaskResources resources, {
    GranithTask? task,
  }) async {
    final result = await showDialog<_TaskDraft>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TaskEditorDialog(resources: resources, task: task),
    );
    if (result == null) return;

    await _runAction(() async {
      await _service.saveTask(
        id: task?.id,
        title: result.title,
        description: result.description,
        priority: result.priority,
        supervisorId: result.supervisorId,
        assigneeId: result.assigneeId,
        source: result.source,
        projectId: result.projectId,
        budgetId: result.budgetId,
        dueAt: result.dueAt,
        estimatedMinutes: result.estimatedMinutes,
      );
      _showMessage(task == null ? 'Tarefa criada.' : 'Tarefa atualizada.');
    });
  }

  Future<void> _setTimer(GranithTask task, String action) async {
    await _runAction(() async {
      await _service.setTimer(task.id, action);
      _showMessage(switch (action) {
        'start' => 'Cronometro iniciado.',
        'pause' => 'Cronometro pausado.',
        _ => 'Tarefa concluida.',
      });
    });
  }

  Future<void> _cancelTask(GranithTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancelar tarefa?'),
            content: Text(
              'O historico de tempo de "${task.title}" sera preservado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cancelar tarefa'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await _runAction(() async {
      if (task.isTimerRunning) {
        await _service.setTimer(task.id, 'pause');
      }
      await _service.cancelTask(task.id);
      _showMessage('Tarefa cancelada.');
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _showMessage(_friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('granith_tasks') || text.contains('PGRST205')) {
      return 'O modulo de tarefas ainda nao foi aplicado no Supabase. Execute a migration mais recente.';
    }
    if (text.contains('single_active') || text.contains('23505')) {
      return 'Pause a tarefa atual antes de iniciar outra.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? AppColors.accentRed : AppColors.surfaceElevated,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.canControl,
    required this.canManage,
    required this.busy,
    required this.onStart,
    required this.onPause,
    required this.onComplete,
    required this.onEdit,
    required this.onCancel,
  });

  final GranithTask task;
  final bool canControl;
  final bool canManage;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onComplete;
  final VoidCallback? onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final accent = task.priority.color;
    return GranitCard(
      accentColor: task.isTimerRunning ? AppColors.accentBlue : accent,
      emphasized: task.isTimerRunning,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.32)),
                ),
                child: Icon(task.status.icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        GranitBadge(label: task.priority.label, color: accent),
                        GranitBadge(
                          label: task.status.label,
                          color:
                              task.status == GranithTaskStatus.completed
                                  ? AppColors.accentGreen
                                  : AppColors.accentBlue,
                        ),
                        GranitBadge(
                          label: task.source.label,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage && !task.isClosed)
                PopupMenuButton<String>(
                  tooltip: 'Acoes da tarefa',
                  color: AppColors.surfaceElevated,
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'cancel') onCancel();
                  },
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancelar tarefa'),
                        ),
                      ],
                ),
            ],
          ),
          if (task.description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              task.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _Meta(
                icon: Icons.person_outline_rounded,
                label: 'Executor',
                value: task.assigneeName,
              ),
              _Meta(
                icon: Icons.supervisor_account_outlined,
                label: 'Supervisor',
                value: task.supervisorName,
              ),
              _Meta(
                icon: Icons.account_tree_outlined,
                label: task.source.label,
                value: task.sourceName,
              ),
              if (task.dueAt != null)
                _Meta(
                  icon: Icons.event_outlined,
                  label: 'Prazo',
                  value: _date(task.dueAt!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(
                  task.isTimerRunning
                      ? Icons.timer_rounded
                      : Icons.timer_outlined,
                  color:
                      task.isTimerRunning
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _LiveTaskDuration(
                    task: task,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (task.estimatedMinutes > 0)
                  Text(
                    'estimado ${_duration(task.estimatedMinutes * 60)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (canControl && !task.isClosed) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (!task.isTimerRunning)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : onStart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        task.status == GranithTaskStatus.paused
                            ? 'Continuar'
                            : 'Iniciar',
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onPause,
                      icon: const Icon(Icons.pause_rounded),
                      label: const Text('Pausar'),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onComplete,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Concluir'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveTaskPanel extends StatelessWidget {
  const _ActiveTaskPanel({
    required this.task,
    required this.busy,
    required this.onPause,
    required this.onComplete,
  });

  final GranithTask task;
  final bool busy;
  final VoidCallback onPause;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      accentColor: AppColors.accentBlue,
      emphasized: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CRONOMETRO ATIVO',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${task.assigneeName}  |  ${task.sourceName}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          );
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveTaskDuration(
                task: task,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 14),
              IconButton.filledTonal(
                tooltip: 'Pausar',
                onPressed: busy ? null : onPause,
                icon: const Icon(Icons.pause_rounded),
              ),
              const SizedBox(width: 7),
              IconButton.filled(
                tooltip: 'Concluir',
                onPressed: busy ? null : onComplete,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 14), controls],
            );
          }
          return Row(
            children: [
              const Icon(
                Icons.radio_button_checked_rounded,
                color: AppColors.accentBlue,
                size: 34,
              ),
              const SizedBox(width: 14),
              Expanded(child: details),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({required this.resources, this.task});

  final _TaskResources resources;
  final GranithTask? task;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _estimated;
  late EmployeeModel? _supervisor;
  late EmployeeModel? _assignee;
  late GranithTaskPriority _priority;
  late GranithTaskSource _source;
  String? _projectId;
  String? _budgetId;
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _estimated = TextEditingController(
      text:
          task == null || task.estimatedMinutes == 0
              ? ''
              : task.estimatedMinutes.toString(),
    );
    _supervisor = _findEmployee(
      task?.supervisorId ?? widget.resources.currentEmployee?.id,
    );
    _assignee = _findEmployee(task?.assigneeId);
    _priority = task?.priority ?? GranithTaskPriority.medium;
    _source = task?.source ?? GranithTaskSource.general;
    _projectId = task?.projectId;
    _budgetId = task?.budgetId;
    _dueAt = task?.dueAt;
  }

  EmployeeModel? _findEmployee(String? id) {
    if (id == null) return null;
    for (final employee in widget.resources.employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _estimated.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supervisors = widget.resources.employees
        .where((employee) => employee.role.isSupervisorOrAbove)
        .toList(growable: false);
    return AlertDialog(
      insetPadding: const EdgeInsets.all(18),
      title: Text(widget.task == null ? 'Nova tarefa' : 'Editar tarefa'),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Titulo',
                    prefixIcon: Icon(Icons.task_alt_rounded),
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe o titulo.'
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Descricao e criterio de conclusao',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                const _FormLabel('Prioridade'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final priority in GranithTaskPriority.values)
                      ChoiceChip(
                        label: Text(priority.label),
                        selected: _priority == priority,
                        selectedColor: priority.color.withValues(alpha: 0.22),
                        side: BorderSide(
                          color:
                              _priority == priority
                                  ? priority.color
                                  : AppColors.borderColor,
                        ),
                        onSelected: (_) => setState(() => _priority = priority),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 560;
                    final supervisor = _EmployeeSearchField(
                      label: 'Responsavel / supervisor',
                      employees: supervisors,
                      initial: _supervisor,
                      onSelected:
                          (employee) => setState(() => _supervisor = employee),
                    );
                    final assignee = _EmployeeSearchField(
                      label: 'Pessoa executora',
                      employees: widget.resources.employees,
                      initial: _assignee,
                      onSelected:
                          (employee) => setState(() => _assignee = employee),
                    );
                    if (compact) {
                      return Column(
                        children: [
                          supervisor,
                          const SizedBox(height: 12),
                          assignee,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: supervisor),
                        const SizedBox(width: 12),
                        Expanded(child: assignee),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const _FormLabel('Origem da tarefa'),
                SegmentedButton<GranithTaskSource>(
                  showSelectedIcon: false,
                  segments: [
                    for (final source in GranithTaskSource.values)
                      ButtonSegment(
                        value: source,
                        label: Text(source.label),
                        icon: Icon(switch (source) {
                          GranithTaskSource.general => Icons.widgets_outlined,
                          GranithTaskSource.project => Icons.business_outlined,
                          GranithTaskSource.budget =>
                            Icons.request_quote_outlined,
                        }),
                      ),
                  ],
                  selected: {_source},
                  onSelectionChanged:
                      (value) => setState(() {
                        _source = value.first;
                        if (_source != GranithTaskSource.project) {
                          _projectId = null;
                        }
                        if (_source != GranithTaskSource.budget) {
                          _budgetId = null;
                        }
                      }),
                ),
                if (_source == GranithTaskSource.project) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _projectId,
                    dropdownColor: AppColors.surfaceElevated,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Obra'),
                    items: [
                      for (final project in widget.resources.projects)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(
                            '${project.name} - ${project.client}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _projectId = value),
                  ),
                ],
                if (_source == GranithTaskSource.budget) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _budgetId,
                    dropdownColor: AppColors.surfaceElevated,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Orcamento'),
                    items: [
                      for (final budget in widget.resources.budgets)
                        DropdownMenuItem(
                          value: budget.id,
                          child: Text(
                            '${budget.projectName} - ${budget.clientName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _budgetId = value),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Prazo',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                          child: Text(
                            _dueAt == null ? 'Sem prazo' : _date(_dueAt!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _estimated,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimativa (min)',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.task == null ? 'Criar tarefa' : 'Salvar'),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) setState(() => _dueAt = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_supervisor == null || _assignee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione supervisor e executor.')),
      );
      return;
    }
    if (_source == GranithTaskSource.project && _projectId == null ||
        _source == GranithTaskSource.budget && _budgetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a origem da tarefa.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _TaskDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        priority: _priority,
        supervisorId: _supervisor!.id,
        assigneeId: _assignee!.id,
        source: _source,
        projectId: _projectId,
        budgetId: _budgetId,
        dueAt: _dueAt,
        estimatedMinutes: int.tryParse(_estimated.text.trim()) ?? 0,
      ),
    );
  }
}

class _EmployeeSearchField extends StatelessWidget {
  const _EmployeeSearchField({
    required this.label,
    required this.employees,
    required this.initial,
    required this.onSelected,
  });

  final String label;
  final List<EmployeeModel> employees;
  final EmployeeModel? initial;
  final ValueChanged<EmployeeModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<EmployeeModel>(
      initialValue: TextEditingValue(text: initial?.name ?? ''),
      displayStringForOption: (employee) => employee.name,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return employees;
        return employees.where(
          (employee) =>
              employee.name.toLowerCase().contains(query) ||
              employee.jobTitle.toLowerCase().contains(query),
        );
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, controller, focusNode, onSubmitted) => TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.person_search_outlined),
            ),
          ),
      optionsViewBuilder:
          (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: AppColors.surfaceElevated,
              elevation: 16,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 320,
                  maxHeight: 260,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final employee = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(employee.name),
                      subtitle: Text(employee.jobTitle),
                      onTap: () => onSelected(employee),
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 185,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
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
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accentBlue.withValues(alpha: 0.18),
      side: BorderSide(
        color: selected ? AppColors.accentBlue : AppColors.borderColor,
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return GranitCard(
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 24),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.textMuted, size: 42),
            SizedBox(height: 12),
            Text(
              'Nenhuma tarefa encontrada',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ajuste os filtros ou crie uma nova atividade.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GranitCard(
        accentColor: AppColors.accentRed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.accentRed,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTaskDuration extends StatefulWidget {
  const _LiveTaskDuration({required this.task, required this.style});

  final GranithTask task;
  final TextStyle style;

  @override
  State<_LiveTaskDuration> createState() => _LiveTaskDurationState();
}

class _LiveTaskDurationState extends State<_LiveTaskDuration> {
  StreamSubscription<int>? _ticker;

  @override
  void initState() {
    super.initState();
    _configureTicker();
  }

  @override
  void didUpdateWidget(covariant _LiveTaskDuration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.isTimerRunning != widget.task.isTimerRunning ||
        oldWidget.task.activeTimerStartedAt !=
            widget.task.activeTimerStartedAt) {
      _configureTicker();
    }
  }

  void _configureTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (!widget.task.isTimerRunning) return;
    _ticker = Stream<int>.periodic(
      const Duration(seconds: 1),
      (value) => value,
    ).listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _duration(widget.task.elapsedSecondsAt(DateTime.now())),
      style: widget.style,
    );
  }
}

class _TaskResources {
  const _TaskResources({
    required this.employees,
    required this.projects,
    required this.budgets,
    required this.currentEmployee,
  });

  final List<EmployeeModel> employees;
  final List<Project> projects;
  final List<Budget> budgets;
  final EmployeeModel? currentEmployee;
}

class _TaskDraft {
  const _TaskDraft({
    required this.title,
    required this.description,
    required this.priority,
    required this.supervisorId,
    required this.assigneeId,
    required this.source,
    required this.projectId,
    required this.budgetId,
    required this.dueAt,
    required this.estimatedMinutes,
  });

  final String title;
  final String description;
  final GranithTaskPriority priority;
  final String supervisorId;
  final String assigneeId;
  final GranithTaskSource source;
  final String? projectId;
  final String? budgetId;
  final DateTime? dueAt;
  final int estimatedMinutes;
}

String _duration(int totalSeconds) {
  final safe = totalSeconds.clamp(0, 1 << 31);
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final seconds = safe % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
