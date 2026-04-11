import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/supplier/supplier_card.dart';
import 'package:project_granith/widgets/supplier/suppliers_header.dart';

class SuppliersPageView extends StatelessWidget {
  const SuppliersPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupplierController(SupplierService())..loadSuppliers(),
      child: Consumer<SupplierController>(
        builder: (context, controller, _) {
          final isDesktop = MediaQuery.of(context).size.width > 900;
          final suppliers = controller.filteredSuppliers;

          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Column(
              children: [
                SuppliersHeader(isDesktop: isDesktop),
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGold,
                          ),
                        )
                      : suppliers.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum fornecedor encontrado.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: suppliers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return SupplierCard(
                                  supplier: suppliers[index],
                                  isListView: true,
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
