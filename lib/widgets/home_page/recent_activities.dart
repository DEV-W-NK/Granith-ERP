import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';

class RecentActivities extends StatelessWidget {
  final List<ActivityItem> activities;

  const RecentActivities({super.key, this.activities = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Atividades Recentes',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: AppColors.backgroundDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Ver todas',
                    style: TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text("Nenhuma atividade recente.", style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            // Lista de atividades
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              padding: const EdgeInsets.only(bottom: 16),
              separatorBuilder: (context, index) => Divider(
                color: AppColors.dividerColor.withOpacity(0.5), 
                height: 1, 
                indent: 70, 
                endIndent: 24
              ),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return _buildActivityItem(activity);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activity.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: activity.iconColor.withOpacity(0.2)),
            ),
            child: Icon(activity.icon, color: activity.iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activity.time,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}