import 'package:flutter/material.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/AppCard.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final actions = [
            _QuickActionData(
              icon: Icons.business_rounded,
              label: 'Obras',
              color: AppColors.accentGold,
              route: '/projects',
            ),
            _QuickActionData(
              icon: Icons.menu_book_rounded,
              label: 'Diarios',
              color: AppColors.auraCyan,
              route: '/daily-logs',
            ),
            _QuickActionData(
              icon: Icons.assignment_turned_in_rounded,
              label: 'Requisicoes',
              color: AppColors.accentBlue,
              route: '/requisitions',
            ),
            _QuickActionData(
              icon: Icons.badge_rounded,
              label: 'Equipe',
              color: AppColors.accentGreen,
              route: '/hr',
            ),
          ];
          final gap =
              ResponsiveLayout.gap(
                constraints.maxWidth,
              ).clamp(8.0, 12.0).toDouble();
          final columns = compact ? 1 : 2;
          final itemWidth =
              (constraints.maxWidth - (gap * (columns - 1))) / columns;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCardTitle('Acoes rapidas'),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children:
                    actions
                        .map(
                          (action) => SizedBox(
                            width: itemWidth,
                            child: _buildQuickAction(
                              context: context,
                              icon: action.icon,
                              label: action.label,
                              color: action.color,
                              route: action.route,
                            ),
                          ),
                        )
                        .toList(),
              ),
              SizedBox(height: gap),
              _buildSystemStatus(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return GranithPressable(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.6),
          ),
          boxShadow: AppColors.glowShadows(color),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: 0.18)),
                boxShadow: AppColors.auraShadows(color),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.tx2,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              boxShadow: AppColors.auraShadows(AppColors.green),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Todos os sistemas operacionais',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.tx2, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'Atualizado agora',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(color: AppColors.tx3, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
