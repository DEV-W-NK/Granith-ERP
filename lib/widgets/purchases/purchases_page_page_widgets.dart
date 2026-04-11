import 'package:flutter/material.dart';
import 'package:project_granith/services/purchase_service.dart';
import 'package:project_granith/themes/app_theme.dart';
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
          body: purchases.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma compra registrada.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return PurchaseCard(purchase: purchases[index]);
                  },
                ),
        );
      },
    );
  }
}
