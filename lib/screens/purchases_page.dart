import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/services/purchase_service.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/purchases/purchase_form_dialog.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  final PurchaseService _purchaseService = PurchaseService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Compras & Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentGold, Color(0xFFB8941F)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppColors.accentGold.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openPurchaseDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, color: AppColors.primaryDark, size: 20),
                      SizedBox(width: 6),
                      Text('Nova Compra', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pesquisa
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por item, projeto ou fornecedor...',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentGold),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                      onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                    ) 
                  : null,
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentGold)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Lista
          Expanded(
            child: StreamBuilder<List<Purchase>>(
              stream: _purchaseService.getPurchasesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Erro ao carregar', style: TextStyle(color: AppColors.accentRed)));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));

                var purchases = snapshot.data!;

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  purchases = purchases.where((p) => 
                    p.itemName.toLowerCase().contains(query) || 
                    p.supplierName.toLowerCase().contains(query) ||
                    p.projectName.toLowerCase().contains(query)
                  ).toList();
                }

                if (purchases.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text('Nenhuma compra registrada', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildPurchaseCard(purchases[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPurchaseDialog(context, purchase: purchase),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: AppColors.accentGold),
                    ),
                    const SizedBox(width: 16),
                    // Infos Principais
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome do Projeto (Badge)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.business_rounded, size: 10, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    purchase.projectName,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            purchase.itemName,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  purchase.supplierName,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Valor
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(purchase.totalValue),
                          style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: purchase.status.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: purchase.status.color.withOpacity(0.3)),
                          ),
                          child: Text(
                            purchase.status.label,
                            style: TextStyle(color: purchase.status.color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.borderColor, height: 1),
                ),
                // Footer (Endereço e Data)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              purchase.deliveryAddress,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(purchase.purchaseDate),
                      style: TextStyle(color: AppColors.textMuted.withOpacity(0.6), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPurchaseDialog(BuildContext context, {Purchase? purchase}) async {
    final result = await showDialog<Purchase>(
      context: context,
      builder: (context) => PurchaseFormDialog(purchase: purchase),
    );

    if (result != null) {
      try {
        if (purchase == null) {
          await _purchaseService.addPurchase(result);
          EasyLoading.showSuccess('Compra registrada!');
        } else {
          await _purchaseService.updatePurchase(result.copyWith(id: purchase.id));
          EasyLoading.showSuccess('Compra atualizada!');
        }
      } catch (e) {
        EasyLoading.showError('Erro ao salvar');
      }
    }
  }
}