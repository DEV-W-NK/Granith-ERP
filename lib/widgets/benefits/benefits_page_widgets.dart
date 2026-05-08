import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project_granith/models/BenefitCategoryModel.dart';
import 'package:project_granith/models/BenefitModel.dart';
import 'package:project_granith/models/EmployeeBenefitModel.dart';
import 'package:project_granith/models/employee_model.dart';
import 'package:project_granith/services/HrService.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class BenefitsPageView extends StatefulWidget {
  const BenefitsPageView({super.key});

  @override
  State<BenefitsPageView> createState() => _BenefitsPageViewState();
}

class _BenefitsPageViewState extends State<BenefitsPageView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final HrService _service = HrService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pagePadding =
        width >= 1100
            ? 20.0
            : width >= 480
            ? 14.0
            : 10.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Padding(
        padding: EdgeInsets.all(pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BenefitsTopBar(tabController: _tabController),
            SizedBox(height: width < 480 ? 10 : 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CatalogTab(service: _service),
                  _CategoriesTab(service: _service),
                  _EmployeeBenefitsTab(service: _service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTab extends StatefulWidget {
  final HrService service;

  const _CatalogTab({required this.service});

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BenefitCategoryModel>>(
      stream: widget.service.watchBenefitCategories(),
      builder: (context, categoriesSnapshot) {
        if (categoriesSnapshot.hasError) {
          return _CenteredMessage(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar categorias',
            message: categoriesSnapshot.error.toString(),
            actionLabel: 'Tentar novamente',
            onAction: () => setState(() {}),
          );
        }

        if (!categoriesSnapshot.hasData) {
          return const _LoadingState();
        }

        final categories = categoriesSnapshot.data!;

        return StreamBuilder<List<BenefitModel>>(
          stream: widget.service.watchBenefits(),
          builder: (context, benefitsSnapshot) {
            if (benefitsSnapshot.hasError) {
              return _CenteredMessage(
                icon: Icons.error_outline_rounded,
                title: 'Erro ao carregar beneficios',
                message: benefitsSnapshot.error.toString(),
                actionLabel: 'Tentar novamente',
                onAction: () => setState(() {}),
              );
            }

            if (!benefitsSnapshot.hasData) {
              return const _LoadingState();
            }

            final benefits = benefitsSnapshot.data!;

            return Column(
              children: [
                _CatalogToolbar(
                  benefits: benefits,
                  categories: categories,
                  onCreate: () => _openBenefitForm(categories: categories),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child:
                      benefits.isEmpty
                          ? _CenteredMessage(
                            icon: Icons.card_giftcard_rounded,
                            title: 'Nenhum beneficio cadastrado',
                            message:
                                'Crie beneficios no catalogo antes de vincular aos colaboradores.',
                            actionLabel: 'Novo beneficio',
                            onAction:
                                () => _openBenefitForm(categories: categories),
                          )
                          : _BenefitsGrid(
                            benefits: benefits,
                            onEdit:
                                (benefit) => _openBenefitForm(
                                  benefit: benefit,
                                  categories: categories,
                                ),
                            onToggle: _toggleBenefit,
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openBenefitForm({
    BenefitModel? benefit,
    required List<BenefitCategoryModel> categories,
  }) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => _BenefitFormDialog(
            service: widget.service,
            benefit: benefit,
            categories: categories,
          ),
    );
  }

  Future<void> _toggleBenefit(BenefitModel benefit) async {
    try {
      await widget.service.toggleBenefit(benefit.id, !benefit.isActive);
      if (!mounted) return;
      _showSnack(
        context,
        benefit.isActive ? 'Beneficio desativado.' : 'Beneficio reativado.',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Erro ao atualizar beneficio: $error');
    }
  }
}

class _CategoriesTab extends StatefulWidget {
  final HrService service;

  const _CategoriesTab({required this.service});

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionToolbar(
          title: 'Categorias de beneficios',
          actionLabel: 'Nova categoria',
          actionIcon: Icons.category_rounded,
          onAction: () => _openForm(),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: StreamBuilder<List<BenefitCategoryModel>>(
            stream: widget.service.watchBenefitCategories(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _CenteredMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Erro ao carregar categorias',
                  message: snapshot.error.toString(),
                  actionLabel: 'Tentar novamente',
                  onAction: () => setState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const _LoadingState();
              }

              final categories = snapshot.data!;
              if (categories.isEmpty) {
                return _CenteredMessage(
                  icon: Icons.category_outlined,
                  title: 'Nenhuma categoria cadastrada',
                  message:
                      'Use categorias para organizar beneficios por vale, saude, seguro ou politica interna.',
                  actionLabel: 'Nova categoria',
                  onAction: () => _openForm(),
                );
              }

              return _CategoriesList(
                categories: categories,
                onEdit: _openForm,
                onToggle: _toggleCategory,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openForm([BenefitCategoryModel? category]) {
    return showDialog<void>(
      context: context,
      builder:
          (_) =>
              _CategoryFormDialog(service: widget.service, category: category),
    );
  }

  Future<void> _toggleCategory(BenefitCategoryModel category) async {
    try {
      await widget.service.toggleBenefitCategory(
        category.id,
        !category.isActive,
      );
      if (!mounted) return;
      _showSnack(
        context,
        category.isActive ? 'Categoria desativada.' : 'Categoria reativada.',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Erro ao atualizar categoria: $error');
    }
  }
}

class _EmployeeBenefitsTab extends StatefulWidget {
  final HrService service;

  const _EmployeeBenefitsTab({required this.service});

  @override
  State<_EmployeeBenefitsTab> createState() => _EmployeeBenefitsTabState();
}

class _EmployeeBenefitsTabState extends State<_EmployeeBenefitsTab> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EmployeeModel>>(
      stream: widget.service.watchEmployees(),
      builder: (context, employeesSnapshot) {
        if (employeesSnapshot.hasError) {
          return _CenteredMessage(
            icon: Icons.error_outline_rounded,
            title: 'Erro ao carregar colaboradores',
            message: employeesSnapshot.error.toString(),
            actionLabel: 'Tentar novamente',
            onAction: () => setState(() {}),
          );
        }

        if (!employeesSnapshot.hasData) {
          return const _LoadingState();
        }

        final employees = employeesSnapshot.data!;

        return StreamBuilder<List<BenefitModel>>(
          stream: widget.service.watchBenefits(onlyActive: true),
          builder: (context, benefitsSnapshot) {
            if (benefitsSnapshot.hasError) {
              return _CenteredMessage(
                icon: Icons.error_outline_rounded,
                title: 'Erro ao carregar beneficios',
                message: benefitsSnapshot.error.toString(),
                actionLabel: 'Tentar novamente',
                onAction: () => setState(() {}),
              );
            }

            if (!benefitsSnapshot.hasData) {
              return const _LoadingState();
            }

            final benefits = benefitsSnapshot.data!;

            return StreamBuilder<List<EmployeeBenefitModel>>(
              stream: widget.service.watchAllEmployeeBenefits(),
              builder: (context, assignmentsSnapshot) {
                if (assignmentsSnapshot.hasError) {
                  return _CenteredMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Erro ao carregar vinculos',
                    message: assignmentsSnapshot.error.toString(),
                    actionLabel: 'Tentar novamente',
                    onAction: () => setState(() {}),
                  );
                }

                if (!assignmentsSnapshot.hasData) {
                  return const _LoadingState();
                }

                final assignments = assignmentsSnapshot.data!;
                final activeAssignments =
                    assignments.where((item) => item.isActive).toList();

                return Column(
                  children: [
                    _AssignmentsToolbar(
                      activeCount: activeAssignments.length,
                      dailyTotal: activeAssignments.fold<double>(
                        0,
                        (sum, item) => sum + item.dailyValue,
                      ),
                      onCreate:
                          employees.isEmpty || benefits.isEmpty
                              ? null
                              : () => _openAssignmentForm(
                                employees: employees,
                                benefits: benefits,
                                assignments: assignments,
                              ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child:
                          assignments.isEmpty
                              ? _CenteredMessage(
                                icon: Icons.link_rounded,
                                title: 'Nenhum vinculo cadastrado',
                                message:
                                    employees.isEmpty || benefits.isEmpty
                                        ? 'Cadastre colaboradores e beneficios ativos antes de criar vinculos.'
                                        : 'Vincule colaboradores aos beneficios que eles recebem.',
                                actionLabel:
                                    employees.isEmpty || benefits.isEmpty
                                        ? null
                                        : 'Novo vinculo',
                                onAction:
                                    employees.isEmpty || benefits.isEmpty
                                        ? null
                                        : () => _openAssignmentForm(
                                          employees: employees,
                                          benefits: benefits,
                                          assignments: assignments,
                                        ),
                              )
                              : _AssignmentsList(
                                employees: employees,
                                benefits: benefits,
                                assignments: assignments,
                                onEdit:
                                    (assignment) => _openAssignmentForm(
                                      employees: employees,
                                      benefits: benefits,
                                      assignments: assignments,
                                      assignment: assignment,
                                    ),
                                onRemove: _removeAssignment,
                              ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openAssignmentForm({
    required List<EmployeeModel> employees,
    required List<BenefitModel> benefits,
    required List<EmployeeBenefitModel> assignments,
    EmployeeBenefitModel? assignment,
  }) {
    return showDialog<void>(
      context: context,
      builder:
          (_) => _AssignmentFormDialog(
            service: widget.service,
            employees: employees,
            benefits: benefits,
            assignments: assignments,
            assignment: assignment,
          ),
    );
  }

  Future<void> _removeAssignment(EmployeeBenefitModel assignment) async {
    try {
      await widget.service.removeBenefitFromEmployee(assignment.id);
      if (!mounted) return;
      _showSnack(context, 'Beneficio encerrado para o colaborador.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Erro ao encerrar vinculo: $error');
    }
  }
}

class _CatalogToolbar extends StatelessWidget {
  final List<BenefitModel> benefits;
  final List<BenefitCategoryModel> categories;
  final VoidCallback onCreate;

  const _CatalogToolbar({
    required this.benefits,
    required this.categories,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final activeBenefits = benefits.where((item) => item.isActive).length;
    final activeCategories = categories.where((item) => item.isActive).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final stats = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: 'Ativos',
              value: '$activeBenefits',
              color: AppColors.accentGreen,
            ),
            _StatPill(
              label: 'Categorias',
              value: '$activeCategories',
              color: AppColors.accentBlue,
            ),
          ],
        );
        final button = SizedBox(
          width: compact ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Novo beneficio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [stats, const SizedBox(height: 12), button],
          );
        }

        return Row(children: [Expanded(child: stats), button]);
      },
    );
  }
}

class _AssignmentsToolbar extends StatelessWidget {
  final int activeCount;
  final double dailyTotal;
  final VoidCallback? onCreate;

  const _AssignmentsToolbar({
    required this.activeCount,
    required this.dailyTotal,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final stats = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: 'Vinculos ativos',
              value: '$activeCount',
              color: AppColors.accentGreen,
            ),
            _StatPill(
              label: 'Custo diario',
              value: currency.format(dailyTotal),
              color: AppColors.accentGold,
            ),
          ],
        );
        final button = SizedBox(
          width: compact ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Novo vinculo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [stats, const SizedBox(height: 12), button],
          );
        }

        return Row(children: [Expanded(child: stats), button]);
      },
    );
  }
}

class _BenefitsGrid extends StatelessWidget {
  final List<BenefitModel> benefits;
  final ValueChanged<BenefitModel> onEdit;
  final ValueChanged<BenefitModel> onToggle;

  const _BenefitsGrid({
    required this.benefits,
    required this.onEdit,
    required this.onToggle,
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
            mainAxisExtent: constraints.maxWidth < 420 ? 252 : 228,
          ),
          itemCount: benefits.length,
          itemBuilder: (context, index) {
            final benefit = benefits[index];
            return _BenefitCard(
              benefit: benefit,
              onEdit: () => onEdit(benefit),
              onToggle: () => onToggle(benefit),
            );
          },
        );
      },
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final BenefitModel benefit;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _BenefitCard({
    required this.benefit,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final statusColor =
        benefit.isActive ? AppColors.accentGreen : AppColors.textMuted;
    final category =
        benefit.categoryName.trim().isEmpty
            ? 'Sem categoria'
            : benefit.categoryName.trim();
    final valueLabel =
        benefit.valueMode == BenefitValueMode.reimbursement
            ? 'Limite ${currency.format(benefit.reimbursementLimit)}'
            : 'Diaria ${currency.format(benefit.dailyValue)}';

    return _SurfaceTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TileIcon(
                icon: Icons.card_giftcard_rounded,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  benefit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<_TileAction>(
                tooltip: 'Acoes',
                color: AppColors.surfaceDark,
                icon: const Icon(
                  Icons.more_vert_rounded,
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
                              benefit.isActive
                                  ? Icons.toggle_off_rounded
                                  : Icons.toggle_on_rounded,
                          label: benefit.isActive ? 'Desativar' : 'Reativar',
                        ),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(
                label: _benefitTypeLabel(benefit.type),
                color: AppColors.accentBlue,
              ),
              _StatusBadge(label: category, color: AppColors.accentGold),
              _StatusBadge(
                label: benefit.valueModeLabel,
                color:
                    benefit.valueMode == BenefitValueMode.reimbursement
                        ? AppColors.accentGreen
                        : AppColors.accentBlue,
              ),
              _StatusBadge(label: valueLabel, color: AppColors.textMuted),
              _StatusBadge(
                label: benefit.isActive ? 'Ativo' : 'Inativo',
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              benefit.description.isEmpty
                  ? 'Sem descricao cadastrada.'
                  : benefit.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  final List<BenefitCategoryModel> categories;
  final ValueChanged<BenefitCategoryModel> onEdit;
  final ValueChanged<BenefitCategoryModel> onToggle;

  const _CategoriesList({
    required this.categories,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryTile(
          category: category,
          onEdit: () => onEdit(category),
          onToggle: () => onToggle(category),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final BenefitCategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceTile(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TileIcon(
            icon: Icons.category_rounded,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      label: category.isActive ? 'Ativa' : 'Inativa',
                      color:
                          category.isActive
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                    ),
                  ],
                ),
                if (category.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    category.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_TileAction>(
            tooltip: 'Acoes',
            color: AppColors.surfaceDark,
            icon: const Icon(
              Icons.more_vert_rounded,
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
                          category.isActive
                              ? Icons.toggle_off_rounded
                              : Icons.toggle_on_rounded,
                      label: category.isActive ? 'Desativar' : 'Reativar',
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}

class _AssignmentsList extends StatelessWidget {
  final List<EmployeeModel> employees;
  final List<BenefitModel> benefits;
  final List<EmployeeBenefitModel> assignments;
  final ValueChanged<EmployeeBenefitModel> onEdit;
  final ValueChanged<EmployeeBenefitModel> onRemove;

  const _AssignmentsList({
    required this.employees,
    required this.benefits,
    required this.assignments,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final employeesById = {
      for (final employee in employees) employee.id: employee,
    };
    final benefitsById = {for (final benefit in benefits) benefit.id: benefit};
    final sorted = [...assignments]..sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      final employeeA = employeesById[a.employeeId]?.name ?? '';
      final employeeB = employeesById[b.employeeId]?.name ?? '';
      return employeeA.toLowerCase().compareTo(employeeB.toLowerCase());
    });

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = sorted[index];
        return _AssignmentTile(
          assignment: assignment,
          employeeName:
              employeesById[assignment.employeeId]?.name ??
              'Colaborador nao encontrado',
          benefit: benefitsById[assignment.benefitId],
          onEdit: () => onEdit(assignment),
          onRemove: assignment.isActive ? () => onRemove(assignment) : null,
        );
      },
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final EmployeeBenefitModel assignment;
  final String employeeName;
  final BenefitModel? benefit;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  const _AssignmentTile({
    required this.assignment,
    required this.employeeName,
    required this.benefit,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final category = benefit?.categoryName.trim() ?? '';
    final isReimbursement =
        benefit?.valueMode == BenefitValueMode.reimbursement;

    return _SurfaceTile(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TileIcon(
            icon: Icons.link_rounded,
            color: AppColors.accentGold,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      label: assignment.isActive ? 'Ativo' : 'Encerrado',
                      color:
                          assignment.isActive
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  assignment.benefitName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusBadge(
                      label:
                          isReimbursement
                              ? 'Limite ${currency.format(assignment.dailyValue)}'
                              : 'Diaria ${currency.format(assignment.dailyValue)}',
                      color: AppColors.accentGold,
                    ),
                    if (isReimbursement)
                      _StatusBadge(
                        label: 'Reembolso',
                        color: AppColors.accentGreen,
                      ),
                    _StatusBadge(
                      label:
                          'Inicio ${dateFormat.format(assignment.startDate)}',
                      color: AppColors.accentBlue,
                    ),
                    if (category.isNotEmpty)
                      _StatusBadge(label: category, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<_AssignmentAction>(
            tooltip: 'Acoes',
            color: AppColors.surfaceDark,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
            ),
            onSelected: (action) {
              switch (action) {
                case _AssignmentAction.edit:
                  onEdit();
                  break;
                case _AssignmentAction.remove:
                  onRemove?.call();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: _AssignmentAction.edit,
                    child: _PopupActionLabel(
                      icon: Icons.edit_rounded,
                      label: 'Editar',
                    ),
                  ),
                  if (onRemove != null)
                    const PopupMenuItem(
                      value: _AssignmentAction.remove,
                      child: _PopupActionLabel(
                        icon: Icons.link_off_rounded,
                        label: 'Encerrar',
                      ),
                    ),
                ],
          ),
        ],
      ),
    );
  }
}

class _BenefitFormDialog extends StatefulWidget {
  final HrService service;
  final BenefitModel? benefit;
  final List<BenefitCategoryModel> categories;

  const _BenefitFormDialog({
    required this.service,
    required this.categories,
    this.benefit,
  });

  @override
  State<_BenefitFormDialog> createState() => _BenefitFormDialogState();
}

class _BenefitFormDialogState extends State<_BenefitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _dailyValueCtrl = TextEditingController();
  final _reimbursementLimitCtrl = TextEditingController();
  BenefitType _type = BenefitType.vr;
  String? _categoryId;
  BenefitValueMode _valueMode = BenefitValueMode.workedDay;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.benefit != null;

  @override
  void initState() {
    super.initState();
    final benefit = widget.benefit;
    if (benefit != null) {
      _nameCtrl.text = benefit.name;
      _descriptionCtrl.text = benefit.description;
      _dailyValueCtrl.text = benefit.dailyValue.toStringAsFixed(2);
      _reimbursementLimitCtrl.text = benefit.reimbursementLimit.toStringAsFixed(
        2,
      );
      _type = benefit.type;
      _categoryId = benefit.categoryId;
      _valueMode = benefit.valueMode;
      _isActive = benefit.isActive;
    } else {
      _dailyValueCtrl.text = '0.00';
      _reimbursementLimitCtrl.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _dailyValueCtrl.dispose();
    _reimbursementLimitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryStillExists =
        _categoryId == null ||
        widget.categories.any((category) => category.id == _categoryId);
    final initialCategoryId = categoryStillExists ? _categoryId : null;
    final dialogWidth =
        (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 500.0).toDouble();
    final dialogMaxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEdit ? 'Editar beneficio' : 'Novo beneficio'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o nome'
                                : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<BenefitType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    dropdownColor: AppColors.surfaceDark,
                    items:
                        BenefitType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(_benefitTypeLabel(type)),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String?>(
                    initialValue: initialCategoryId,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    dropdownColor: AppColors.surfaceDark,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sem categoria'),
                      ),
                      ...widget.categories.map(
                        (category) => DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<BenefitValueMode>(
                    initialValue: _valueMode,
                    decoration: const InputDecoration(
                      labelText: 'Forma de valor',
                    ),
                    dropdownColor: AppColors.surfaceDark,
                    items:
                        const [
                              BenefitValueMode.workedDay,
                              BenefitValueMode.reimbursement,
                            ]
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(_benefitValueModeLabel(mode)),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _valueMode = value!),
                  ),
                  const SizedBox(height: 14),
                  if (_valueMode == BenefitValueMode.workedDay)
                    TextFormField(
                      controller: _dailyValueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor por dia trabalhado padrao',
                        prefixText: 'R\$ ',
                      ),
                      validator: _validateMoney,
                    )
                  else
                    TextFormField(
                      controller: _reimbursementLimitCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Limite de reembolso',
                        prefixText: 'R\$ ',
                      ),
                      validator: _validateMoney,
                    ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descricao'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Beneficio ativo'),
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

  String? _validateMoney(String? value) {
    final parsed = _parseMoney(value ?? '');
    if (parsed == null || parsed < 0) {
      return 'Informe um valor valido';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.benefit;
    final category = _selectedCategory();
    final dailyValue =
        _valueMode == BenefitValueMode.workedDay
            ? _parseMoney(_dailyValueCtrl.text) ?? 0
            : 0.0;
    final reimbursementLimit =
        _valueMode == BenefitValueMode.reimbursement
            ? _parseMoney(_reimbursementLimitCtrl.text) ?? 0
            : 0.0;
    final benefit =
        existing == null
            ? BenefitModel(
              id: '',
              name: _nameCtrl.text.trim(),
              type: _type,
              categoryId: category?.id,
              categoryName: category?.name ?? '',
              valueMode: _valueMode,
              dailyValue: dailyValue,
              reimbursementLimit: reimbursementLimit,
              description: _descriptionCtrl.text.trim(),
              isActive: _isActive,
              createdAt: now,
            )
            : existing.copyWith(
              name: _nameCtrl.text.trim(),
              type: _type,
              categoryId: category?.id,
              categoryName: category?.name,
              clearCategory: category == null,
              valueMode: _valueMode,
              dailyValue: dailyValue,
              reimbursementLimit: reimbursementLimit,
              description: _descriptionCtrl.text.trim(),
              isActive: _isActive,
            );

    try {
      if (existing == null) {
        await widget.service.addBenefit(benefit);
      } else {
        await widget.service.updateBenefit(benefit);
      }
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(
        context,
        existing == null ? 'Beneficio cadastrado.' : 'Beneficio atualizado.',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Erro ao salvar beneficio: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  BenefitCategoryModel? _selectedCategory() {
    final id = _categoryId;
    if (id == null) return null;
    for (final category in widget.categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final HrService service;
  final BenefitCategoryModel? category;

  const _CategoryFormDialog({required this.service, this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      _nameCtrl.text = category.name;
      _descriptionCtrl.text = category.description;
      _isActive = category.isActive;
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
    final dialogWidth =
        (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 460.0).toDouble();
    final dialogMaxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEdit ? 'Editar categoria' : 'Nova categoria'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
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
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Categoria ativa'),
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
    final existing = widget.category;
    final category =
        existing == null
            ? BenefitCategoryModel(
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
      if (existing == null) {
        await widget.service.addBenefitCategory(category);
      } else {
        await widget.service.updateBenefitCategory(category);
      }
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(
        context,
        existing == null ? 'Categoria cadastrada.' : 'Categoria atualizada.',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Erro ao salvar categoria: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AssignmentFormDialog extends StatefulWidget {
  final HrService service;
  final List<EmployeeModel> employees;
  final List<BenefitModel> benefits;
  final List<EmployeeBenefitModel> assignments;
  final EmployeeBenefitModel? assignment;

  const _AssignmentFormDialog({
    required this.service,
    required this.employees,
    required this.benefits,
    required this.assignments,
    this.assignment,
  });

  @override
  State<_AssignmentFormDialog> createState() => _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends State<_AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueCtrl = TextEditingController();
  String? _employeeId;
  String? _benefitId;
  DateTime _startDate = DateTime.now();
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    if (assignment != null) {
      _employeeId = assignment.employeeId;
      _benefitId = assignment.benefitId;
      _valueCtrl.text = assignment.dailyValue.toStringAsFixed(2);
      _startDate = assignment.startDate;
      _isActive = assignment.isActive;
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEmployees =
        widget.employees.where((employee) => !employee.isDismissed).toList();
    final initialEmployee =
        activeEmployees.any((employee) => employee.id == _employeeId)
            ? _employeeId
            : null;
    final initialBenefit =
        widget.benefits.any((benefit) => benefit.id == _benefitId)
            ? _benefitId
            : null;
    final selectedBenefit = _selectedBenefit();
    final valueLabel =
        selectedBenefit?.valueMode == BenefitValueMode.reimbursement
            ? 'Limite de reembolso'
            : 'Valor por dia trabalhado';
    final dialogWidth =
        (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 520.0).toDouble();
    final dialogMaxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(_isEdit ? 'Editar vinculo' : 'Novo vinculo'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: initialEmployee,
                    decoration: const InputDecoration(labelText: 'Colaborador'),
                    dropdownColor: AppColors.surfaceDark,
                    items:
                        activeEmployees
                            .map(
                              (employee) => DropdownMenuItem(
                                value: employee.id,
                                child: Text(employee.name),
                              ),
                            )
                            .toList(),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Selecione o colaborador'
                                : null,
                    onChanged: (value) => setState(() => _employeeId = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: initialBenefit,
                    decoration: const InputDecoration(labelText: 'Beneficio'),
                    dropdownColor: AppColors.surfaceDark,
                    items:
                        widget.benefits
                            .map(
                              (benefit) => DropdownMenuItem(
                                value: benefit.id,
                                child: Text(benefit.name),
                              ),
                            )
                            .toList(),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Selecione o beneficio'
                                : null,
                    onChanged: _selectBenefit,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: valueLabel,
                      prefixText: 'R\$ ',
                    ),
                    validator: (value) {
                      final parsed = _parseMoney(value ?? '');
                      if (parsed == null || parsed < 0) {
                        return 'Informe um valor valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _DatePickerTile(
                    label: 'Inicio do beneficio',
                    date: _startDate,
                    onPick: _pickStartDate,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vinculo ativo'),
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
          label: Text(_isEdit ? 'Salvar' : 'Vincular'),
        ),
      ],
    );
  }

  void _selectBenefit(String? value) {
    setState(() {
      final changed = _benefitId != value;
      _benefitId = value;
      if (!changed) return;

      final selected = _selectedBenefit();
      final suggested = selected?.suggestedAssignmentValue ?? 0;
      _valueCtrl.text = suggested.toStringAsFixed(2);
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasDuplicateActiveAssignment()) {
      _showSnack(context, 'Este colaborador ja possui esse beneficio ativo.');
      return;
    }

    setState(() => _saving = true);
    final existing = widget.assignment;
    final benefit = _selectedBenefit();
    final value = _parseMoney(_valueCtrl.text) ?? 0;
    final endDate =
        _isActive ? existing?.endDate : existing?.endDate ?? DateTime.now();
    final assignment =
        existing == null
            ? EmployeeBenefitModel(
              id: '',
              employeeId: _employeeId!,
              benefitId: _benefitId!,
              benefitName: benefit?.name ?? '',
              dailyValue: value,
              startDate: _startDate,
              isActive: _isActive,
              endDate: endDate,
            )
            : existing.copyWith(
              employeeId: _employeeId,
              benefitId: _benefitId,
              benefitName: benefit?.name,
              dailyValue: value,
              startDate: _startDate,
              isActive: _isActive,
              endDate: endDate,
              clearEndDate: _isActive,
            );

    try {
      if (existing == null) {
        await widget.service.assignBenefit(assignment);
      } else {
        await widget.service.updateEmployeeBenefit(assignment);
      }
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(
        context,
        existing == null ? 'Beneficio vinculado.' : 'Vinculo atualizado.',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, 'Erro ao salvar vinculo: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _hasDuplicateActiveAssignment() {
    final employeeId = _employeeId;
    final benefitId = _benefitId;
    if (employeeId == null || benefitId == null || !_isActive) return false;

    return widget.assignments.any(
      (assignment) =>
          assignment.id != widget.assignment?.id &&
          assignment.isActive &&
          assignment.employeeId == employeeId &&
          assignment.benefitId == benefitId,
    );
  }

  BenefitModel? _selectedBenefit() {
    final id = _benefitId;
    if (id == null) return null;
    for (final benefit in widget.benefits) {
      if (benefit.id == id) return benefit;
    }
    return null;
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onPick;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy').format(date);

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_month_rounded),
        ),
        child: Text(
          dateText,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _BenefitsTopBar extends StatelessWidget {
  final TabController tabController;

  const _BenefitsTopBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Row(
          children: [
            const _HeaderIcon(),
            const SizedBox(width: 14),
            const Expanded(child: _HeaderTitle()),
          ],
        );
        final tabs = _BenefitsTabBar(tabController: tabController);

        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: tabs),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            SizedBox(width: 390, child: tabs),
          ],
        );
      },
    );
  }
}

class _BenefitsTabBar extends StatelessWidget {
  final TabController tabController;

  const _BenefitsTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = constraints.maxWidth < 330;

        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondaryDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor),
          ),
          padding: const EdgeInsets.all(3),
          child: TabBar(
            controller: tabController,
            isScrollable: false,
            indicator: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.3),
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.accentGold,
            unselectedLabelColor: AppColors.textMuted,
            labelPadding: EdgeInsets.zero,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              _BenefitNavTab(
                icon: Icons.card_giftcard_rounded,
                label: 'Catalogo',
                iconOnly: iconOnly,
              ),
              _BenefitNavTab(
                icon: Icons.category_rounded,
                label: 'Categorias',
                iconOnly: iconOnly,
              ),
              _BenefitNavTab(
                icon: Icons.link_rounded,
                label: 'Vinculos',
                iconOnly: iconOnly,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BenefitNavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool iconOnly;

  const _BenefitNavTab({
    required this.icon,
    required this.label,
    required this.iconOnly,
  });

  @override
  Widget build(BuildContext context) {
    final content = Tab(
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15),
          if (!iconOnly) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );

    return iconOnly ? Tooltip(message: label, child: content) : content;
  }
}

class _SectionToolbar extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _SectionToolbar({
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < ResponsiveLayout.compact;
        final heading = Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        );
        final button = SizedBox(
          width: compact ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 18),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: AppColors.primaryDark,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 12), button],
          );
        }

        return Row(children: [Expanded(child: heading), button]);
      },
    );
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
        Icons.card_giftcard_rounded,
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
          'Gestao de beneficios',
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
          'Catalogo, categorias e vinculos com colaboradores',
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
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

enum _TileAction { edit, toggle }

enum _AssignmentAction { edit, remove }

String _benefitTypeLabel(BenefitType type) => switch (type) {
  BenefitType.vt => 'Vale Transporte',
  BenefitType.vr => 'Vale Refeicao',
  BenefitType.health => 'Plano de Saude',
  BenefitType.dental => 'Plano Odontologico',
  BenefitType.lifeInsurance => 'Seguro de Vida',
  BenefitType.other => 'Outro',
};

String _benefitValueModeLabel(BenefitValueMode mode) => switch (mode) {
  BenefitValueMode.workedDay => 'Por dia trabalhado',
  BenefitValueMode.reimbursement => 'Reembolso',
  BenefitValueMode.fixedMonthly => 'Por dia trabalhado',
};

double? _parseMoney(String value) {
  final cleaned = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (cleaned.isEmpty) return null;
  final normalized =
      cleaned.contains(',')
          ? cleaned.replaceAll('.', '').replaceAll(',', '.')
          : cleaned;
  return double.tryParse(normalized);
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
