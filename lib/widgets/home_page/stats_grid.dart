import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';

class StatsGrid extends StatelessWidget {
  final bool isDesktop;
  final List<StatItem> stats;

  const StatsGrid({super.key, required this.isDesktop, required this.stats});


  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox();

    final cards = stats
        .asMap()
        .entries
        .map((entry) => GranithReveal(
              delay: Duration(milliseconds: 120 + (entry.key * 70)),
              beginOffset: const Offset(0, 0.05),
              child: _buildStatCard(entry.value),
            ))
        .toList();

    if (isDesktop) {
      return Row(
        children: cards
            .expand((c) => [Expanded(child: c), const SizedBox(width: 12)])
            .toList()
          ..removeLast(),
      );
    }

    return Column(children: [
      Row(children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: cards[2]),
        const SizedBox(width: 10),
        if (cards.length > 3) Expanded(child: cards[3]),
      ]),
    ]);
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: stat.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(stat.icon, color: stat.accent, size: 15),
            ),
            const Spacer(),
            Container(
              width: 28, height: 2,
              decoration: BoxDecoration(
                  color: stat.accent, borderRadius: BorderRadius.circular(2)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(stat.label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              stat.value,
              key: ValueKey(stat.value),
              style: TextStyle(
                color: stat.accent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Icon(
                stat.deltaUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: stat.deltaUp ? AppColors.accentGreen : AppColors.accentRed),
            const SizedBox(width: 3),
            Flexible(
              child: Text(stat.delta,
                  style: TextStyle(
                      color: stat.deltaUp ? AppColors.accentGreen : AppColors.accentRed, fontSize: 10)),
            ),
          ]),
        ]),
      ),
    );
  }
}
