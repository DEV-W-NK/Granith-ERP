import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_granith/controllers/supplier_controller.dart';
import 'package:project_granith/services/supplier_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/supplier/supplier_card.dart';
import 'package:project_granith/widgets/supplier/suppliers_header.dart';

class SuppliersPageView extends StatelessWidget {
  final SupplierController? controller;

  const SuppliersPageView({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SupplierController>(
      create:
          (_) =>
              controller ?? SupplierController(SupplierService())
                ..loadSuppliers(),
      child: Consumer<SupplierController>(
        builder: (context, controller, _) {
          final isDesktop =
              MediaQuery.of(context).size.width > ResponsiveLayout.compact;
          final suppliers = controller.filteredSuppliers;

          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Column(
              children: [
                SuppliersHeader(isDesktop: isDesktop),
                Expanded(
                  child:
                      controller.isLoading
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
                          : LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final gap = ResponsiveLayout.gap(width);
                              final padding = ResponsiveLayout.pagePadding(
                                width,
                              );

                              if (controller.isGridView && width >= 620) {
                                final columns = ResponsiveLayout.columnsFor(
                                  width,
                                  mediumColumns: 2,
                                  expandedColumns: 3,
                                );
                                return GridView.builder(
                                  padding: padding,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: gap,
                                        mainAxisSpacing: gap,
                                        mainAxisExtent: 180,
                                      ),
                                  itemCount: suppliers.length,
                                  itemBuilder:
                                      (context, index) => SupplierCard(
                                        supplier: suppliers[index],
                                        isListView: false,
                                      ),
                                );
                              }

                              return ListView.separated(
                                padding: padding,
                                itemCount: suppliers.length,
                                separatorBuilder:
                                    (_, __) => SizedBox(height: gap),
                                itemBuilder: (context, index) {
                                  return SupplierCard(
                                    supplier: suppliers[index],
                                    isListView: true,
                                  );
                                },
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
