import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/constants/supplier_constants.dart';
import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/models/supplier_model.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';
import 'package:project_granith/widgets/supplier/cnpj_lookup_dialog.dart';
import 'package:project_granith/widgets/supplier/supplier_card.dart';
import 'package:project_granith/widgets/supplier/supplier_form_dialog.dart';
import 'package:project_granith/widgets/supplier/suppliers_header.dart';

enum _SupplierSortOption {
  nameAsc,
  activeFirst,
  inactiveFirst,
  createdDesc,
  updatedDesc,
}

class SuppliersPageView extends StatelessWidget {
  final SupplierController? controller;

  const SuppliersPageView({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    final injectedController = controller;
    if (injectedController != null) {
      return ChangeNotifierProvider<SupplierController>.value(
        value: injectedController,
        child: const _SuppliersPageContent(),
      );
    }

    return ChangeNotifierProvider<SupplierController>(
      create: (_) => SupplierController(SupplierService())..loadSuppliers(),
      child: const _SuppliersPageContent(),
    );
  }
}

class _SuppliersPageContent extends StatefulWidget {
  const _SuppliersPageContent();

  @override
  State<_SuppliersPageContent> createState() => _SuppliersPageContentState();
}

class _SuppliersPageContentState extends State<_SuppliersPageContent> {
  static const int _initialVisibleItems = 24;
  static const int _visibleItemsStep = 24;

