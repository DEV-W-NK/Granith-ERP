import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/utils/responsive_layout.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';

class StatsGrid extends StatelessWidget {
  final bool isDesktop;
  final List<StatItem> stats;

  const StatsGrid({super.key, required this.isDesktop, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox();

    final cards =
        stats
            .asMap()
            .entries
            .map(
              (entry) => GranithReveal(
                delay: Duration(milliseconds: 120 + (entry.key * 70)),
                beginOffset: const Offset(0, 0.05),
                child: _buildStatCard(entry.value),
              ),
            )
            .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final gap = ResponsiveLayout.gap(maxWidth).clamp(10.0, 14.0).toDouble();
        final columns =
            isDesktop
                ? cards.length.clamp(1, 4).toInt()
                : maxWidth < 360
                ? 1
                : 2;
        final itemWidth = (maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              cards
                  .map((card) => SizedBox(width: itemWidth, child: card))
                  .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(StatItem stat) {
    return GranithPressable(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: stat.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stat.icon, color: stat.accent, size: 15),
                ),
                const Spacer(),
                Container(
                  width: 28,
                  height: 2,
                  decoration: BoxDecoration(
                    color: stat.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 24,
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder:
                      (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.18),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                  child: FittedBox(
                    key: ValueKey(stat.value),
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      stat.value,
                      maxLines: 1,
                      style: TextStyle(
                        color: stat.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  stat.deltaUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color:
                      stat.deltaUp
                          ? AppColors.accentGreen
                          : AppColors.accentRed,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    stat.delta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          stat.deltaUp
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
