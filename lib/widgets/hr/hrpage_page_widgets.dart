import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/ViewModels/HrViewModel.dart';
import 'package:project_granith/constants/permission_constants.dart';
import 'package:project_granith/controllers/team_controller.dart';
import 'package:project_granith/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/models/job_role_model.dart';
import 'package:project_granith/models/sector_model.dart';
import 'package:project_granith/services/HrService.dart';
import 'package:project_granith/services/job_role_service.dart';
import 'package:project_granith/services/sector_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/employee/employee_card.dart';
import 'package:project_granith/widgets/employee/employee_form_dialog.dart';

class HrPageView extends StatefulWidget {
  const HrPageView({super.key});

  @override
  State<HrPageView> createState() => _HrPageViewState();
}

class _HrPageViewState extends State<HrPageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final HrService _hrService = HrService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeamController>().init();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HrViewModel(_hrService),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = ResponsiveLayout.pagePadding(
                constraints.maxWidth,
              );

              return Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HrHeader(),
                    const SizedBox(height: 10),
                    _HrTabBar(tabController: _tabController),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [
                          _EmployeesTab(),
                          _JobRolesTab(),
                          _SectorsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HrHeader extends StatelessWidget {
  const _HrHeader();

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamController>(
      builder: (context, controller, _) {
        final employees = controller.employees;
        final total = employees.length;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < ResponsiveLayout.compact;

            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 2 : 0,
                vertical: compact ? 2 : 4,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!compact) ...[
                    const _HeaderIcon(),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: _HeaderTitle(compact: compact)),
                  if (!compact) ...[
                    _HeaderStatusPill(
                      label: '$total colaboradores',
                      icon: Icons.groups_2_rounded,
                      color: AppColors.accentGold,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmployeesTab extends StatefulWidget {
  const _EmployeesTab();

  @override
  State<_EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<_EmployeesTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TeamController, HrViewModel>(
      builder: (context, controller, viewModel, _) {
        final employees = viewModel.filterEmployees(controller.employees);
        final auth = context.watch<AuthViewModel?>();
        final canViewSalary = PermissionCodes.canViewPeopleSalary(
          isAdmin: auth?.isAdminUser ?? false,
          permissions: auth?.user?.permissions ?? const <String>[],
        );

        return Column(
          children: [
            _EmployeesToolbar(
              searchController: _searchController,
              viewModel: viewModel,
              visibleCount: employees.length,
              totalCount: controller.employees.length,
              onCreate: () => _openEmployeeForm(context, canViewSalary),
            ),
            if (controller.error != null) ...[
              const SizedBox(height: 12),
              _InlineError(
                message: controller.error!,
                onRetry: controller.refresh,
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child:
                    controller.isLoading && controller.employees.isEmpty
                        ? const _LoadingState()
                        : employees.isEmpty
                        ? _EmptyEmployeesState(
                          hasAnyEmployee: controller.employees.isNotEmpty,
                        )
                        : _EmployeeGrid(
                          employees: employees,
                          canViewSalary: canViewSalary,
                          onEdit:
                              (employee) => _openEmployeeForm(
                                context,
                                canViewSalary,
                                employee,
                              ),
                          onDismiss:
                              (employee) => _confirmDismiss(context, employee),
                          onDelete:
                              (employee) => _confirmDelete(context, employee),
                        ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEmployeeForm(
    BuildContext context, [
    bool canViewSalary = false,
    EmployeeModel? employee,
  ]) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => EmployeeFormDialog(
            employee: employee,
            canViewSalary: canViewSalary,
          ),
    );
  }

  Future<void> _confirmDismiss(
    BuildContext context,
    EmployeeModel employee,
  ) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Registrar desligamento?',
      message:
          'O colaborador sera marcado como desligado e removido das equipes.',
      confirmLabel: 'Desligar',
      confirmColor: AppColors.accentRed,
    );
    if (confirmed != true || !context.mounted) return;

    final controller = context.read<TeamController>();
    try {
      await controller.dismissEmployee(employee.id);
      if (!context.mounted) return;
      _showSnack(context, 'Desligamento registrado.');
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, controller.error ?? 'Erro ao desligar colaborador.');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EmployeeModel employee,
  ) async {
    final confirmed = await _confirmAction(
      context,
      title: 'Excluir cadastro?',
      message: 'Essa acao remove o registro do colaborador do banco de dados.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.accentRed,
    );
    if (confirmed != true || !context.mounted) return;

    final controller = context.read<TeamController>();
    try {
      await controller.deleteEmployee(employee.id);
      if (!context.mounted) return;
      _showSnack(context, 'Cadastro excluido.');
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, controller.error ?? 'Erro ao excluir colaborador.');
    }
  }

  Future<bool?> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.96),
            title: Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmployeesToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final HrViewModel viewModel;
  final int visibleCount;
  final int totalCount;
  final VoidCallback onCreate;

  const _EmployeesToolbar({
    required this.searchController,
    required this.viewModel,
    required this.visibleCount,
    required this.totalCount,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ResponsiveLayout.compact;
        final roomy = constraints.maxWidth >= 1320;
        final searchField = SizedBox(
          width:
              compact
                  ? double.infinity
                  : roomy
                  ? 390
                  : 320,
          child: TextField(
            controller: searchController,
            onChanged: viewModel.updateSearch,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Buscar por nome, cargo, setor ou email',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.backgroundDark.withValues(alpha: 0.34),
            ),
          ),
        );

        final statusField = SizedBox(
          width: compact ? double.infinity : 210,
          height: 48,
          child: Container(
            padding: const EdgeInsets.only(left: 14, right: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EmployeeStatus?>(
                      value: viewModel.statusFilter,
                      hint: const Text('Todos'),
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceDark,
                      icon: const Icon(Icons.expand_more_rounded, size: 20),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(
                          value: EmployeeStatus.ativo,
                          child: Text('Ativos'),
                        ),
                        DropdownMenuItem(
                          value: EmployeeStatus.ferias,
                          child: Text('Ferias'),
                        ),
                        DropdownMenuItem(
                          value: EmployeeStatus.afastado,
                          child: Text('Afastados'),
                        ),
                        DropdownMenuItem(
                          value: EmployeeStatus.desligado,
                          child: Text('Desligados'),
                        ),
                      ],
                      onChanged: viewModel.updateStatusFilter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final resultChip = _ToolbarCountChip(
          visibleCount: visibleCount,
          totalCount: totalCount,
        );

        final createButton = SizedBox(
          width: compact ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(compact ? 'Novo' : 'Novo colaborador'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );

        if (compact) {
          return _ToolbarSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                statusField,
                const SizedBox(height: 10),
                Row(children: [Expanded(child: resultChip)]),
                const SizedBox(height: 10),
                createButton,
              ],
            ),
          );
        }

        if (!roomy) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [searchField, statusField, resultChip, createButton],
          );
        }

        return Row(
          children: [
            searchField,
            const SizedBox(width: 10),
            statusField,
            const SizedBox(width: 10),
            resultChip,
            const Spacer(),
            createButton,
          ],
        );
      },
    );
  }
}

class _EmployeeGrid extends StatelessWidget {
  final List<EmployeeModel> employees;
  final bool canViewSalary;
  final ValueChanged<EmployeeModel> onEdit;
  final ValueChanged<EmployeeModel> onDismiss;
  final ValueChanged<EmployeeModel> onDelete;

  const _EmployeeGrid({
    required this.employees,
    required this.canViewSalary,
    required this.onEdit,
    required this.onDismiss,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1120
                ? 3
                : constraints.maxWidth >= 720
                ? 2
                : 1;

        return GridView.builder(
          key: const ValueKey('employees-grid'),
          padding: const EdgeInsets.only(bottom: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: constraints.maxWidth < 420 ? 286 : 268,
          ),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return EmployeeCard(
              employee: employee,
              canViewSalary: canViewSalary,
              onTap: () => onEdit(employee),
              onDismiss:
                  employee.isDismissed ? null : () => onDismiss(employee),
              onDelete: () => onDelete(employee),
            );
          },
        );
      },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final messageRow = Row(
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
            ],
          );
          final action = TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Recarregar'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                messageRow,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: messageRow),
              const SizedBox(width: 10),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _ToolbarSurface extends StatelessWidget {
  final Widget child;

  const _ToolbarSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.62),
        ),
      ),
      child: child,
    );
  }
}

