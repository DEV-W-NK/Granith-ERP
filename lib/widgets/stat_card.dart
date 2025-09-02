import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import '../models/statistics_model.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TrendType trend;
  final String trendValue;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
    required this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            // Header com ícone
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(8), // Reduced padding
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20, // Reduced size
                    ),
                  ),
                ),
                Flexible(child: _buildTrendIcon()),
              ],
            ),

            const SizedBox(height: 12), // Reduced spacing
            // Valor principal
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            const SizedBox(height: 4),

            // Título
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12, // Reduced font size
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            const SizedBox(height: 2),

            // Subtítulo
            Flexible(
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10, // Reduced font size
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIcon() {
    Color trendColor;
    IconData trendIcon;

    switch (trend) {
      case TrendType.up:
        trendColor = AppColors.accentGreen;
        trendIcon = Icons.trending_up;
        break;
      case TrendType.down:
        trendColor = AppColors.accentRed;
        trendIcon = Icons.trending_down;
        break;
      case TrendType.neutral:
        trendColor = AppColors.textMuted;
        trendIcon = Icons.trending_flat;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ), // Reduced padding
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 10, // Reduced size
          ),
          if (trendValue != '0') ...[
            const SizedBox(width: 2),
            Text(
              trendValue,
              style: TextStyle(
                color: trendColor,
                fontSize: 9, // Reduced font size
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
