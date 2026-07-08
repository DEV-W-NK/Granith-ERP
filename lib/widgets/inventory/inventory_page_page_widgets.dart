import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/inventory/inventory_action_dialog.dart';

enum _InventoryStatusFilter { all, healthy, lowStock, outOfStock }

enum _InventorySortOption {
  critical,
  name,
  quantityAsc,
  quantityDesc,
  updatedDesc,
  lastEntryDesc,
}

class InventoryPageView extends StatefulWidget {
  final InventoryService? service;
  final Stream<List<InventoryItem>>? inventoryStream;

  const InventoryPageView({super.key, this.service, this.inventoryStream});

  @override
  State<InventoryPageView> createState() => _InventoryPageViewState();
}

class _InventoryPageViewState extends State<InventoryPageView>
    with SingleTickerProviderStateMixin {
  static const int _initialVisibleItems = 24;
  static const int _visibleItemsStep = 24;

  late final TabController _tabController;
  late final InventoryService _service;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _InventoryStatusFilter _statusFilter = _InventoryStatusFilter.all;
  _InventorySortOption _sortOption = _InventorySortOption.critical;
  int _visibleInventoryCount = _initialVisibleItems;
  int _visibleAlertCount = _initialVisibleItems;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? InventoryService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(width),
          child: StreamBuilder<List<InventoryItem>>(
            stream: widget.inventoryStream ?? _service.getInventoryStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _InventoryLoadError(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const _InventoryLoadingState();
              }

              return _buildInventoryContent(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryContent(List<InventoryItem> items) {
    final alertCount = _alertItems(items).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InventoryHeader(items: items),
        const SizedBox(height: 14),
        _InventoryToolbar(
          searchController: _searchController,
          searchQuery: _searchQuery,
          statusFilter: _statusFilter,
          sortOption: _sortOption,
          onSearchChanged: (value) {
            setState(() {
              _searchQuery = value;
              _resetVisibleCounts();
            });
          },
          onClearSearch: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
              _resetVisibleCounts();
            });
          },
          onStatusFilterChanged: (filter) {
            setState(() {
              _statusFilter = filter;
              _resetVisibleCounts();
            });
          },
          onSortChanged: (option) {
            setState(() {
              _sortOption = option;
              _resetVisibleCounts();
            });
          },
        ),
        const SizedBox(height: 14),
        Container(
          decoration: AppDecorations.cardSurface(elevated: false, radius: 16),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accentGold,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textMuted,
            dividerColor: Colors.transparent,
            tabs: [
              const Tab(
                icon: Icon(Icons.inventory_2_outlined, size: 18),
                text: 'Estoque',
              ),
              Tab(
                icon: const Icon(Icons.warning_amber_outlined, size: 18),
                text: 'Alertas ($alertCount)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryList(items, alertsOnly: false),
              _buildInventoryList(items, alertsOnly: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryList(
    List<InventoryItem> allItems, {
    required bool alertsOnly,
  }) {
    final items = _filteredItems(allItems, alertsOnly: alertsOnly);
    final visibleCount =
        alertsOnly ? _visibleAlertCount : _visibleInventoryCount;
    final visibleItems = items.take(visibleCount).toList();
    final hasMore = visibleItems.length < items.length;

    if (allItems.isEmpty) {
      return const _InventoryEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Estoque vazio',
        message: 'Receba compras para alimentar o estoque.',
      );
    }

    if (items.isEmpty) {
      return _InventoryEmptyState(
        icon:
            alertsOnly
                ? Icons.check_circle_outline_rounded
                : Icons.manage_search_rounded,
        title:
            alertsOnly ? 'Nenhum item critico' : 'Nenhum material encontrado',
        message:
            alertsOnly
                ? 'Os itens com saldo baixo ou zerado aparecerao aqui.'
                : 'Ajuste a busca, o status ou a ordenacao para ver outros materiais.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: visibleItems.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= visibleItems.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    if (alertsOnly) {
                      _visibleAlertCount += _visibleItemsStep;
                    } else {
                      _visibleInventoryCount += _visibleItemsStep;
                    }
                  });
                },
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  'Mostrar mais (${visibleItems.length} de ${items.length})',
                ),
              ),
            ),
          );
        }

        return _InventoryCard(
          item: visibleItems[index],
          onAction: _openInventoryAction,
        );
      },
    );
  }

  List<InventoryItem> _filteredItems(
    List<InventoryItem> source, {
    required bool alertsOnly,
  }) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered =
        source.where((item) {
          if (alertsOnly && !_isAlertItem(item)) return false;
          if (!_matchesStatus(item)) return false;
          if (query.isEmpty) return true;

          final searchable =
              [
                item.name,
                item.unit,
                item.lastPurchaseId ?? '',
                _statusLabel(item),
              ].join(' ').toLowerCase();
          return searchable.contains(query);
        }).toList();

    filtered.sort(_compareItems);
    return filtered;
  }

  List<InventoryItem> _alertItems(List<InventoryItem> items) =>
      items.where(_isAlertItem).toList();

  bool _isAlertItem(InventoryItem item) => item.isLowStock || item.isOutOfStock;

  bool _matchesStatus(InventoryItem item) {
    switch (_statusFilter) {
      case _InventoryStatusFilter.all:
        return true;
      case _InventoryStatusFilter.healthy:
        return !_isAlertItem(item);
      case _InventoryStatusFilter.lowStock:
        return item.isLowStock && !item.isOutOfStock;
      case _InventoryStatusFilter.outOfStock:
        return item.isOutOfStock;
    }
  }

  int _compareItems(InventoryItem left, InventoryItem right) {
    switch (_sortOption) {
      case _InventorySortOption.critical:
        final statusCompare = _criticalRank(
          left,
        ).compareTo(_criticalRank(right));
        if (statusCompare != 0) return statusCompare;
        final healthCompare = left.stockHealthPercent.compareTo(
          right.stockHealthPercent,
        );
        if (healthCompare != 0) return healthCompare;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      case _InventorySortOption.name:
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      case _InventorySortOption.quantityAsc:
        return left.quantity.compareTo(right.quantity);
      case _InventorySortOption.quantityDesc:
        return right.quantity.compareTo(left.quantity);
      case _InventorySortOption.updatedDesc:
        return right.updatedAt.compareTo(left.updatedAt);
      case _InventorySortOption.lastEntryDesc:
        return _compareNullableDateDesc(
          left.lastEntryDate,
          right.lastEntryDate,
        );
    }
  }

  int _criticalRank(InventoryItem item) {
    if (item.isOutOfStock) return 0;
    if (item.isLowStock) return 1;
    return 2;
  }

  int _compareNullableDateDesc(DateTime? left, DateTime? right) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  void _resetVisibleCounts() {
    _visibleInventoryCount = _initialVisibleItems;
    _visibleAlertCount = _initialVisibleItems;
  }

  Future<void> _openInventoryAction(
    InventoryItem item,
    InventoryMovementType type,
  ) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => InventoryActionDialog(item: item, type: type),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  final List<InventoryItem> items;

  const _InventoryHeader({required this.items});

  @override
  Widget build(BuildContext context) {
    final lowStockCount =
        items.where((item) => item.isLowStock && !item.isOutOfStock).length;
    final outOfStockCount = items.where((item) => item.isOutOfStock).length;
    final healthyCount =
        items.where((item) => !item.isLowStock && !item.isOutOfStock).length;
    final lastEntry = _lastEntryDate(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < ResponsiveLayout.compact;
            final title = Row(
              children: [
                if (!compact) ...[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: AppDecorations.iconTile(AppColors.accentGold),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Controle de Estoque',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Saldos, alertas e movimentacoes de materiais',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final chips = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: compact ? WrapAlignment.start : WrapAlignment.end,
              children: [
                _InventoryContextChip(
                  icon: Icons.inventory_2_rounded,
                  label: _plural(items.length, 'item', 'itens'),
                  color: AppColors.accentBlue,
                ),
                _InventoryContextChip(
                  icon: Icons.health_and_safety_outlined,
                  label: _plural(healthyCount, 'saudavel', 'saudaveis'),
                  color: AppColors.accentGreen,
                ),
                _InventoryContextChip(
                  icon: Icons.warning_amber_rounded,
                  label: _plural(lowStockCount, 'critico', 'criticos'),
                  color: AppColors.accentGold,
                ),
                _InventoryContextChip(
                  icon: Icons.remove_shopping_cart_outlined,
                  label: _plural(outOfStockCount, 'zerado', 'zerados'),
                  color: AppColors.accentRed,
                ),
                _InventoryContextChip(
                  icon: Icons.event_available_outlined,
                  label:
                      lastEntry == null
                          ? 'sem entrada'
                          : 'ultima entrada ${_formatShortDate(lastEntry)}',
                  color: AppColors.textSecondary,
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 12), chips],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: title),
                const SizedBox(width: 16),
                Flexible(child: chips),
              ],
            );
          },
        ),
      ],
    );
  }

  DateTime? _lastEntryDate(List<InventoryItem> items) {
    final dates =
        items.map((item) => item.lastEntryDate).whereType<DateTime>().toList();
    if (dates.isEmpty) return null;
    dates.sort((left, right) => right.compareTo(left));
    return dates.first;
  }
}