  final TextEditingController _searchController = TextEditingController();
  _SupplierSortOption _sortOption = _SupplierSortOption.nameAsc;
  int _visibleCount = _initialVisibleItems;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > ResponsiveLayout.compact;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(width),
          child: Consumer<SupplierController>(
            builder: (context, controller, _) {
              final sortedSuppliers = _sortedSuppliers(
                controller.filteredSuppliers,
              );
              final visibleSuppliers =
                  sortedSuppliers.take(_visibleCount).toList();
              final hasMore = visibleSuppliers.length < sortedSuppliers.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SuppliersHeader(
                    isDesktop: isDesktop,
                    onAddSupplier: () => _openSupplierForm(context),
                    onLookupCnpj: () => _openCnpjLookup(context),
                  ),
                  const SizedBox(height: 14),
                  _SupplierToolbar(
                    searchController: _searchController,
                    searchQuery: controller.searchQuery,
                    selectedFilter: controller.selectedFilter,
                    sortOption: _sortOption,
                    totalFilteredCount: sortedSuppliers.length,
                    totalCount: controller.suppliers.length,
                    hasActiveFilters: controller.hasActiveFilters,
                    onSearchChanged: (value) {
                      controller.updateSearchQuery(value);
                      _resetVisibleCount();
                    },
                    onClearSearch: () {
                      _searchController.clear();
                      controller.updateSearchQuery('');
                      _resetVisibleCount();
                    },
                    onFilterChanged: (filter) {
                      controller.updateFilter(filter);
                      _resetVisibleCount();
                    },
                    onClearFilters: () {
                      _searchController.clear();
                      controller.clearFilters();
                      _resetVisibleCount();
                    },
                    onSortChanged: (option) {
                      setState(() {
                        _sortOption = option;
                        _visibleCount = _initialVisibleItems;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _SuppliersBody(
                      controller: controller,
                      suppliers: visibleSuppliers,
                      totalFilteredCount: sortedSuppliers.length,
                      hasMore: hasMore,
                      onLoadMore: () {
                        setState(() {
                          _visibleCount += _visibleItemsStep;
                        });
                      },
                      onCreate: () => _openSupplierForm(context),
                      onClearFilters: () {
                        _searchController.clear();
                        controller.clearFilters();
                        _resetVisibleCount();
                      },
                      onRefresh:
                          () => controller.loadSuppliers(forceRefresh: true),
                      onView:
                          (supplier) => _openSupplierDetails(context, supplier),
                      onEdit:
                          (supplier) => _openSupplierForm(context, supplier),
                      onDelete:
                          (supplier) => _deleteSupplier(context, supplier),
                      onToggleStatus:
                          (supplier) =>
                              _toggleSupplierStatus(context, supplier),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _resetVisibleCount() {
    setState(() => _visibleCount = _initialVisibleItems);
  }

  List<Supplier> _sortedSuppliers(List<Supplier> suppliers) {
    final sorted = [...suppliers];
    sorted.sort((left, right) {
      switch (_sortOption) {
        case _SupplierSortOption.nameAsc:
          return left.name.toLowerCase().compareTo(right.name.toLowerCase());
        case _SupplierSortOption.activeFirst:
          final statusCompare = _statusRank(left).compareTo(_statusRank(right));
          if (statusCompare != 0) return statusCompare;
          return left.name.toLowerCase().compareTo(right.name.toLowerCase());
        case _SupplierSortOption.inactiveFirst:
          final statusCompare = _statusRank(right).compareTo(_statusRank(left));
          if (statusCompare != 0) return statusCompare;
          return left.name.toLowerCase().compareTo(right.name.toLowerCase());
        case _SupplierSortOption.createdDesc:
          return right.createdAt.compareTo(left.createdAt);
        case _SupplierSortOption.updatedDesc:
          return right.updatedAt.compareTo(left.updatedAt);
      }
    });
    return sorted;
  }

  int _statusRank(Supplier supplier) => supplier.isActive ? 0 : 1;

  Future<void> _openSupplierForm(BuildContext context, [Supplier? supplier]) {
    final controller = context.read<SupplierController>();
    return showDialog<void>(
      context: context,
      builder:
          (_) => SupplierFormDialog(
            supplier: supplier,
            onSave: (value) {
              return supplier == null
                  ? controller.createSupplier(value)
                  : controller.updateSupplier(value);
            },
          ),
    );
  }

  Future<void> _openCnpjLookup(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const CNPJLookupDialog(),
    );
  }

  Future<void> _openSupplierDetails(BuildContext context, Supplier supplier) {
    return showDialog<void>(
      context: context,
      builder: (_) => _SupplierDetailsDialog(supplier: supplier),
    );
  }

  Future<void> _toggleSupplierStatus(
    BuildContext context,
    Supplier supplier,
  ) async {
    try {
      await context.read<SupplierController>().toggleSupplierStatus(
        supplier.id,
        !supplier.isActive,
      );
      if (!context.mounted) return;
      _showSnack(
        context,
        supplier.isActive ? 'Fornecedor desativado.' : 'Fornecedor ativado.',
        AppColors.accentGreen,
      );
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(
        context,
        'Erro ao alterar status: $error',
        AppColors.accentRed,
      );
    }
  }

  Future<void> _deleteSupplier(BuildContext context, Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _SupplierConfirmDialog(supplier: supplier),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<SupplierController>().deleteSupplier(supplier.id);
      if (!context.mounted) return;
      _showSnack(context, 'Fornecedor excluido.', AppColors.accentGreen);
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(
        context,
        'Erro ao excluir fornecedor: $error',
        AppColors.accentRed,
      );
    }
  }

  void _showSnack(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SupplierToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedFilter;
  final _SupplierSortOption sortOption;
  final int totalFilteredCount;
  final int totalCount;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<_SupplierSortOption> onSortChanged;

  const _SupplierToolbar({
    required this.searchController,
    required this.searchQuery,
    required this.selectedFilter,
    required this.sortOption,
    required this.totalFilteredCount,
    required this.totalCount,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onClearFilters,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardSurface(elevated: false, radius: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final searchField = SizedBox(
            width: compact ? double.infinity : 360,
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Buscar fornecedor',
                hintText: 'Nome, CNPJ ou status',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    searchQuery.isEmpty
                        ? null
                        : IconButton(
                          tooltip: SupplierConstants.tooltipClearSearch,
                          onPressed: onClearSearch,
                          icon: const Icon(Icons.close_rounded),
                        ),
              ),
              onChanged: onSearchChanged,
            ),
          );
          final sortField = SizedBox(
            width: compact ? double.infinity : 240,
            child: DropdownButtonFormField<_SupplierSortOption>(
              initialValue: sortOption,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items:
                  _SupplierSortOption.values
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(_sortLabel(option)),
                        ),
                      )
                      .toList(),
              onChanged: (option) {
                if (option != null) onSortChanged(option);
              },
            ),
          );
          final filters = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SupplierFilterChip(
                label: 'Todos',
                selected: selectedFilter == SupplierConstants.filterAll,
                icon: Icons.all_inclusive_rounded,
                onSelected: () => onFilterChanged(SupplierConstants.filterAll),
              ),
              _SupplierFilterChip(
                label: 'Ativos',
                selected: selectedFilter == SupplierConstants.filterActive,
                icon: Icons.check_circle_rounded,
                color: AppColors.accentGreen,
                onSelected:
                    () => onFilterChanged(SupplierConstants.filterActive),
              ),
              _SupplierFilterChip(
                label: 'Inativos',
                selected: selectedFilter == SupplierConstants.filterInactive,
                icon: Icons.cancel_rounded,
                color: AppColors.accentRed,
                onSelected:
                    () => onFilterChanged(SupplierConstants.filterInactive),
              ),
              if (hasActiveFilters)
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Limpar'),
                ),
            ],
          );
          final resultCounter = _SupplierResultCounter(
            visibleCount: totalFilteredCount,
            totalCount: totalCount,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchField,
                const SizedBox(height: 12),
                sortField,
                const SizedBox(height: 12),
                filters,
                const SizedBox(height: 10),
                resultCounter,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  searchField,
                  const SizedBox(width: 12),
                  sortField,
                  const SizedBox(width: 12),
                  Expanded(child: filters),
                  const SizedBox(width: 12),
                  resultCounter,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _sortLabel(_SupplierSortOption option) {
    switch (option) {
      case _SupplierSortOption.nameAsc:
        return 'Nome';
      case _SupplierSortOption.activeFirst:
        return 'Ativos primeiro';
      case _SupplierSortOption.inactiveFirst:
        return 'Inativos primeiro';
      case _SupplierSortOption.createdDesc:
        return 'Cadastro recente';
      case _SupplierSortOption.updatedDesc:
        return 'Atualizacao recente';
    }
  }
}

class _SuppliersBody extends StatelessWidget {
  final SupplierController controller;
  final List<Supplier> suppliers;
  final int totalFilteredCount;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback onCreate;
  final VoidCallback onClearFilters;
  final VoidCallback onRefresh;
  final ValueChanged<Supplier> onView;
  final ValueChanged<Supplier> onEdit;
  final ValueChanged<Supplier> onDelete;
  final ValueChanged<Supplier> onToggleStatus;

  const _SuppliersBody({
    required this.controller,
    required this.suppliers,
    required this.totalFilteredCount,
    required this.hasMore,
    required this.onLoadMore,
    required this.onCreate,
    required this.onClearFilters,
    required this.onRefresh,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.suppliers.isEmpty) {
      return const _SupplierLoadingState();
    }

    if (controller.hasError && controller.suppliers.isEmpty) {
      return _SupplierLoadError(
        message: controller.errorMessage ?? SupplierConstants.errorGeneric,
        onRetry: onRefresh,
      );
    }

    if (controller.suppliers.isEmpty) {
      return _SupplierEmptyState(
        icon: Icons.business_rounded,
        title: 'Nenhum fornecedor cadastrado',
        message: 'Cadastre fornecedores para usar compras, cotacoes e estoque.',
        actionLabel: 'Novo fornecedor',
        onAction: onCreate,
      );
    }

    if (suppliers.isEmpty) {
      return _SupplierEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'Nenhum fornecedor encontrado.',
        message:
            'Ajuste a busca ou limpe os filtros para ver outros registros.',
        actionLabel: 'Limpar filtros',
        onAction: onClearFilters,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gap = ResponsiveLayout.gap(width);

        if (controller.isGridView && width >= 720) {
          final columns = ResponsiveLayout.columnsFor(
            width,
            mediumColumns: 2,
            expandedColumns: 3,
          );

          return CustomScrollView(
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SupplierCard(
                    supplier: suppliers[index],
                    isListView: false,
                    onTap: () => onView(suppliers[index]),
                    onEdit: () => onEdit(suppliers[index]),
                    onDelete: () => onDelete(suppliers[index]),
                    onToggleStatus: () => onToggleStatus(suppliers[index]),
                  ),
                  childCount: suppliers.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  mainAxisExtent: 244,
                ),
              ),
              if (hasMore)
                SliverToBoxAdapter(
                  child: _SupplierLoadMoreButton(
                    visibleCount: suppliers.length,
                    totalCount: totalFilteredCount,
                    onPressed: onLoadMore,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: suppliers.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: gap),
          itemBuilder: (context, index) {
            if (index >= suppliers.length) {
              return _SupplierLoadMoreButton(
                visibleCount: suppliers.length,
                totalCount: totalFilteredCount,
                onPressed: onLoadMore,
              );
            }

            final supplier = suppliers[index];
            return SupplierCard(
              supplier: supplier,
              isListView: true,
              onTap: () => onView(supplier),
              onEdit: () => onEdit(supplier),
              onDelete: () => onDelete(supplier),
              onToggleStatus: () => onToggleStatus(supplier),
            );
          },
        );
      },
    );
  }
}

class _SupplierFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData icon;
  final Color color;

  const _SupplierFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.icon,
    this.color = AppColors.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? color : AppColors.textMuted,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.18),
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.46),
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      side: BorderSide(
        color:
            selected
                ? color.withValues(alpha: 0.7)
                : AppColors.borderColor.withValues(alpha: 0.55),
      ),
    );
  }
}

