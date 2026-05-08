import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/constants/budget_type_constants.dart';
import 'package:project_granith/controllers/budget_type_controller.dart';
import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/services/budget_type_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/Budget_Type/budget_type_card.dart';
import 'package:project_granith/widgets/Budget_Type/budget_type_form_dialog.dart';

class BudgetTypesPageView extends StatelessWidget {
  final BudgetTypeController? controller;

  const BudgetTypesPageView({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BudgetTypeController>(
      create: (_) {
        final resolved =
            controller ?? BudgetTypeController(BudgetTypeService());
        resolved.loadBudgetTypes();
        return resolved;
      },
      child: const _BudgetTypesPageContent(),
    );
  }
}

class _BudgetTypesPageContent extends StatelessWidget {
  const _BudgetTypesPageContent();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          _BudgetTypesCommandHeader(),
          _BudgetTypesControls(),
          Expanded(child: _BudgetTypesBody()),
        ],
      ),
    );
  }
}

class _BudgetTypesCommandHeader extends StatelessWidget {
  const _BudgetTypesCommandHeader();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BudgetTypeController>();
    final width = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveLayout.pagePadding(width);
    final activeCount =
        controller.budgetTypes.where((type) => type.isActive).length;
    final inactiveCount = controller.budgetTypes.length - activeCount;
    final categoryCount =
        controller.budgetTypes
            .map((type) => type.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .length;
    final compact = width < 760;

    final title = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accentGold.withValues(alpha: 0.28),
            ),
          ),
          child: const Icon(
            Icons.request_quote_rounded,
            color: AppColors.accentGold,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipos de Orçamento',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                controller.isLoading
                    ? 'Carregando catálogo comercial'
                    : '${controller.filteredBudgetTypes.length} em exibição',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        compact ? 14 : 18,
        padding.right,
        compact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            title,
            const SizedBox(height: 12),
            const _BudgetTypesHeaderActions(stretch: true),
          ] else
            Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 20),
                const _BudgetTypesHeaderActions(),
              ],
            ),
          const SizedBox(height: 14),
          _BudgetTypesMetrics(
            totalCount: controller.budgetTypes.length,
            activeCount: activeCount,
            inactiveCount: inactiveCount,
            categoryCount: categoryCount,
          ),
        ],
      ),
    );
  }
}

class _BudgetTypesHeaderActions extends StatelessWidget {
  final bool stretch;

  const _BudgetTypesHeaderActions({this.stretch = false});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BudgetTypeController>();
    final actions = [
      _HeaderIconButton(
        icon: Icons.refresh_rounded,
        tooltip: 'Atualizar',
        onPressed:
            controller.isLoading
                ? null
                : () => context.read<BudgetTypeController>().loadBudgetTypes(
                  forceRefresh: true,
                ),
      ),
      const _BudgetTypesViewToggle(),
      ElevatedButton.icon(
        onPressed: () => showBudgetTypeForm(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Novo tipo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ];

    if (stretch) {
      return Row(
        children: [
          actions[0],
          const SizedBox(width: 8),
          actions[1],
          const SizedBox(width: 10),
          Expanded(child: actions[2]),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        actions[0],
        const SizedBox(width: 8),
        actions[1],
        const SizedBox(width: 12),
        actions[2],
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.textSecondary,
        disabledColor: AppColors.textMuted,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.55),
          side: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.35),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          fixedSize: const Size(44, 44),
        ),
      ),
    );
  }
}

class _BudgetTypesViewToggle extends StatelessWidget {
  const _BudgetTypesViewToggle();

