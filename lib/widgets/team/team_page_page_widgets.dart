import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/team_model.dart';
import 'package:project_granith/themes/app_theme.dart';

class TeamPageView extends StatefulWidget {
  const TeamPageView({super.key});

  @override
  State<TeamPageView> createState() => _TeamPageViewState();
}

class _TeamPageViewState extends State<TeamPageView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeamController>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pagePadding =
        width >= 1100
            ? 28.0
            : width >= 480
            ? 16.0
            : 12.0;

    return Consumer2<TeamController, AuthViewModel>(
      builder: (context, controller, auth, _) {
        final currentEmployee = _currentEmployee(auth, controller.employees);
        final canManage = _canManageTeams(auth, currentEmployee);

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Padding(
            padding: EdgeInsets.all(pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TeamHeader(
                  controller: controller,
                  canManage: canManage,
                  onCreate: canManage ? () => _openTeamDialog(context) : null,
                ),
                if (!canManage) ...[
                  const SizedBox(height: 14),
                  const _ReadOnlyBanner(),
                ],
                if (controller.error != null) ...[
                  const SizedBox(height: 14),
                  _InlineError(
                    message: controller.error!,
                    onRetry: controller.refresh,
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child:
                        controller.isLoading && controller.teams.isEmpty
                            ? const _LoadingState()
                            : controller.teams.isEmpty
                            ? _EmptyTeamsState(
                              canManage: canManage,
                              onCreate:
                                  canManage
                                      ? () => _openTeamDialog(context)
                                      : null,
                            )
                            : _TeamsGrid(
                              controller: controller,
                              canManage: canManage,
                              onEdit: (team) => _openTeamDialog(context, team),
                              onManageMembers:
                                  (team) => _openMembersDialog(context, team),
                              onDelete: (team) => _confirmDelete(context, team),
                            ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTeamDialog(BuildContext context, [TeamModel? team]) async {
    final controller = context.read<TeamController>();
    final result = await showDialog<_TeamFormResult>(
      context: context,
      builder:
          (_) => _TeamFormDialog(
            team: team,
            employees: controller.employees.where((e) => e.isActive).toList(),
          ),
    );

    if (result == null || !context.mounted) return;

    try {
      if (team == null) {
        await controller.createTeam(
          name: result.name,
          description: result.description,
          memberIds: result.memberIds,
          leaderId: result.leaderId,
        );
        if (!context.mounted) return;
        _showSnack(context, 'Equipe criada.');
      } else {
        await controller.updateTeam(
          team.copyWith(
            name: result.name,
            description: result.description,
            memberIds: result.memberIds,
            leaderId: result.leaderId,
          ),
        );
        if (!context.mounted) return;
        _showSnack(context, 'Equipe atualizada.');
      }
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(context, 'Erro ao salvar equipe: $error');
    }
  }

  Future<void> _openMembersDialog(BuildContext context, TeamModel team) async {
    final controller = context.read<TeamController>();
    final result = await showDialog<_TeamMembersResult>(
      context: context,
      builder:
          (_) => _TeamMembersDialog(
            team: team,
            employees: controller.employees.where((e) => e.isActive).toList(),
          ),
    );

    if (result == null || !context.mounted) return;

    try {
      await controller.updateTeam(
        team.copyWith(memberIds: result.memberIds, leaderId: result.leaderId),
      );
      if (!context.mounted) return;
      _showSnack(context, 'Composicao da equipe atualizada.');
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(context, 'Erro ao montar equipe: $error');
    }
  }

  Future<void> _confirmDelete(BuildContext context, TeamModel team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.96),
            title: const Text(
              'Desativar equipe?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'A equipe "${team.name}" deixara de aparecer na listagem.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Desativar'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    final controller = context.read<TeamController>();
    try {
      await controller.deleteTeam(team.id);
      if (!context.mounted) return;
      _showSnack(context, 'Equipe desativada.');
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(context, 'Erro ao desativar equipe: $error');
    }
  }
}

class _TeamHeader extends StatelessWidget {
  final TeamController controller;
  final bool canManage;
  final VoidCallback? onCreate;

  const _TeamHeader({
    required this.controller,
    required this.canManage,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final assignedMembers = controller.teams.fold<int>(
      0,
      (total, team) => total + team.memberIds.length,
    );
    final unassigned =
        controller.employees.where((employee) {
          if (!employee.isActive) return false;
          return !controller.teams.any(
            (team) => team.memberIds.contains(employee.id),
          );
        }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final title = Row(
          children: [
            const _HeaderIcon(),
            const SizedBox(width: 14),
            const Expanded(child: _HeaderTitle()),
          ],
        );
        final stats = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: 'Equipes',
              value: '${controller.teams.length}',
              color: AppColors.accentBlue,
            ),
            _StatPill(
              label: 'Membros',
              value: '$assignedMembers',
              color: AppColors.accentGreen,
            ),
            _StatPill(
              label: 'Disponiveis',
              value: '$unassigned',
              color: AppColors.accentGold,
            ),
          ],
        );
        final button = ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.group_add_rounded, size: 18),
          label: const Text('Nova equipe'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryDark,
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 14),
              stats,
              if (canManage) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: button),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 18),
            stats,
            if (canManage) ...[const SizedBox(width: 14), button],
          ],
        );
      },
    );
  }
}