class _SupplierResultCounter extends StatelessWidget {
  final int visibleCount;
  final int totalCount;

  const _SupplierResultCounter({
    required this.visibleCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: AppDecorations.cardInnerSurface(accent: AppColors.accentGold),
      child: Text(
        '$visibleCount de $totalCount',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SupplierLoadMoreButton extends StatelessWidget {
  final int visibleCount;
  final int totalCount;
  final VoidCallback onPressed;

  const _SupplierLoadMoreButton({
    required this.visibleCount,
    required this.totalCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.expand_more_rounded),
          label: Text('Mostrar mais ($visibleCount de $totalCount)'),
        ),
      ),
    );
  }
}

class _SupplierEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _SupplierEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.cardSurface(elevated: false, radius: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: AppDecorations.iconTile(AppColors.accentBlue),
              child: Icon(icon, color: AppColors.accentBlue),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierLoadingState extends StatelessWidget {
  const _SupplierLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentGold),
    );
  }
}

class _SupplierLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SupplierLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.cardSurface(
          accent: AppColors.accentRed,
          radius: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.accentRed,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nao foi possivel carregar fornecedores',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierDetailsDialog extends StatelessWidget {
  final Supplier supplier;

  const _SupplierDetailsDialog({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 32).clamp(300.0, 520.0);

    return GranithDialogSurface(
      width: width.toDouble(),
      maxHeight: size.height * 0.9,
      accentColor:
          supplier.isActive ? AppColors.accentBlue : AppColors.textMuted,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GranithDialogHeader(
            icon: Icons.business_rounded,
            title: supplier.name,
            subtitle:
                supplier.isActive ? 'Fornecedor ativo' : 'Fornecedor inativo',
            accentColor:
                supplier.isActive ? AppColors.accentBlue : AppColors.textMuted,
            onClose: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SupplierDetailRow(
                  icon: Icons.badge_outlined,
                  label: 'CNPJ',
                  value: supplier.formattedCnpj,
                ),
                _SupplierDetailRow(
                  icon: Icons.event_available_outlined,
                  label: 'Cadastro',
                  value: _formatDate(supplier.createdAt),
                ),
                _SupplierDetailRow(
                  icon: Icons.update_rounded,
                  label: 'Atualizacao',
                  value: _formatDate(supplier.updatedAt),
                ),
                _SupplierDetailRow(
                  icon: Icons.toggle_on_outlined,
                  label: 'Status',
                  value:
                      supplier.isActive
                          ? SupplierConstants.statusActive
                          : SupplierConstants.statusInactive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierConfirmDialog extends StatelessWidget {
  final Supplier supplier;

  const _SupplierConfirmDialog({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      title: const Text(
        'Excluir fornecedor',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        'Excluir "${supplier.name}" da lista de fornecedores?',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accentRed),
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}

class _SupplierDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SupplierDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardInnerSurface(accent: AppColors.accentBlue),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