  @override
  Widget build(BuildContext context) {
    final isGrid = context.select((BudgetTypeController c) => c.isGridView);

    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: Icons.grid_view_rounded,
            selected: isGrid,
            tooltip: 'Grade',
            onTap: () => context.read<BudgetTypeController>().setViewMode(true),
          ),
          _ViewToggleButton(
            icon: Icons.view_list_rounded,
            selected: !isGrid,
            tooltip: 'Lista',
            onTap:
                () => context.read<BudgetTypeController>().setViewMode(false),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.accentGold.withValues(alpha: 0.16)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? AppColors.accentGold : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _BudgetTypesMetrics extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final int categoryCount;

  const _BudgetTypesMetrics({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetricPill(
          icon: Icons.inventory_2_outlined,
          label: 'Total',
          value: totalCount.toString(),
          color: AppColors.accentGold,
        ),
        _MetricPill(
          icon: Icons.check_circle_outline_rounded,
          label: 'Ativos',
          value: activeCount.toString(),
          color: AppColors.accentGreen,
        ),
        _MetricPill(
          icon: Icons.visibility_off_outlined,
          label: 'Inativos',
          value: inactiveCount.toString(),
          color: AppColors.textMuted,
        ),
        _MetricPill(
          icon: Icons.account_tree_outlined,
          label: 'Categorias',
          value: categoryCount.toString(),
          color: AppColors.accentBlue,
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132, minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTypesControls extends StatefulWidget {
  const _BudgetTypesControls();

  @override
  State<_BudgetTypesControls> createState() => _BudgetTypesControlsState();
}

class _BudgetTypesControlsState extends State<_BudgetTypesControls> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BudgetTypeController>();
    final width = MediaQuery.sizeOf(context).width;
    final padding = ResponsiveLayout.pagePadding(width);

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, 14, padding.right, 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondaryDark.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.35),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final search = _BudgetTypeSearchField(
              controller: _searchController,
              hasText: controller.searchQuery.isNotEmpty,
              onClear: () {
                _searchController.clear();
                context.read<BudgetTypeController>().updateSearchQuery('');
              },
            );
            final filters = _BudgetTypeFilterStrip(
              selectedFilter: controller.selectedFilter,
              options: controller.filterOptions,
              onChanged: context.read<BudgetTypeController>().updateFilter,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  const SizedBox(height: 10),
                  filters,
                  if (controller.hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _ClearFiltersButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<BudgetTypeController>().clearFilters();
                        },
                      ),
                    ),
                  ],
                ],
              );
            }

            return Row(
              children: [
                SizedBox(width: 340, child: search),
                const SizedBox(width: 12),
                Expanded(child: filters),
                if (controller.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  _ClearFiltersButton(
                    onPressed: () {
                      _searchController.clear();
                      context.read<BudgetTypeController>().clearFilters();
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BudgetTypeSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onClear;

  const _BudgetTypeSearchField({
    required this.controller,
    required this.hasText,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar tipo, categoria ou descrição',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon:
              hasText
                  ? IconButton(
                    tooltip: 'Limpar busca',
                    onPressed: onClear,
                    icon: const Icon(Icons.clear, color: AppColors.textMuted),
                  )
                  : null,
          filled: true,
          fillColor: AppColors.backgroundDark.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accentGold),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onChanged:
            (value) =>
                context.read<BudgetTypeController>().updateSearchQuery(value),
      ),
    );
  }
}

class _BudgetTypeFilterStrip extends StatelessWidget {
  final String selectedFilter;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _BudgetTypeFilterStrip({
    required this.selectedFilter,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return _FilterToken(
            label: option,
            selected: selectedFilter == option,
            color: _filterColor(option),
            icon: _filterIcon(option),
            onTap: () => onChanged(option),
          );
        },
      ),
    );
  }

  Color _filterColor(String filter) {
    if (filter == 'Todos') return AppColors.accentGold;
    if (filter == 'Ativos') return AppColors.accentGreen;
    if (filter == 'Inativos') return AppColors.textMuted;
    return BudgetTypeConstants.categoryColors[filter] ?? AppColors.accentBlue;
  }

  IconData _filterIcon(String filter) {
    if (filter == 'Todos') return Icons.apps_rounded;
    if (filter == 'Ativos') return Icons.check_circle_outline_rounded;
    if (filter == 'Inativos') return Icons.visibility_off_outlined;
    return BudgetTypeConstants.categoryIcons[filter] ?? Icons.category;
  }
}

