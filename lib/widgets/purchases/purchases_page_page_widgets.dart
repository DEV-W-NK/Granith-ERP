import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/components/granith_dialog.dart';
import 'package:project_granith/widgets/purchases/purchase_card.dart';
import 'package:project_granith/widgets/purchases/purchase_form_dialog.dart';

enum _PurchaseStatusFilter {
  all,
  awaitingApproval,
  pending,
  ordered,
  delivered,
  cancelled,
}

enum _PurchaseFulfillmentFilter { all, delivery, pickup }

enum _PurchaseSortOption {
  urgency,
  dateDesc,
  expectedAsc,
  valueDesc,
  supplier,
  project,
}

class PurchasesPageView extends StatefulWidget {
  final PurchaseService? service;
  final Stream<List<Purchase>>? purchasesStream;

  const PurchasesPageView({super.key, this.service, this.purchasesStream});

  @override
  State<PurchasesPageView> createState() => _PurchasesPageViewState();
}

class _PurchasesPageViewState extends State<PurchasesPageView> {
  static const int _initialVisibleItems = 18;
  static const int _visibleItemsStep = 18;

  late final PurchaseService _service;
  late final Stream<List<Purchase>> _purchasesStream;
  final TextEditingController _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  String _searchQuery = '';
  String? _projectKey;
  String? _itemKey;
  DateTime? _selectedDate;
  _PurchaseStatusFilter _statusFilter = _PurchaseStatusFilter.all;
  _PurchaseFulfillmentFilter _fulfillmentFilter =
      _PurchaseFulfillmentFilter.all;
  _PurchaseSortOption _sortOption = _PurchaseSortOption.urgency;
  int _visibleCount = _initialVisibleItems;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? PurchaseService();
    _purchasesStream = widget.purchasesStream ?? _service.getPurchasesStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          child: StreamBuilder<List<Purchase>>(
            stream: _purchasesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _PurchasesLoadError(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }

              if (!snapshot.hasData) {
                return const _PurchasesLoadingState();
              }

              return _buildPurchasesContent(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasesContent(List<Purchase> purchases) {
    final projectOptions = _buildProjectOptions(purchases);
    final itemOptions = _buildItemOptions(purchases);
    final projectKey = _validKey(_projectKey, projectOptions);
    final itemKey = _validKey(_itemKey, itemOptions);
    final filtered = _filteredPurchases(
      purchases,
      projectKey: projectKey,
      itemKey: itemKey,
    );
    final visiblePurchases = filtered.take(_visibleCount).toList();
    final hasMore = visiblePurchases.length < filtered.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PurchasesHeader(
          purchases: purchases,
          onCreate: () => _openPurchaseForm(context),
        ),
        const SizedBox(height: 14),
        _PurchaseToolbar(
          searchController: _searchController,
          searchQuery: _searchQuery,
          projectOptions: projectOptions,
          itemOptions: itemOptions,
          selectedProjectKey: projectKey,
          selectedItemKey: itemKey,
          selectedDate: _selectedDate,
          dateFormat: _dateFormat,
          statusFilter: _statusFilter,
          fulfillmentFilter: _fulfillmentFilter,
          sortOption: _sortOption,
          resultCount: filtered.length,
          totalCount: purchases.length,
          onSearchChanged: (value) {
            setState(() {
              _searchQuery = value;
              _resetVisibleCount();
            });
          },
          onClearSearch: () {
            setState(() {
              _searchController.clear();
              _searchQuery = '';
              _resetVisibleCount();
            });
          },
          onProjectChanged: (value) {
            setState(() {
              _projectKey = value;
              _resetVisibleCount();
            });
          },
          onItemChanged: (value) {
            setState(() {
              _itemKey = value;
              _resetVisibleCount();
            });
          },
          onPickDate: _pickDate,
          onClearDate: () {
            setState(() {
              _selectedDate = null;
              _resetVisibleCount();
            });
          },
          onStatusChanged: (filter) {
            setState(() {
              _statusFilter = filter;
              _resetVisibleCount();
            });
          },
          onFulfillmentChanged: (filter) {
            setState(() {
              _fulfillmentFilter = filter;
              _resetVisibleCount();
            });
          },
          onSortChanged: (option) {
            setState(() {
              _sortOption = option;
              _resetVisibleCount();
            });
          },
          onClearAll: _clearFilters,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _PurchasesBody(
            purchases: purchases,
            visiblePurchases: visiblePurchases,
            totalFilteredCount: filtered.length,
            hasMore: hasMore,
            purchaseService: _service,
            hasActiveFilters: _hasActiveFilters,
            onLoadMore: () {
              setState(() {
                _visibleCount += _visibleItemsStep;
              });
            },
            onCreate: () => _openPurchaseForm(context),
            onClearFilters: _clearFilters,
            onOpenDetails:
                (purchase) => _openPurchaseDetails(context, purchase),
          ),
        ),
      ],
    );
  }

