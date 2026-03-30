import 'package:flutter/material.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/purchases/purchase_card.dart';
import 'package:project_granith/widgets/purchases/purchase_form_dialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage>
    with SingleTickerProviderStateMixin {
  final PurchaseService _service = PurchaseService();
  late TabController _tabController;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Compras & Pedidos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Botão Nova Compra (setor de compras)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGold, Color(0xFFB8941F)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openPurchaseDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.add_shopping_cart_rounded,
                          color: AppColors.primaryDark, size: 20),
                      SizedBox(width: 6),
                      Text('Nova Compra',
                          style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textMuted,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_bag_outlined, size: 18),
              text: 'Setor de Compras',
            ),
            Tab(
              icon: Icon(Icons.verified_outlined, size: 18),
              text: 'Aprovação CEO',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.surfaceDark,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por item, projeto ou fornecedor...',
                hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.accentGold),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        })
                    : null,
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.accentGold)),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Aba 1: Setor de Compras ──
                // Mostra tudo EXCETO awaitingApproval
                _PurchaseList(
                  stream: _service.getPurchasesStream(),
                  search: _search,
                  excludeStatus: PurchaseStatus.awaitingApproval,
                  emptyLabel: 'Nenhuma compra registrada',
                  emptyIcon: Icons.shopping_bag_outlined,
                  onTap: (p) => _openPurchaseDialog(context, purchase: p),
                ),

                // ── Aba 2: Aprovação CEO ──
                // Mostra APENAS awaitingApproval
                _PurchaseList(
                  stream: _service.getAwaitingApprovalStream(),
                  search: _search,
                  emptyLabel: 'Nenhuma compra aguardando aprovação',
                  emptyIcon: Icons.verified_outlined,
                  onTap: (p) => _openPurchaseDialog(context, purchase: p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPurchaseDialog(BuildContext context,
      {Purchase? purchase}) async {
    final result = await showDialog<Purchase>(
      context: context,
      builder: (_) => PurchaseFormDialog(purchase: purchase),
    );

    if (result != null) {
      try {
        if (purchase == null) {
          await _service.addPurchase(result);
          EasyLoading.showSuccess('Compra registrada!');
        } else {
          await _service.updatePurchase(result.copyWith(id: purchase.id));
          EasyLoading.showSuccess('Compra atualizada!');
        }
      } catch (e) {
        EasyLoading.showError('Erro ao salvar');
      }
    }
  }
}

// ─── Lista de compras ─────────────────────────────────────────────────────────

class _PurchaseList extends StatelessWidget {
  final Stream<List<Purchase>> stream;
  final String search;
  final PurchaseStatus? excludeStatus;
  final String emptyLabel;
  final IconData emptyIcon;
  final void Function(Purchase)? onTap;

  const _PurchaseList({
    required this.stream,
    required this.search,
    this.excludeStatus,
    required this.emptyLabel,
    required this.emptyIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Purchase>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Erro ao carregar',
                  style: const TextStyle(color: AppColors.accentRed)));
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentGold));
        }

        var purchases = snapshot.data!;

        // Filtra status excluído
        if (excludeStatus != null) {
          purchases = purchases
              .where((p) => p.status != excludeStatus)
              .toList();
        }

        // Busca
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          purchases = purchases
              .where((p) =>
                  p.itemName.toLowerCase().contains(q) ||
                  p.supplierName.toLowerCase().contains(q) ||
                  p.projectName.toLowerCase().contains(q))
              .toList();
        }

        if (purchases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon,
                    size: 56,
                    color: AppColors.textMuted.withOpacity(0.3)),
                const SizedBox(height: 14),
                Text(emptyLabel,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => PurchaseCard(
            purchase: purchases[i],
            onTap: onTap != null ? () => onTap!(purchases[i]) : null,
          ),
        );
      },
    );
  }
}