class _TeamsGrid extends StatelessWidget {
  final TeamController controller;
  final bool canManage;
  final ValueChanged<TeamModel> onEdit;
  final ValueChanged<TeamModel> onManageMembers;
  final ValueChanged<TeamModel> onDelete;

  const _TeamsGrid({
    required this.controller,
    required this.canManage,
    required this.onEdit,
    required this.onManageMembers,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1180
                ? 3
                : constraints.maxWidth >= 760
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: constraints.maxWidth < 420 ? 306 : 268,
          ),
          itemCount: controller.teams.length,
          itemBuilder: (context, index) {
            final team = controller.teams[index];
            final members = controller.getMembersOfTeam(team);
            final leader = _employeeById(controller.employees, team.leaderId);
            return _TeamCard(
              team: team,
              members: members,
              leader: leader,
              canManage: canManage,
              onEdit: () => onEdit(team),
              onManageMembers: () => onManageMembers(team),
              onDelete: () => onDelete(team),
            );
          },
        );
      },
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final List<EmployeeModel> members;
  final EmployeeModel? leader;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onManageMembers;
  final VoidCallback onDelete;

  const _TeamCard({
    required this.team,
    required this.members,
    required this.leader,
    required this.canManage,
    required this.onEdit,
    required this.onManageMembers,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TileIcon(
                icon: Icons.groups_2_rounded,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      leader == null ? 'Sem lider definido' : leader!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<_TeamAction>(
                  tooltip: 'Acoes',
                  color: AppColors.surfaceDark,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _TeamAction.members:
                        onManageMembers();
                        break;
                      case _TeamAction.edit:
                        onEdit();
                        break;
                      case _TeamAction.delete:
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(
                          value: _TeamAction.members,
                          child: _PopupActionLabel(
                            icon: Icons.group_add_rounded,
                            label: 'Montar equipe',
                          ),
                        ),
                        PopupMenuItem(
                          value: _TeamAction.edit,
                          child: _PopupActionLabel(
                            icon: Icons.edit_rounded,
                            label: 'Editar dados',
                          ),
                        ),
                        PopupMenuItem(
                          value: _TeamAction.delete,
                          child: _PopupActionLabel(
                            icon: Icons.delete_outline_rounded,
                            label: 'Desativar',
                          ),
                        ),
                      ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(
                label: '${members.length} membro(s)',
                color: AppColors.accentGreen,
              ),
              if (team.projectId?.isNotEmpty == true)
                _StatusBadge(
                  label: 'Obra vinculada',
                  color: AppColors.accentGold,
                ),
            ],
          ),
          if (team.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              team.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(child: _MembersPreview(members: members)),
          if (canManage) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManageMembers,
                icon: const Icon(Icons.groups_rounded, size: 18),
                label: const Text('Montar equipe'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembersPreview extends StatelessWidget {
  final List<EmployeeModel> members;

  const _MembersPreview({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Nenhum colaborador vinculado.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...members.take(5).map((member) => _MemberChip(employee: member)),
        if (members.length > 5) _TextChip(label: '+${members.length - 5}'),
      ],
    );
  }
}

class _TeamFormDialog extends StatefulWidget {
  final TeamModel? team;
  final List<EmployeeModel> employees;

  const _TeamFormDialog({this.team, required this.employees});

  @override
  State<_TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<_TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  late final Set<String> _memberIds;
  String? _leaderId;

  bool get _isEdit => widget.team != null;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _nameCtrl.text = team?.name ?? '';
    _descriptionCtrl.text = team?.description ?? '';
    _memberIds = Set<String>.from(team?.memberIds ?? const []);
    _leaderId = team?.leaderId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth =
        (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 620.0).toDouble();
    final dialogMaxHeight = MediaQuery.sizeOf(context).height * 0.74;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEdit ? 'Editar equipe' : 'Nova equipe'),
      content: SizedBox(
        width: dialogWidth,
        height: dialogMaxHeight,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome da equipe',
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe o nome'
                              : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                ),
                const SizedBox(height: 18),
                _EmployeePicker(
                  employees: widget.employees,
                  selectedIds: _memberIds,
                  leaderId: _leaderId,
                  onToggle: _toggleMember,
                  onLeaderChanged: (id) => setState(() => _leaderId = id),
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
          onPressed: _save,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: Text(_isEdit ? 'Salvar' : 'Criar equipe'),
        ),
      ],
    );
  }

  void _toggleMember(String employeeId, bool selected) {
    setState(() {
      if (selected) {
        _memberIds.add(employeeId);
      } else {
        _memberIds.remove(employeeId);
        if (_leaderId == employeeId) {
          _leaderId = null;
        }
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _TeamFormResult(
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        memberIds: _memberIds.toList(),
        leaderId: _memberIds.contains(_leaderId) ? _leaderId : null,
      ),
    );
  }
}

class _TeamMembersDialog extends StatefulWidget {
  final TeamModel team;
  final List<EmployeeModel> employees;

  const _TeamMembersDialog({required this.team, required this.employees});

  @override
  State<_TeamMembersDialog> createState() => _TeamMembersDialogState();
}

class _TeamMembersDialogState extends State<_TeamMembersDialog> {
  late final Set<String> _memberIds;
  String? _leaderId;

  @override
  void initState() {
    super.initState();
    _memberIds = Set<String>.from(widget.team.memberIds);
    _leaderId = widget.team.leaderId;
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth =
        (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 620.0).toDouble();
    final dialogMaxHeight = MediaQuery.sizeOf(context).height * 0.74;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text('Montar ${widget.team.name}'),
      content: SizedBox(
        width: dialogWidth,
        height: dialogMaxHeight,
        child: SingleChildScrollView(
          child: _EmployeePicker(
            employees: widget.employees,
            selectedIds: _memberIds,
            leaderId: _leaderId,
            onToggle: _toggleMember,
            onLeaderChanged: (id) => setState(() => _leaderId = id),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Salvar composicao'),
        ),
      ],
    );
  }

  void _toggleMember(String employeeId, bool selected) {
    setState(() {
      if (selected) {
        _memberIds.add(employeeId);
      } else {
        _memberIds.remove(employeeId);
        if (_leaderId == employeeId) {
          _leaderId = null;
        }
      }
    });
  }

  void _save() {
    Navigator.pop(
      context,
      _TeamMembersResult(
        memberIds: _memberIds.toList(),
        leaderId: _memberIds.contains(_leaderId) ? _leaderId : null,
      ),
    );
  }
}

class _EmployeePicker extends StatelessWidget {
  final List<EmployeeModel> employees;
  final Set<String> selectedIds;
  final String? leaderId;
  final void Function(String employeeId, bool selected) onToggle;
  final ValueChanged<String?> onLeaderChanged;

  const _EmployeePicker({
    required this.employees,
    required this.selectedIds,
    required this.leaderId,
    required this.onToggle,
    required this.onLeaderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedEmployees =
        employees
            .where((employee) => selectedIds.contains(employee.id))
            .toList();
    final sortedEmployees = [...employees]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: selectedIds.contains(leaderId) ? leaderId : null,
          decoration: const InputDecoration(labelText: 'Lider da equipe'),
          dropdownColor: AppColors.surfaceDark,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Sem lider definido'),
            ),
            ...selectedEmployees.map(
              (employee) => DropdownMenuItem<String?>(
                value: employee.id,
                child: Text(employee.name),
              ),
            ),
          ],
          onChanged: onLeaderChanged,
        ),
        const SizedBox(height: 16),
        const Text(
          'Membros',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (employees.isEmpty)
          const Text(
            'Cadastre colaboradores ativos antes de montar equipes.',
            style: TextStyle(color: AppColors.textMuted),
          )
        else
          ...sortedEmployees.map((employee) {
            final selected = selectedIds.contains(employee.id);
            return CheckboxListTile(
              value: selected,
              onChanged: (value) => onToggle(employee.id, value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                employee.name,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                '${employee.jobTitle} - ${employee.sector}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              secondary:
                  leaderId == employee.id
                      ? const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.accentGold,
                      )
                      : null,
            );
          }),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Recarregar'),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.28)),
      ),
      child: const Row(
        children: [
          Icon(Icons.visibility_rounded, color: AppColors.accentBlue, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Visualizacao liberada. A montagem de equipes fica disponivel para Coordenadores, Supervisores RH e Gerencia.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTeamsState extends StatelessWidget {
  final bool canManage;
  final VoidCallback? onCreate;

  const _EmptyTeamsState({required this.canManage, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_2_outlined,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhuma equipe cadastrada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              canManage
                  ? 'Crie equipes e vincule colaboradores ativos.'
                  : 'As equipes criadas pelo RH aparecerao aqui.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            if (canManage && onCreate != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Nova equipe'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
      ),
      child: const Icon(
        Icons.groups_2_rounded,
        color: AppColors.accentGold,
        size: 20,
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Equipes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Visualizacao e montagem de equipes operacionais',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  final Widget child;

  const _SurfaceTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TileIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final EmployeeModel employee;

  const _MemberChip({required this.employee});

  @override
  Widget build(BuildContext context) {
    return _TextChip(label: employee.name);
  }
}

class _TextChip extends StatelessWidget {
  final String label;

  const _TextChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}

class _PopupActionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PopupActionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 18),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      ],
    );
  }
}

class _TeamFormResult {
  final String name;
  final String description;
  final List<String> memberIds;
  final String? leaderId;

  const _TeamFormResult({
    required this.name,
    required this.description,
    required this.memberIds,
    required this.leaderId,
  });
}

class _TeamMembersResult {
  final List<String> memberIds;
  final String? leaderId;

  const _TeamMembersResult({required this.memberIds, required this.leaderId});
}

enum _TeamAction { members, edit, delete }

EmployeeModel? _currentEmployee(
  AuthViewModel auth,
  List<EmployeeModel> employees,
) {
  final email = (auth.user?.email ?? '').trim().toLowerCase();
  if (email.isEmpty) return null;

  for (final employee in employees) {
    if (employee.email.trim().toLowerCase() == email) {
      return employee;
    }
  }
  return null;
}

EmployeeModel? _employeeById(List<EmployeeModel> employees, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final employee in employees) {
    if (employee.id == id) return employee;
  }
  return null;
}

bool _canManageTeams(AuthViewModel auth, EmployeeModel? employee) {
  if (auth.isAdminUser ||
      auth.hasPermission('people.manage') ||
      auth.hasPermission('mobile.team.manage') ||
      auth.hasPermission('mobile.hierarchy.manage')) {
    return true;
  }

  if (employee == null) return false;
  if (employee.role == EmployeeRole.coordenador ||
      employee.role == EmployeeRole.gerente) {
    return true;
  }

  return employee.role == EmployeeRole.supervisor &&
      _isRhSector(employee.sector);
}

bool _isRhSector(String sector) {
  final normalized = sector
      .toLowerCase()
      .replaceAll('recursos humanos', 'rh')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return normalized.contains('rh');
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