  List<Purchase> _filteredPurchases(
    List<Purchase> purchases, {
    required String? projectKey,
    required String? itemKey,
  }) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered =
        purchases.where((purchase) {
          if (projectKey != null && _projectKeyFor(purchase) != projectKey) {
            return false;
          }
          if (itemKey != null && _itemKeyFor(purchase) != itemKey) {
            return false;
          }
          if (_selectedDate != null &&
              !_sameDay(purchase.purchaseDate, _selectedDate!)) {
            return false;
          }
          if (!_matchesStatus(purchase)) return false;
          if (!_matchesFulfillment(purchase)) return false;
          if (query.isEmpty) return true;

          final searchable =
              [
                purchase.id,
                purchase.itemName,
                purchase.supplierName,
                purchase.projectName,
                purchase.status.label,
                purchase.fulfillmentType.label,
                purchase.invoiceNumber ?? '',
                purchase.approvalSector ?? '',
                purchase.deliveryAddress,
                purchase.pickupAddress,
              ].join(' ').toLowerCase();
          return searchable.contains(query);
        }).toList();

    filtered.sort(_comparePurchases);
    return filtered;
  }

  bool _matchesStatus(Purchase purchase) {
    switch (_statusFilter) {
      case _PurchaseStatusFilter.all:
        return true;
      case _PurchaseStatusFilter.awaitingApproval:
        return purchase.status == PurchaseStatus.awaitingApproval;
      case _PurchaseStatusFilter.pending:
        return purchase.status == PurchaseStatus.pending;
      case _PurchaseStatusFilter.ordered:
        return purchase.status == PurchaseStatus.ordered;
      case _PurchaseStatusFilter.delivered:
        return purchase.status == PurchaseStatus.delivered;
      case _PurchaseStatusFilter.cancelled:
        return purchase.status == PurchaseStatus.cancelled;
    }
  }

  bool _matchesFulfillment(Purchase purchase) {
    switch (_fulfillmentFilter) {
      case _PurchaseFulfillmentFilter.all:
        return true;
      case _PurchaseFulfillmentFilter.delivery:
        return purchase.fulfillmentType == PurchaseFulfillmentType.delivery;
      case _PurchaseFulfillmentFilter.pickup:
        return purchase.fulfillmentType == PurchaseFulfillmentType.pickup;
    }
  }

  int _comparePurchases(Purchase left, Purchase right) {
    switch (_sortOption) {
      case _PurchaseSortOption.urgency:
        final statusCompare = _statusRank(
          left.status,
        ).compareTo(_statusRank(right.status));
        if (statusCompare != 0) return statusCompare;
        return _compareNullableDateAsc(
          left.expectedDeliveryDate,
          right.expectedDeliveryDate,
        );
      case _PurchaseSortOption.dateDesc:
        return right.purchaseDate.compareTo(left.purchaseDate);
      case _PurchaseSortOption.expectedAsc:
        return _compareNullableDateAsc(
          left.expectedDeliveryDate,
          right.expectedDeliveryDate,
        );
      case _PurchaseSortOption.valueDesc:
        return right.totalValue.compareTo(left.totalValue);
      case _PurchaseSortOption.supplier:
        return left.supplierName.toLowerCase().compareTo(
          right.supplierName.toLowerCase(),
        );
      case _PurchaseSortOption.project:
        return left.projectName.toLowerCase().compareTo(
          right.projectName.toLowerCase(),
        );
    }
  }

  int _statusRank(PurchaseStatus status) {
    switch (status) {
      case PurchaseStatus.awaitingApproval:
        return 0;
      case PurchaseStatus.pending:
        return 1;
      case PurchaseStatus.ordered:
        return 2;
      case PurchaseStatus.delivered:
        return 3;
      case PurchaseStatus.cancelled:
        return 4;
    }
  }

  int _compareNullableDateAsc(DateTime? left, DateTime? right) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _projectKey != null ||
      _itemKey != null ||
      _selectedDate != null ||
      _statusFilter != _PurchaseStatusFilter.all ||
      _fulfillmentFilter != _PurchaseFulfillmentFilter.all;

  void _resetVisibleCount() {
    _visibleCount = _initialVisibleItems;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      setState(() {
        _selectedDate = selected;
        _resetVisibleCount();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _projectKey = null;
      _itemKey = null;
      _selectedDate = null;
      _statusFilter = _PurchaseStatusFilter.all;
      _fulfillmentFilter = _PurchaseFulfillmentFilter.all;
      _resetVisibleCount();
    });
  }

  Future<void> _openPurchaseForm(BuildContext context) async {
    final purchase = await showDialog<Purchase>(
      context: context,
      builder: (_) => const PurchaseFormDialog(),
    );
    if (purchase == null || !context.mounted) return;

    try {
      await _service.addPurchase(purchase);
      if (!context.mounted) return;
      _showSnack(context, 'Compra registrada.', AppColors.accentGreen);
    } catch (error) {
      if (!context.mounted) return;
      _showSnack(
        context,
        'Erro ao registrar compra: $error',
        AppColors.accentRed,
      );
    }
  }

  Future<void> _openPurchaseDetails(BuildContext context, Purchase purchase) {
    return showDialog<void>(
      context: context,
      builder: (_) => _PurchaseDetailsDialog(purchase: purchase),
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
}

class _PurchasesHeader extends StatelessWidget {
  final List<Purchase> purchases;
  final VoidCallback onCreate;

  const _PurchasesHeader({required this.purchases, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final awaitingCount = _countStatus(
      purchases,
      PurchaseStatus.awaitingApproval,
    );
    final approvedCount = _countStatus(purchases, PurchaseStatus.pending);
    final orderedCount = _countStatus(purchases, PurchaseStatus.ordered);
    final deliveredCount = _countStatus(purchases, PurchaseStatus.delivered);
    final cancelledCount = _countStatus(purchases, PurchaseStatus.cancelled);
    final openValue = purchases
        .where(
          (purchase) =>
              purchase.status != PurchaseStatus.delivered &&
              purchase.status != PurchaseStatus.cancelled,
        )
        .fold<double>(0, (total, purchase) => total + purchase.totalValue);
    final overdueCount = purchases.where(_isOverduePurchase).length;
    final lastPurchaseDate = _latestDate(
      purchases.map((purchase) => purchase.purchaseDate),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardSurface(
        accent: AppColors.accentGold,
        elevated: false,
        radius: 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < ResponsiveLayout.compact;
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                Container(
                  width: 46,
                  height: 46,
                  decoration: AppDecorations.iconTile(AppColors.accentGold),
                  child: const Icon(
                    Icons.shopping_cart_checkout_rounded,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compras',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      purchases.isEmpty
                          ? 'Solicitacoes, aprovacao e recebimento'
                          : '${_plural(purchases.length, 'compra', 'compras')} no historico, ${_formatCurrency(openValue)} em aberto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _PurchaseHeaderMetric(
                icon: Icons.hourglass_top_rounded,
                label: '$awaitingCount aguardando',
                color: Colors.purpleAccent,
              ),
              _PurchaseHeaderMetric(
                icon: Icons.verified_outlined,
                label: '$approvedCount aprovadas',
                color: Colors.orange,
              ),
              _PurchaseHeaderMetric(
                icon: Icons.receipt_long_outlined,
                label: '$orderedCount consolidadas',
                color: AppColors.accentBlue,
              ),
              _PurchaseHeaderMetric(
                icon: Icons.local_shipping_outlined,
                label: '$deliveredCount entregues',
                color: AppColors.accentGreen,
              ),
              _PurchaseHeaderMetric(
                icon: Icons.warning_amber_rounded,
                label: '$overdueCount atrasadas',
                color:
                    overdueCount == 0
                        ? AppColors.textSecondary
                        : AppColors.accentRed,
              ),
              _PurchaseHeaderMetric(
                icon: Icons.cancel_outlined,
                label: '$cancelledCount canceladas',
                color:
                    cancelledCount == 0
                        ? AppColors.textSecondary
                        : AppColors.accentRed,
              ),
              _PurchaseHeaderMetric(
                icon: Icons.event_available_outlined,
                label:
                    lastPurchaseDate == null
                        ? 'sem compras'
                        : 'ultima ${_formatShortDate(lastPurchaseDate)}',
                color: AppColors.accentGold,
              ),
            ],
          );

          final actions = FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Nova compra'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 14),
                metrics,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 14), metrics],
                ),
              ),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _PurchaseToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final List<_FilterOption> projectOptions;
  final List<_FilterOption> itemOptions;
  final String? selectedProjectKey;
  final String? selectedItemKey;
  final DateTime? selectedDate;
  final DateFormat dateFormat;
  final _PurchaseStatusFilter statusFilter;
  final _PurchaseFulfillmentFilter fulfillmentFilter;
  final _PurchaseSortOption sortOption;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onProjectChanged;
  final ValueChanged<String?> onItemChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<_PurchaseStatusFilter> onStatusChanged;
  final ValueChanged<_PurchaseFulfillmentFilter> onFulfillmentChanged;
  final ValueChanged<_PurchaseSortOption> onSortChanged;
  final VoidCallback onClearAll;

  const _PurchaseToolbar({
    required this.searchController,
    required this.searchQuery,
    required this.projectOptions,
    required this.itemOptions,
    required this.selectedProjectKey,
    required this.selectedItemKey,
    required this.selectedDate,
    required this.dateFormat,
    required this.statusFilter,
    required this.fulfillmentFilter,
    required this.sortOption,
    required this.resultCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onProjectChanged,
    required this.onItemChanged,
    required this.onPickDate,
    required this.onClearDate,
    required this.onStatusChanged,
    required this.onFulfillmentChanged,
    required this.onSortChanged,
    required this.onClearAll,
  });

  bool get _hasFilters =>
      searchQuery.trim().isNotEmpty ||
      selectedProjectKey != null ||
      selectedItemKey != null ||
      selectedDate != null ||
      statusFilter != _PurchaseStatusFilter.all ||
      fulfillmentFilter != _PurchaseFulfillmentFilter.all;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardSurface(elevated: false, radius: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 840;
          final searchField = SizedBox(
            width: compact ? double.infinity : 330,
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Buscar compra',
                hintText: 'Item, fornecedor, obra, NF ou ID',
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
            width: compact ? double.infinity : 230,
            child: DropdownButtonFormField<_PurchaseSortOption>(
              initialValue: sortOption,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ordenar por'),
              items:
                  _PurchaseSortOption.values
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
          final projectField = _FilterDropdown(
            icon: Icons.business_outlined,
            label: 'Obra',
            value: selectedProjectKey,
            options: projectOptions,
            allLabel: 'Todas as obras',
            onChanged: onProjectChanged,
          );
          final itemField = _FilterDropdown(
            icon: Icons.inventory_2_outlined,
            label: 'Produto',
            value: selectedItemKey,
            options: itemOptions,
            allLabel: 'Todos os produtos',
            onChanged: onItemChanged,
          );
          final dateField = _DateFilterButton(
            date: selectedDate,
            dateFormat: dateFormat,
            onPickDate: onPickDate,
            onClearDate: onClearDate,
          );

          final statusChips = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PurchaseStatusChip(
                label: 'Todas',
                selected: statusFilter == _PurchaseStatusFilter.all,
                onSelected: () => onStatusChanged(_PurchaseStatusFilter.all),
              ),
              _PurchaseStatusChip(
                label: 'Aguardando',
                selected:
                    statusFilter == _PurchaseStatusFilter.awaitingApproval,
                color: Colors.purpleAccent,
                onSelected:
                    () =>
                        onStatusChanged(_PurchaseStatusFilter.awaitingApproval),
              ),
              _PurchaseStatusChip(
                label: 'Aprovadas',
                selected: statusFilter == _PurchaseStatusFilter.pending,
                color: Colors.orange,
                onSelected:
                    () => onStatusChanged(_PurchaseStatusFilter.pending),
              ),
              _PurchaseStatusChip(
                label: 'Consolidadas',
                selected: statusFilter == _PurchaseStatusFilter.ordered,
                color: AppColors.accentBlue,
                onSelected:
                    () => onStatusChanged(_PurchaseStatusFilter.ordered),
              ),
              _PurchaseStatusChip(
                label: 'Entregues',
                selected: statusFilter == _PurchaseStatusFilter.delivered,
                color: AppColors.accentGreen,
                onSelected:
                    () => onStatusChanged(_PurchaseStatusFilter.delivered),
              ),
              _PurchaseStatusChip(
                label: 'Canceladas',
                selected: statusFilter == _PurchaseStatusFilter.cancelled,
                color: AppColors.accentRed,
                onSelected:
                    () => onStatusChanged(_PurchaseStatusFilter.cancelled),
              ),
            ],
          );

          final fulfillmentChips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PurchaseStatusChip(
                label: 'Entrega + coleta',
                selected: fulfillmentFilter == _PurchaseFulfillmentFilter.all,
                icon: Icons.all_inclusive_rounded,
                onSelected:
                    () => onFulfillmentChanged(_PurchaseFulfillmentFilter.all),
              ),
              _PurchaseStatusChip(
                label: 'Entrega',
                selected:
                    fulfillmentFilter == _PurchaseFulfillmentFilter.delivery,
                icon: Icons.local_shipping_outlined,
                color: AppColors.accentBlue,
                onSelected:
                    () => onFulfillmentChanged(
                      _PurchaseFulfillmentFilter.delivery,
                    ),
              ),
              _PurchaseStatusChip(
                label: 'Coleta',
                selected:
                    fulfillmentFilter == _PurchaseFulfillmentFilter.pickup,
                icon: Icons.store_mall_directory_outlined,
                color: AppColors.accentGold,
                onSelected:
                    () =>
                        onFulfillmentChanged(_PurchaseFulfillmentFilter.pickup),
              ),
            ],
          );

          final counter = _FilterCountBadge(
            resultCount: resultCount,
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
                projectField,
                const SizedBox(height: 10),
                itemField,
                const SizedBox(height: 10),
                dateField,
                const SizedBox(height: 12),
                statusChips,
                const SizedBox(height: 10),
                fulfillmentChips,
                const SizedBox(height: 10),
                Row(
                  children: [
                    counter,
                    const SizedBox(width: 10),
                    if (_hasFilters)
                      TextButton.icon(
                        onPressed: onClearAll,
                        icon: const Icon(
                          Icons.filter_alt_off_outlined,
                          size: 16,
                        ),
                        label: const Text('Limpar filtros'),
                      ),
                  ],
                ),
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
                  Expanded(child: projectField),
                  const SizedBox(width: 12),
                  Expanded(child: itemField),
                  const SizedBox(width: 12),
                  SizedBox(width: 210, child: dateField),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sortField,
                  const SizedBox(width: 12),
                  Expanded(child: statusChips),
                  const SizedBox(width: 12),
                  Expanded(child: fulfillmentChips),
                  const SizedBox(width: 12),
                  counter,
                  if (_hasFilters) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                      label: const Text('Limpar'),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _sortLabel(_PurchaseSortOption option) {
    switch (option) {
      case _PurchaseSortOption.urgency:
        return 'Fluxo de compra';
      case _PurchaseSortOption.dateDesc:
        return 'Data recente';
      case _PurchaseSortOption.expectedAsc:
        return 'Previsao proxima';
      case _PurchaseSortOption.valueDesc:
        return 'Maior valor';
      case _PurchaseSortOption.supplier:
        return 'Fornecedor';
      case _PurchaseSortOption.project:
        return 'Obra';
    }
  }
}

