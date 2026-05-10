import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/purchases/purchase_card.dart';

class PurchasesPageView extends StatefulWidget {
  const PurchasesPageView({super.key});

  @override
  State<PurchasesPageView> createState() => _PurchasesPageViewState();
}

class _PurchasesPageViewState extends State<PurchasesPageView> {
  String? _projectKey;
  String? _itemKey;
  DateTime? _selectedDate;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Purchase>>(
      stream: PurchaseService().getPurchasesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            ),
          );
        }

        final purchases = snapshot.data!;
        final projectOptions = _buildProjectOptions(purchases);
        final itemOptions = _buildItemOptions(purchases);
        final projectKey = _validKey(_projectKey, projectOptions);
        final itemKey = _validKey(_itemKey, itemOptions);
        final filtered = _filterPurchases(
          purchases,
          projectKey: projectKey,
          itemKey: itemKey,
          date: _selectedDate,
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final padding = ResponsiveLayout.pagePadding(width);
              final gap = ResponsiveLayout.gap(width);

              if (purchases.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma compra registrada.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding.left,
                      padding.top,
                      padding.right,
                      0,
                    ),
                    child: _PurchaseFilterBar(
                      projectOptions: projectOptions,
                      itemOptions: itemOptions,
                      selectedProjectKey: projectKey,
                      selectedItemKey: itemKey,
                      selectedDate: _selectedDate,
                      dateFormat: _dateFormat,
                      resultCount: filtered.length,
                      totalCount: purchases.length,
                      onProjectChanged:
                          (value) => setState(() => _projectKey = value),
                      onItemChanged:
                          (value) => setState(() => _itemKey = value),
                      onPickDate: _pickDate,
                      onClearDate: () => setState(() => _selectedDate = null),
                      onClearAll: _clearFilters,
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child:
                        filtered.isEmpty
                            ? _FilteredEmptyState(onClear: _clearFilters)
                            : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                padding.left,
                                0,
                                padding.right,
                                padding.bottom,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder:
                                  (context, index) => SizedBox(height: gap),
                              itemBuilder: (context, index) {
                                return PurchaseCard(purchase: filtered[index]);
                              },
                            ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
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
      setState(() => _selectedDate = selected);
    }
  }

  void _clearFilters() {
    setState(() {
      _projectKey = null;
      _itemKey = null;
      _selectedDate = null;
    });
  }
}

class _PurchaseFilterBar extends StatelessWidget {
  final List<_FilterOption> projectOptions;
  final List<_FilterOption> itemOptions;
  final String? selectedProjectKey;
  final String? selectedItemKey;
  final DateTime? selectedDate;
  final DateFormat dateFormat;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String?> onProjectChanged;
  final ValueChanged<String?> onItemChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final VoidCallback onClearAll;

  const _PurchaseFilterBar({
    required this.projectOptions,
    required this.itemOptions,
    required this.selectedProjectKey,
    required this.selectedItemKey,
    required this.selectedDate,
    required this.dateFormat,
    required this.resultCount,
    required this.totalCount,
    required this.onProjectChanged,
    required this.onItemChanged,
    required this.onPickDate,
    required this.onClearDate,
    required this.onClearAll,
  });

  bool get _hasFilters =>
      selectedProjectKey != null ||
      selectedItemKey != null ||
      selectedDate != null;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 780;

    final filters = [
      _FilterDropdown(
        icon: Icons.business_outlined,
        label: 'Obra',
        value: selectedProjectKey,
        options: projectOptions,
        allLabel: 'Todas as obras',
        onChanged: onProjectChanged,
      ),
      _FilterDropdown(
        icon: Icons.inventory_2_outlined,
        label: 'Produto',
        value: selectedItemKey,
        options: itemOptions,
        allLabel: 'Todos os produtos',
        onChanged: onItemChanged,
      ),
      _DateFilterButton(
        date: selectedDate,
        dateFormat: dateFormat,
        onPickDate: onPickDate,
        onClearDate: onClearDate,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterCountBadge(
                resultCount: resultCount,
                totalCount: totalCount,
              ),
              if (_hasFilters)
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                  label: const Text('Limpar filtros'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          compact
              ? Column(
                children:
                    filters
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: filter,
                          ),
                        )
                        .toList(),
              )
              : Row(
                children: [
                  Expanded(child: filters[0]),
                  const SizedBox(width: 10),
                  Expanded(child: filters[1]),
                  const SizedBox(width: 10),
                  SizedBox(width: 230, child: filters[2]),
                ],
              ),
        ],
      ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.62),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value ?? allValue,
            isExpanded: true,
            dropdownColor: AppColors.secondaryDark,
            iconEnabledColor: AppColors.textMuted,
            items: [
              DropdownMenuItem(
                value: allValue,
                child: _DropdownLabel(icon: icon, label: allLabel, muted: true),
              ),
              for (final option in options)
                DropdownMenuItem(
                  value: option.key,
                  child: _DropdownLabel(icon: icon, label: option.label),
                ),
            ],
            onChanged: (selected) {
              onChanged(selected == allValue ? null : selected);
            },
          ),
        ),
      ),
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool muted;

  const _DropdownLabel({
    required this.icon,
    required this.label,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: muted ? AppColors.textMuted : AppColors.accentGold,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted ? AppColors.textMuted : AppColors.textPrimary,
              fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.62),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPickDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: 16,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accentGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.28)),
      ),
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

class _FilteredEmptyState extends StatelessWidget {
  final VoidCallback onClear;

  const _FilteredEmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              color: AppColors.textMuted,
              size: 34,
            ),
            const SizedBox(height: 10),
            const Text(
              'Nenhuma compra encontrada',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajuste obra, produto ou data para ampliar a busca.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String key;
  final String label;

  const _FilterOption({required this.key, required this.label});
}

List<Purchase> _filterPurchases(
  List<Purchase> purchases, {
  required String? projectKey,
  required String? itemKey,
  required DateTime? date,
}) {
  return purchases
      .where((purchase) {
        if (projectKey != null && _projectKeyFor(purchase) != projectKey) {
          return false;
        }
        if (itemKey != null && _itemKeyFor(purchase) != itemKey) {
          return false;
        }
        if (date != null && !_sameDay(purchase.purchaseDate, date)) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
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
