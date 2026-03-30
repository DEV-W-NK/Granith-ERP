import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class TransparencyBanner extends StatelessWidget {
  const TransparencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/subscription'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.s1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldDim,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.gold, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Transparência & Custos',
                  style: TextStyle(
                      color: AppColors.tx, fontSize: 13,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Detalhamento de recursos e fatura estimada',
                  style: TextStyle(color: AppColors.tx3, fontSize: 11)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.gold, size: 20),
        ]),
      ),
    );
  }
}