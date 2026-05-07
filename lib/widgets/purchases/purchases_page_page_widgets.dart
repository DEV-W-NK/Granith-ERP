import 'package:flutter/material.dart';
import 'package:project_granith/services/purchase_service.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/purchases/purchase_card.dart';

class PurchasesPageView extends StatelessWidget {
  const PurchasesPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
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

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body:
              purchases.isEmpty
                  ? const Center(
                    child: Text(
                      'Nenhuma compra registrada.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final padding = ResponsiveLayout.pagePadding(width);
                      final gap = ResponsiveLayout.gap(width);

                      return ListView.separated(
                        padding: padding,
                        itemCount: purchases.length,
                        separatorBuilder: (_, __) => SizedBox(height: gap),
                        itemBuilder: (context, index) {
                          return PurchaseCard(purchase: purchases[index]);
                        },
                      );
                    },
                  ),
        );
      },
    );
  }
}