class _InventoryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final _InventoryStatusFilter statusFilter;
  final _InventorySortOption sortOption;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<_InventoryStatusFilter> onStatusFilterChanged;
  final ValueChanged<_InventorySortOption> onSortChanged;

  const _InventoryToolbar({
    required this.searchController,
    required this.searchQuery,
    required this.statusFilter,
    required this.sortOption,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusFilterChanged,
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
          final compact = constraints.maxWidth < 720;
          final searchField = SizedBox(
            width: compact ? double.infinity : 360,
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Buscar material',
                hintText: 'Nome, unidade ou compra',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    searchQuery.isEmpty
                        ? null
                        : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: onClearSearch,
                          icon: const Icon(Icons.close_rounded),
                        ),
              ),
              onChanged: onSearchChanged,
            ),
          );
          final sortField = SizedBox(
            width: compact ? double.infinity : 250,
            child: DropdownButtonFormField<_InventorySortOption>(
              initialValue: sortOption,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items:
                  _InventorySortOption.values
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
            children: [
              _InventoryFilterChip(
                label: 'Todos',
                selected: statusFilter == _InventoryStatusFilter.all,
                onSelected:
                    () => onStatusFilterChanged(_InventoryStatusFilter.all),
              ),
              _InventoryFilterChip(
                label: 'Saudaveis',
                selected: statusFilter == _InventoryStatusFilter.healthy,
                color: AppColors.accentGreen,
                onSelected:
                    () => onStatusFilterChanged(_InventoryStatusFilter.healthy),
              ),
              _InventoryFilterChip(
                label: 'Criticos',
                selected: statusFilter == _InventoryStatusFilter.lowStock,
                color: AppColors.accentGold,
                onSelected:
                    () =>
                        onStatusFilterChanged(_InventoryStatusFilter.lowStock),
              ),
              _InventoryFilterChip(
                label: 'Zerados',
                selected: statusFilter == _InventoryStatusFilter.outOfStock,
                color: AppColors.accentRed,
                onSelected:
                    () => onStatusFilterChanged(
                      _InventoryStatusFilter.outOfStock,
                    ),
              ),
            ],
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
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _sortLabel(_InventorySortOption option) {
    switch (option) {
      case _InventorySortOption.critical:
        return 'Criticidade';
      case _InventorySortOption.name:
        return 'Nome';
      case _InventorySortOption.quantityAsc:
        return 'Menor saldo';
      case _InventorySortOption.quantityDesc:
        return 'Maior saldo';
      case _InventorySortOption.updatedDesc:
        return 'Atualizacao recente';
      case _InventorySortOption.lastEntryDesc:
        return 'Ultima entrada';
    }
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final void Function(InventoryItem item, InventoryMovementType type) onAction;

  const _InventoryCard({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final statusColor = _stockColor(item);
    final healthPct =
        (item.stockHealthPercent / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardSurface(
        accent: statusColor,
        emphasized: item.isLowStock || item.isOutOfStock,
        radius: 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: AppDecorations.iconTile(statusColor),
                child: Icon(Icons.inventory_2_outlined, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _InventoryStatusChip(item: item),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Atualizado ${_formatDateTime(item.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    if (item.lastPurchaseId?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Compra vinculada: ${item.lastPurchaseId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InventoryMetric(
                label: 'Saldo',
                value: _formatQuantity(item.quantity, item.unit),
                color: statusColor,
              ),
              _InventoryMetric(
                label: 'Minimo',
                value: _formatQuantity(item.minQuantity, item.unit),
                color: AppColors.textSecondary,
              ),
              _InventoryMetric(
                label: 'Ultima entrada',
                value:
                    item.lastEntryDate == null
                        ? 'Sem registro'
                        : _formatShortDate(item.lastEntryDate!),
                color: AppColors.accentBlue,
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed:
                    item.quantity <= 0
                        ? null
                        : () => onAction(item, InventoryMovementType.outbound),
                icon: const Icon(Icons.call_made_rounded),
                label: const Text('Baixa'),
              ),
              OutlinedButton.icon(
                onPressed:
                    item.quantity <= 0
                        ? null
                        : () => onAction(item, InventoryMovementType.transfer),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Transferir'),
              ),
              TextButton.icon(
                onPressed:
                    () => onAction(item, InventoryMovementType.adjustment),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Ajustar'),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                identity,
                const SizedBox(height: 14),
                metrics,
                const SizedBox(height: 12),
                actions,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: identity),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: metrics),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: actions,
                      ),
                    ),
                  ],
                ),
              if (item.minQuantity > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: healthPct,
                    backgroundColor: AppColors.surfaceDark.withValues(
                      alpha: 0.65,
                    ),
                    color: statusColor,
                    minHeight: 5,
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

class _InventoryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InventoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppDecorations.cardInnerSurface(accent: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryStatusChip extends StatelessWidget {
  final InventoryItem item;

  const _InventoryStatusChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _stockColor(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _statusLabel(item),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InventoryContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InventoryContextChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: AppDecorations.cardInnerSurface(accent: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color color;

  const _InventoryFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color = AppColors.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.18),
      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.46),
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class _InventoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InventoryEmptyState({
    required this.icon,
    required this.title,
    required this.message,
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
          ],
        ),
      ),
    );
  }
}

class _InventoryLoadingState extends StatelessWidget {
  const _InventoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentGold),
    );
  }
}

class _InventoryLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InventoryLoadError({required this.message, required this.onRetry});

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
              'Nao foi possivel carregar o estoque',
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

String _statusLabel(InventoryItem item) {
  if (item.isOutOfStock) return 'Zerado';
  if (item.isLowStock) return 'Critico';
  return 'Saudavel';
}

Color _stockColor(InventoryItem item) {
  if (item.isOutOfStock) return AppColors.accentRed;
  if (item.isLowStock) return AppColors.accentGold;
  return AppColors.accentGreen;
}

String _formatQuantity(double quantity, String unit) {
  final value =
      quantity % 1 == 0
          ? quantity.toStringAsFixed(0)
          : quantity.toStringAsFixed(1);
  return '$value $unit';
}

String _formatDateTime(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

String _formatShortDate(DateTime date) =>
    DateFormat('dd/MM/yyyy').format(date.toLocal());

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