class _PurchasesBody extends StatelessWidget {
  final List<Purchase> purchases;
  final List<Purchase> visiblePurchases;
  final int totalFilteredCount;
  final bool hasMore;
  final PurchaseService purchaseService;
  final bool hasActiveFilters;
  final VoidCallback onLoadMore;
  final VoidCallback onCreate;
  final VoidCallback onClearFilters;
  final ValueChanged<Purchase> onOpenDetails;

  const _PurchasesBody({
    required this.purchases,
    required this.visiblePurchases,
    required this.totalFilteredCount,
    required this.hasMore,
    required this.purchaseService,
    required this.hasActiveFilters,
    required this.onLoadMore,
    required this.onCreate,
    required this.onClearFilters,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return _PurchasesEmptyState(
        icon: Icons.shopping_cart_outlined,
        title: 'Nenhuma compra registrada',
        message:
            'Registre compras para acompanhar aprovacao, entrega e financeiro.',
        actionLabel: 'Nova compra',
        onAction: onCreate,
      );
    }

    if (visiblePurchases.isEmpty) {
      return _PurchasesEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'Nenhuma compra encontrada',
        message:
            'Ajuste busca, status, obra, produto ou data para ampliar a lista.',
        actionLabel: hasActiveFilters ? 'Limpar filtros' : 'Nova compra',
        onAction: hasActiveFilters ? onClearFilters : onCreate,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: visiblePurchases.length + (hasMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= visiblePurchases.length) {
          return _PurchaseLoadMoreButton(
            visibleCount: visiblePurchases.length,
            totalCount: totalFilteredCount,
            onPressed: onLoadMore,
          );
        }

        final purchase = visiblePurchases[index];
        return PurchaseCard(
          purchase: purchase,
          purchaseService: purchaseService,
          onTap: () => onOpenDetails(purchase),
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final List<_FilterOption> options;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.allLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const allValue = '__all__';
    return DropdownButtonFormField<String>(
      initialValue: value ?? allValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        DropdownMenuItem(
          value: allValue,
          child: Text(allLabel, overflow: TextOverflow.ellipsis),
        ),
        for (final option in options)
          DropdownMenuItem(
            value: option.key,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        onChanged(selected == allValue ? null : selected);
      },
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  final DateTime? date;
  final DateFormat dateFormat;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  const _DateFilterButton({
    required this.date,
    required this.dateFormat,
    required this.onPickDate,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data',
          prefixIcon: Icon(Icons.event_outlined),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date == null ? 'Todas as datas' : dateFormat.format(date!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      date == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClearDate,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterCountBadge extends StatelessWidget {
  final int resultCount;
  final int totalCount;

  const _FilterCountBadge({
    required this.resultCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppDecorations.cardInnerSurface(accent: AppColors.accentGold),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            size: 14,
            color: AppColors.accentGold,
          ),
          const SizedBox(width: 6),
          Text(
            '$resultCount de $totalCount compras',
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseStatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color color;
  final IconData? icon;

  const _PurchaseStatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color = AppColors.accentBlue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar:
          icon == null
              ? null
              : Icon(
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

class _PurchaseHeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PurchaseHeaderMetric({
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _PurchaseLoadMoreButton extends StatelessWidget {
  final int visibleCount;
  final int totalCount;
  final VoidCallback onPressed;

  const _PurchaseLoadMoreButton({
    required this.visibleCount,
    required this.totalCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
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

class _PurchasesEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _PurchasesEmptyState({
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
              decoration: AppDecorations.iconTile(AppColors.accentGold),
              child: Icon(icon, color: AppColors.accentGold),
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

class _PurchasesLoadingState extends StatelessWidget {
  const _PurchasesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentGold),
    );
  }
}

class _PurchasesLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PurchasesLoadError({required this.message, required this.onRetry});

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
              'Nao foi possivel carregar compras',
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

class _PurchaseDetailsDialog extends StatelessWidget {
  final Purchase purchase;

  const _PurchaseDetailsDialog({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 32).clamp(300.0, 560.0);

    return GranithDialogSurface(
      width: width.toDouble(),
      maxHeight: size.height * 0.9,
      accentColor: purchase.status.color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GranithDialogHeader(
            icon: Icons.shopping_cart_checkout_rounded,
            title: purchase.itemName,
            subtitle: purchase.status.label,
            accentColor: purchase.status.color,
            onClose: () => Navigator.pop(context),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _PurchaseDetailRow(
                    icon: Icons.storefront_outlined,
                    label: 'Fornecedor',
                    value: purchase.supplierName,
                  ),
                  _PurchaseDetailRow(
                    icon: Icons.business_outlined,
                    label: 'Obra',
                    value: purchase.projectName,
                  ),
                  _PurchaseDetailRow(
                    icon: Icons.numbers_outlined,
                    label: 'Quantidade',
                    value: _formatQuantity(purchase.quantity),
                  ),
                  _PurchaseDetailRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Valor',
                    value: _formatCurrency(purchase.totalValue),
                  ),
                  _PurchaseDetailRow(
                    icon: Icons.event_outlined,
                    label: 'Compra',
                    value: _formatShortDate(purchase.purchaseDate),
                  ),
                  if (purchase.expectedDeliveryDate != null)
                    _PurchaseDetailRow(
                      icon: Icons.event_available_outlined,
                      label: 'Previsao',
                      value: _formatShortDate(purchase.expectedDeliveryDate!),
                    ),
                  if (purchase.deliveryDate != null)
                    _PurchaseDetailRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Entrega',
                      value: _formatShortDate(purchase.deliveryDate!),
                    ),
                  _PurchaseDetailRow(
                    icon: purchase.fulfillmentType.icon,
                    label: 'Atendimento',
                    value: purchase.fulfillmentType.label,
                  ),
                  if (purchase.pickupAddress.trim().isNotEmpty)
                    _PurchaseDetailRow(
                      icon: Icons.store_mall_directory_outlined,
                      label: 'Coleta',
                      value: purchase.pickupAddress,
                    ),
                  if (purchase.deliveryAddress.trim().isNotEmpty)
                    _PurchaseDetailRow(
                      icon: Icons.place_outlined,
                      label: 'Destino',
                      value: purchase.deliveryAddress,
                    ),
                  if (purchase.invoiceNumber?.trim().isNotEmpty == true)
                    _PurchaseDetailRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'NF',
                      value: purchase.invoiceNumber!,
                    ),
                  if (purchase.notes?.trim().isNotEmpty == true)
                    _PurchaseDetailRow(
                      icon: Icons.sticky_note_2_outlined,
                      label: 'Obs.',
                      value: purchase.notes!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PurchaseDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardInnerSurface(accent: AppColors.accentGold),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGold, size: 18),
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
              maxLines: 3,
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

class _FilterOption {
  final String key;
  final String label;

  const _FilterOption({required this.key, required this.label});
}

List<_FilterOption> _buildProjectOptions(List<Purchase> purchases) {
  return _uniqueOptions(
    purchases,
    keyOf: _projectKeyFor,
    labelOf: (purchase) => purchase.projectName,
  );
}

List<_FilterOption> _buildItemOptions(List<Purchase> purchases) {
  return _uniqueOptions(
    purchases,
    keyOf: _itemKeyFor,
    labelOf: (purchase) => purchase.itemName,
  );
}

List<_FilterOption> _uniqueOptions(
  List<Purchase> purchases, {
  required String Function(Purchase purchase) keyOf,
  required String Function(Purchase purchase) labelOf,
}) {
  final byKey = <String, String>{};
  for (final purchase in purchases) {
    final key = keyOf(purchase);
    if (key.trim().isEmpty) continue;
    byKey.putIfAbsent(key, () => _cleanLabel(labelOf(purchase)));
  }

  final options =
      byKey.entries
          .map((entry) => _FilterOption(key: entry.key, label: entry.value))
          .toList()
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
  return options;
}

String? _validKey(String? selected, List<_FilterOption> options) {
  if (selected == null) return null;
  return options.any((option) => option.key == selected) ? selected : null;
}

String _projectKeyFor(Purchase purchase) {
  final id = purchase.projectId.trim();
  if (id.isNotEmpty) return id;
  return 'project:${purchase.projectName.trim().toLowerCase()}';
}

String _itemKeyFor(Purchase purchase) {
  final id = purchase.itemId.trim();
  if (id.isNotEmpty) return id;
  return 'item:${purchase.itemName.trim().toLowerCase()}';
}

String _cleanLabel(String value) {
  final cleaned = value.trim();
  return cleaned.isEmpty ? 'Nao informado' : cleaned;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _countStatus(List<Purchase> purchases, PurchaseStatus status) {
  return purchases.where((purchase) => purchase.status == status).length;
}

bool _isOverduePurchase(Purchase purchase) {
  final expected = purchase.expectedDeliveryDate;
  if (expected == null) return false;
  if (purchase.status == PurchaseStatus.delivered ||
      purchase.status == PurchaseStatus.cancelled) {
    return false;
  }
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final expectedOnly = DateTime(expected.year, expected.month, expected.day);
  return expectedOnly.isBefore(todayOnly);
}

DateTime? _latestDate(Iterable<DateTime> dates) {
  final sorted = dates.toList();
  if (sorted.isEmpty) return null;
  sorted.sort((left, right) => right.compareTo(left));
  return sorted.first;
}

String _formatShortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatCurrency(double value) =>
    NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);

String _formatQuantity(double quantity) {
  return quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2);
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';
