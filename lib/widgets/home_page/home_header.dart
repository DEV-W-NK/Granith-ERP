import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    final months   = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    final dateStr  = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.goldDim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: const Icon(Icons.home_rounded, color: AppColors.gold, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Visão Geral',
              style: TextStyle(
                  color: AppColors.tx, fontSize: 17,
                  fontWeight: FontWeight.w600, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('Granith · $dateStr',
              style: const TextStyle(color: AppColors.tx3, fontSize: 12)),
        ]),
      ),
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.s2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border2),
        ),
        child: const Icon(Icons.notifications_none_rounded,
            color: AppColors.tx2, size: 18),
      ),
    ]);
  }
}