class _ToolbarCountChip extends StatelessWidget {
  final int visibleCount;
  final int totalCount;

  const _ToolbarCountChip({
    required this.visibleCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = visibleCount != totalCount;
    final label = filtered ? '$visibleCount de $totalCount' : '$totalCount';
    final suffix = filtered ? 'visiveis' : 'registros';

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered ? Icons.filter_alt_rounded : Icons.badge_rounded,
            size: 17,
            color: filtered ? AppColors.accentBlue : AppColors.accentGold,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' $suffix',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatusPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _HeaderStatusPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEmployeesState extends StatelessWidget {
  final bool hasAnyEmployee;

  const _EmptyEmployeesState({required this.hasAnyEmployee});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyEmployee
                  ? Icons.manage_search_rounded
                  : Icons.group_add_rounded,
              color: AppColors.textMuted,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              hasAnyEmployee
                  ? 'Nenhum colaborador encontrado'
                  : 'Nenhum colaborador cadastrado',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyEmployee
                  ? 'Ajuste a busca ou o filtro de status.'
                  : 'Use o botao Novo colaborador para criar o primeiro registro.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
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

class _JobRolesTab extends StatefulWidget {
  const _JobRolesTab();

  @override
  State<_JobRolesTab> createState() => _JobRolesTabState();
}

class _JobRolesTabState extends State<_JobRolesTab> {
  final _service = JobRoleService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionToolbar(
          title: 'Cargos',
          subtitle: 'Catalogo de funcoes usado no cadastro de colaboradores',
          leadingIcon: Icons.work_outline_rounded,
          leadingColor: AppColors.accentGold,
          actionLabel: 'Novo cargo',
          actionIcon: Icons.work_rounded,
          onAction: () => _openForm(),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: StreamBuilder<List<JobRoleModel>>(
            stream: _service.getJobRoles(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _CenteredMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Erro ao carregar cargos',
                  message: snapshot.error.toString(),
                  actionLabel: 'Tentar novamente',
                  onAction: () => setState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const _LoadingState();
              }

              final roles = snapshot.data!;
              if (roles.isEmpty) {
                return _CenteredMessage(
                  icon: Icons.work_outline_rounded,
                  title: 'Nenhum cargo cadastrado',
                  message: 'Use Novo cargo para criar o catalogo de funcoes.',
                  actionLabel: 'Novo cargo',
                  onAction: () => _openForm(),
                );
              }

              return _JobRolesList(
                roles: roles,
                onEdit: _openForm,
                onToggle: _toggleRole,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openForm([JobRoleModel? role]) {
    return showDialog<void>(
      context: context,
      builder: (_) => _JobRoleFormDialog(service: _service, role: role),
    );
  }

  Future<void> _toggleRole(JobRoleModel role) async {
    try {
      await _service.saveJobRole(role.copyWith(isActive: !role.isActive));
      if (!mounted) return;
      _showSnack(role.isActive ? 'Cargo desativado.' : 'Cargo reativado.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Erro ao atualizar cargo: $error');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _JobRolesList extends StatelessWidget {
  final List<JobRoleModel> roles;
  final ValueChanged<JobRoleModel> onEdit;
  final ValueChanged<JobRoleModel> onToggle;

  const _JobRolesList({
    required this.roles,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final role = roles[index];
        return _JobRoleTile(
          role: role,
          onEdit: () => onEdit(role),
          onToggle: () => onToggle(role),
        );
      },
    );
  }
}

class _JobRoleTile extends StatelessWidget {
  final JobRoleModel role;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _JobRoleTile({
    required this.role,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    role.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: role.isActive ? 'Ativo' : 'Inativo',
                  color:
                      role.isActive
                          ? AppColors.accentGreen
                          : AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SmallInfoChip(
                  icon: Icons.apartment_rounded,
                  label: role.sector,
                  color: AppColors.accentBlue,
                ),
              ],
            ),
            if (role.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                role.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
            if (role.requirements.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    role.requirements
                        .take(5)
                        .map((item) => _RequirementChip(label: item))
                        .toList(),
              ),
            ],
          ],
        );

        final menu = PopupMenuButton<_TileAction>(
          tooltip: 'Acoes',
          color: AppColors.surfaceDark,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: AppColors.textSecondary,
          ),
          onSelected: (action) {
            switch (action) {
              case _TileAction.edit:
                onEdit();
                break;
              case _TileAction.toggle:
                onToggle();
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: _TileAction.edit,
                  child: _PopupActionLabel(
                    icon: Icons.edit_rounded,
                    label: 'Editar',
                  ),
                ),
                PopupMenuItem(
                  value: _TileAction.toggle,
                  child: _PopupActionLabel(
                    icon:
                        role.isActive
                            ? Icons.toggle_off_rounded
                            : Icons.toggle_on_rounded,
                    label: role.isActive ? 'Desativar' : 'Reativar',
                  ),
                ),
              ],
        );

        return _SurfaceTile(
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TileIcon(
                            icon: Icons.work_outline_rounded,
                            color: AppColors.accentGold,
                          ),
                          const Spacer(),
                          menu,
                        ],
                      ),
                      const SizedBox(height: 12),
                      content,
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TileIcon(
                        icon: Icons.work_outline_rounded,
                        color: AppColors.accentGold,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: content),
                      const SizedBox(width: 8),
                      menu,
                    ],
                  ),
        );
      },
    );
  }
}