class _FilterToken extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterToken({
    required this.label,
    required this.selected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 86),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? color.withValues(alpha: 0.16)
                  : AppColors.backgroundDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected
                    ? color.withValues(alpha: 0.58)
                    : AppColors.borderColor.withValues(alpha: 0.26),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearFiltersButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ClearFiltersButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
      label: const Text('Limpar'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _BudgetTypesBody extends StatelessWidget {
  const _BudgetTypesBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BudgetTypeController>();

    if (controller.hasError) {
      return _BudgetTypesStateView(
        icon: Icons.error_outline_rounded,
        title: 'Erro ao carregar tipos de orçamento',
        message: controller.errorMessage ?? 'Tente atualizar a página.',
        actionLabel: 'Tentar novamente',
        onAction:
            () => context.read<BudgetTypeController>().loadBudgetTypes(
              forceRefresh: true,
            ),
      );
    }

    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    final budgetTypes = controller.filteredBudgetTypes;

    if (budgetTypes.isEmpty) {
      return _BudgetTypesStateView(
        icon: Icons.category_outlined,
        title: 'Nenhum tipo encontrado',
        message:
            controller.hasActiveFilters
                ? 'Ajuste a busca ou remova os filtros ativos.'
                : 'O catálogo comercial ainda está vazio.',
        actionLabel: controller.hasActiveFilters ? null : 'Novo tipo',
        onAction:
            controller.hasActiveFilters
                ? null
                : () => showBudgetTypeForm(context),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveLayout.pagePadding(width);
        final gap = ResponsiveLayout.gap(width);

        if (controller.isGridView && width >= 620) {
          final columns = ResponsiveLayout.columnsFor(
            width,
            mediumColumns: BudgetTypeConstants.tabletGridColumns,
            expandedColumns: BudgetTypeConstants.desktopGridColumns,
          );

          return GridView.builder(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              6,
              padding.right,
              padding.bottom + 24,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              mainAxisExtent: 188,
            ),
            itemCount: budgetTypes.length,
            itemBuilder:
                (context, index) => _BudgetTypeTile(
                  budgetType: budgetTypes[index],
                  isListView: false,
                ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            6,
            padding.right,
            padding.bottom + 24,
          ),
          itemCount: budgetTypes.length,
          separatorBuilder: (_, __) => SizedBox(height: gap),
          itemBuilder:
              (context, index) => _BudgetTypeTile(
                budgetType: budgetTypes[index],
                isListView: true,
              ),
        );
      },
    );
  }
}

class _BudgetTypeTile extends StatelessWidget {
  final BudgetType budgetType;
  final bool isListView;

  const _BudgetTypeTile({required this.budgetType, required this.isListView});

  @override
  Widget build(BuildContext context) {
    return BudgetTypeCard(
      budgetType: budgetType,
      isListView: isListView,
      onTap: () => _showForm(context, budgetType),
      onEdit: () => _showForm(context, budgetType),
      onDelete: () => _confirmDelete(context, budgetType),
      onToggleStatus: () => _toggleStatus(context, budgetType),
    );
  }

  Future<void> _showForm(BuildContext context, BudgetType budgetType) {
    return showBudgetTypeForm(context, budgetType: budgetType);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BudgetType budgetType,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Excluir tipo de orçamento?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'O tipo "${budgetType.name}" será removido do cadastro.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: AppColors.accentRed),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    final controller = context.read<BudgetTypeController>();
    final success = await controller.deleteBudgetType(budgetType.id);
    if (!context.mounted) return;

    _showSnack(
      context,
      success
          ? 'Tipo de orçamento excluído.'
          : controller.errorMessage ?? 'Erro ao excluir tipo de orçamento.',
      success ? AppColors.accentGreen : AppColors.accentRed,
    );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    BudgetType budgetType,
  ) async {
    final controller = context.read<BudgetTypeController>();
    final success = await controller.toggleBudgetTypeStatus(
      budgetType.id,
      !budgetType.isActive,
    );

    if (!context.mounted) return;

    _showSnack(
      context,
      success
          ? (budgetType.isActive
              ? 'Tipo de orçamento desativado.'
              : 'Tipo de orçamento ativado.')
          : controller.errorMessage ?? 'Erro ao alterar status.',
      success ? AppColors.accentGreen : AppColors.accentRed,
    );
  }
}

class _BudgetTypesStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _BudgetTypesStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 54,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showBudgetTypeForm(
  BuildContext context, {
  BudgetType? budgetType,
}) {
  return showDialog(
    context: context,
    builder:
        (_) => BudgetTypeFormDialog(
          budgetType: budgetType,
          onSave: (value) async {
            final controller = context.read<BudgetTypeController>();
            final success =
                value.id.isEmpty
                    ? await controller.createBudgetType(value)
                    : await controller.updateBudgetType(value);

            if (!context.mounted) return;

            _showSnack(
              context,
              success
                  ? (value.id.isEmpty
                      ? 'Tipo de orçamento cadastrado.'
                      : 'Tipo de orçamento atualizado.')
                  : controller.errorMessage ??
                      'Erro ao salvar tipo de orçamento.',
              success ? AppColors.accentGreen : AppColors.accentRed,
            );
          },
        ),
  );
}

void _showSnack(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
