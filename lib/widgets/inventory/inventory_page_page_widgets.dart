import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:project_granith/ViewModels/inventoryviewmodel.dart';
import 'package:project_granith/models/inventory_model.dart';
import 'package:project_granith/models/InventoryMovementType.dart';
import 'package:project_granith/services/inventory_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';

class InventoryPageView extends StatefulWidget {
  const InventoryPageView({super.key});

  @override
  State<InventoryPageView> createState() => _InventoryPageViewState();
}

class _InventoryPageViewState extends State<InventoryPageView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InventoryService _service = InventoryService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 420;

    return ChangeNotifierProvider(
      create: (_) => InventoryViewModel(_service),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: Text(
            'Controle de Estoque',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: compact ? 17 : null,
            ),
          ),
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accentGold,
            labelColor: AppColors.accentGold,
            unselectedLabelColor: AppColors.textMuted,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                icon: Icon(Icons.inventory_2_outlined, size: 18),
                text: 'Estoque',
              ),
              Tab(
                icon: Icon(Icons.warning_amber_outlined, size: 18),
                text: 'Alertas',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            const _InventorySearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _InventoryList(lowStockOnly: false),
                  _InventoryList(lowStockOnly: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySearchBar extends StatelessWidget {
  const _InventorySearchBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<InventoryViewModel>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.surfaceDark,
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar material...',
          hintStyle: TextStyle(
            color: AppColors.textMuted.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.accentGold,
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.backgroundDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accentGold),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: viewModel.updateSearch,
      ),
    );
  }
}

class _InventoryList extends StatelessWidget {
  final bool lowStockOnly;
  const _InventoryList({required this.lowStockOnly});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<InventoryViewModel>();
    final service = InventoryService();
    final stream =
        lowStockOnly
            ? service.getLowStockStream()
            : service.getInventoryStream();

    return StreamBuilder<List<InventoryItem>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold),
          );

        final items = viewModel.filterItems(snap.data!);

        if (items.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: ResponsiveLayout.pagePadding(
            MediaQuery.sizeOf(context).width,
          ),
          itemCount: items.length,
          itemBuilder:
              (_, i) => _InventoryCard(item: items[i], viewModel: viewModel),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            lowStockOnly
                ? Icons.check_circle_outline
                : Icons.inventory_2_outlined,
            size: 52,
            color: AppColors.textMuted.withOpacity(0.2),
          ),
          const SizedBox(height: 14),
          Text(
            lowStockOnly ? 'Nenhum item abaixo do mínimo' : 'Estoque vazio',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final InventoryViewModel viewModel;

  const _InventoryCard({required this.item, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final barColor =
        item.isOutOfStock
            ? AppColors.accentRed
            : (item.isLowStock ? Colors.orangeAccent : AppColors.accentGreen);
    final healthPct = (item.stockHealthPercent / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              item.isLowStock
                  ? Colors.orangeAccent.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: barColor,
                size: 20,
              ),
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'Mínimo: ${item.minQuantity.toStringAsFixed(0)} ${item.unit}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 84),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.quantity.toStringAsFixed(
                        item.quantity % 1 == 0 ? 0 : 1,
                      ),
                      maxLines: 1,
                      style: TextStyle(
                        color: barColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    item.unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item.minQuantity > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: LinearProgressIndicator(
                value: healthPct,
                backgroundColor: Colors.white.withOpacity(0.05),
                color: barColor,
                minHeight: 4,
              ),
            ),
        ],
      ),
    );
  }
}
