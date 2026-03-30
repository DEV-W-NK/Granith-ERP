import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/AppCard.dart';
import 'package:project_granith/widgets/home_page/recent_activities.dart';

class RecentActivityList extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const AppCard(child: Center(child: Text("Nenhuma atividade.", style: TextStyle(color: AppColors.tx3))));
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: AppCardTitle('Atividade recente')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.s2,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.border2),
            ),
            child: const Text('Ver tudo',
                style: TextStyle(
                    color: AppColors.tx3, fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
        ...activities
            .map((a) => _buildActivityRow(a))
            .expand((widget) => [widget, const AppDivider()])
            .toList()
          ..removeLast(),
      ]),
    );
  }

  Widget _buildActivityRow(ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: item.iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                style: const TextStyle(
                    color: AppColors.tx, fontSize: 12,
                    fontWeight: FontWeight.w500)),
            Text(item.subtitle,
                style: const TextStyle(color: AppColors.tx3, fontSize: 10)),
          ]),
        ),
        Text(item.value,
            style: TextStyle(
                color: item.isPositive ? AppColors.green : AppColors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}