class _JobRoleFormDialog extends StatefulWidget {
  final JobRoleService service;
  final JobRoleModel? role;

  const _JobRoleFormDialog({required this.service, this.role});

  @override
  State<_JobRoleFormDialog> createState() => _JobRoleFormDialogState();
}

class _JobRoleFormDialogState extends State<_JobRoleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _sectorCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.role != null;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    if (role != null) {
      _titleCtrl.text = role.title;
      _sectorCtrl.text = role.sector;
      _descriptionCtrl.text = role.description;
      _requirementsCtrl.text = role.requirements.join('\n');
      _isActive = role.isActive;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sectorCtrl.dispose();
    _descriptionCtrl.dispose();
    _requirementsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width - 48).clamp(280.0, 520.0).toDouble();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEdit ? 'Editar cargo' : 'Novo cargo'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: size.height * 0.82,
        ),
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Titulo'),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o titulo'
                                : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _sectorCtrl,
                    decoration: const InputDecoration(labelText: 'Setor'),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o setor'
                                : null,
                  ),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descricao'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _requirementsCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Requisitos',
                      hintText: 'Um requisito por linha',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cargo ativo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon:
              _saving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save_rounded, size: 18),
          label: Text(_isEdit ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final requirements =
        _requirementsCtrl.text
            .split(RegExp(r'[\n;]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
    final existing = widget.role;
    final role =
        existing == null
            ? JobRoleModel(
              id: '',
              title: _titleCtrl.text.trim(),
              sector: _sectorCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              requirements: requirements,
              isActive: _isActive,
              createdAt: now,
            )
            : existing.copyWith(
              title: _titleCtrl.text.trim(),
              sector: _sectorCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              requirements: requirements,
              isActive: _isActive,
            );

    try {
      await widget.service.saveJobRole(role);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Cargo cadastrado.' : 'Cargo atualizado.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar cargo: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectorsTab extends StatefulWidget {
  const _SectorsTab();

  @override
  State<_SectorsTab> createState() => _SectorsTabState();
}

class _SectorsTabState extends State<_SectorsTab> {
  final _service = SectorService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionToolbar(
          title: 'Setores',
          subtitle: 'Catalogo usado no vinculo dos colaboradores',
          leadingIcon: Icons.apartment_rounded,
          leadingColor: AppColors.accentBlue,
          actionLabel: 'Novo setor',
          actionIcon: Icons.apartment_rounded,
          onAction: () => _openForm(),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: StreamBuilder<List<SectorModel>>(
            stream: _service.getSectors(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _CenteredMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Erro ao carregar setores',
                  message: snapshot.error.toString(),
                  actionLabel: 'Tentar novamente',
                  onAction: () => setState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const _LoadingState();
              }

              final sectors = snapshot.data!;
              if (sectors.isEmpty) {
                return _CenteredMessage(
                  icon: Icons.apartment_outlined,
                  title: 'Nenhum setor cadastrado',
                  message:
                      'Use Novo setor para criar as areas usadas nos colaboradores.',
                  actionLabel: 'Novo setor',
                  onAction: () => _openForm(),
                );
              }

              return _SectorsList(
                sectors: sectors,
                onEdit: _openForm,
                onToggle: _toggleSector,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openForm([SectorModel? sector]) {
    return showDialog<void>(
      context: context,
      builder: (_) => _SectorFormDialog(service: _service, sector: sector),
    );
  }

  Future<void> _toggleSector(SectorModel sector) async {
    try {
      await _service.saveSector(
        sector.copyWith(isActive: !sector.isActive, updatedAt: DateTime.now()),
      );
      if (!mounted) return;
      _showSnack(sector.isActive ? 'Setor desativado.' : 'Setor reativado.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Erro ao atualizar setor: $error');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectorsList extends StatelessWidget {
  final List<SectorModel> sectors;
  final ValueChanged<SectorModel> onEdit;
  final ValueChanged<SectorModel> onToggle;

  const _SectorsList({
    required this.sectors,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: sectors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sector = sectors[index];
        return _SectorTile(
          sector: sector,
          onEdit: () => onEdit(sector),
          onToggle: () => onToggle(sector),
        );
      },
    );
  }
}

class _SectorTile extends StatelessWidget {
  final SectorModel sector;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _SectorTile({
    required this.sector,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sector.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: sector.isActive ? 'Ativo' : 'Inativo',
                  color:
                      sector.isActive
                          ? AppColors.accentGreen
                          : AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SmallInfoChip(
              icon:
                  sector.isActive
                      ? Icons.person_add_alt_1_rounded
                      : Icons.visibility_off_rounded,
              label:
                  sector.isActive
                      ? 'Disponivel no cadastro'
                      : 'Oculto no cadastro',
              color:
                  sector.isActive ? AppColors.accentBlue : AppColors.textMuted,
            ),
            if (sector.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                sector.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ],
        );

        final menu = PopupMenuButton<_TileAction>(
          tooltip: 'Acoes',
          color: AppColors.surfaceDark,
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: AppColors.textSecondary,
          ),
          onSelected: (action) {
            switch (action) {
              case _TileAction.edit:
                onEdit();
                break;
              case _TileAction.toggle:
                onToggle();
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: _TileAction.edit,
                  child: _PopupActionLabel(
                    icon: Icons.edit_rounded,
                    label: 'Editar',
                  ),
                ),
                PopupMenuItem(
                  value: _TileAction.toggle,
                  child: _PopupActionLabel(
                    icon:
                        sector.isActive
                            ? Icons.toggle_off_rounded
                            : Icons.toggle_on_rounded,
                    label: sector.isActive ? 'Desativar' : 'Reativar',
                  ),
                ),
              ],
        );

        return _SurfaceTile(
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TileIcon(
                            icon: Icons.apartment_rounded,
                            color: AppColors.accentBlue,
                          ),
                          const Spacer(),
                          menu,
                        ],
                      ),
                      const SizedBox(height: 12),
                      content,
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TileIcon(
                        icon: Icons.apartment_rounded,
                        color: AppColors.accentBlue,
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: content),
                      const SizedBox(width: 8),
                      menu,
                    ],
                  ),
        );
      },
    );
  }
}

class _SectorFormDialog extends StatefulWidget {
  final SectorService service;
  final SectorModel? sector;

  const _SectorFormDialog({required this.service, this.sector});

  @override
  State<_SectorFormDialog> createState() => _SectorFormDialogState();
}

class _SectorFormDialogState extends State<_SectorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.sector != null;

  @override
  void initState() {
    super.initState();
    final sector = widget.sector;
    if (sector != null) {
      _nameCtrl.text = sector.name;
      _descriptionCtrl.text = sector.description;
      _isActive = sector.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = (size.width - 48).clamp(280.0, 500.0).toDouble();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEdit ? 'Editar setor' : 'Novo setor'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: size.height * 0.82,
        ),
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do setor',
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o setor'
                                : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descricao',
                      hintText: 'Opcional',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Setor ativo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon:
              _saving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save_rounded, size: 18),
          label: Text(_isEdit ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.sector;
    final sector =
        existing == null
            ? SectorModel(
              id: '',
              name: _nameCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              isActive: _isActive,
              createdAt: now,
              updatedAt: now,
            )
            : existing.copyWith(
              name: _nameCtrl.text.trim(),
              description: _descriptionCtrl.text.trim(),
              isActive: _isActive,
              updatedAt: now,
            );

    try {
      await widget.service.saveSector(sector);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Setor cadastrado.' : 'Setor atualizado.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar setor: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionToolbar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Color leadingColor;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _SectionToolbar({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.leadingColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ResponsiveLayout.compact;
        final heading = Row(
          children: [
            _TileIcon(icon: leadingIcon, color: leadingColor),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final button = SizedBox(
          width: compact ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

        if (compact) {
          return _ToolbarSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 12), button],
            ),
          );
        }

        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            button,
          ],
        );
      },
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
        color: AppColors.surfaceDark.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.54),
        ),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;

  const _RequirementChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.60),
        ),
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

class _SmallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _SurfaceTile(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TileIcon(icon: icon, color: AppColors.accentBlue),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _TileAction { edit, toggle }

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.18)),
      ),
      child: const Icon(
        Icons.people_alt_rounded,
        color: AppColors.accentGold,
        size: 18,
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final bool compact;

  const _HeaderTitle({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recursos Humanos',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 2),
          const Text(
            'Colaboradores, cargos e setores',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _HrTabBar extends StatelessWidget {
  final TabController tabController;

  const _HrTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.48),
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        controller: tabController,
        indicator: BoxDecoration(
          color: AppColors.accentGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.accentGold.withValues(alpha: 0.22),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.accentGold,
        unselectedLabelColor: AppColors.textMuted,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        labelStyle: TextStyle(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w700,
        ),
        tabs: [
          _HrTab(
            icon: Icons.people_rounded,
            label: compact ? 'Pessoas' : 'Colaboradores',
          ),
          const _HrTab(icon: Icons.work_rounded, label: 'Cargos'),
          const _HrTab(icon: Icons.apartment_rounded, label: 'Setores'),
        ],
      ),
    );
  }
}

class _HrTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HrTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
