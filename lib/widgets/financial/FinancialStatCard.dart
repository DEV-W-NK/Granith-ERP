import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';

/// Card de metrica financeira usado no dashboard da FinancialPage.
///
/// [badgeCount] exibe um badge vermelho de alerta.
/// [onTap] permite filtrar a lista ao tocar no card.
class FinancialStatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final int? badgeCount;
  final VoidCallback? onTap;
  final double width;
  final bool compact;

  const FinancialStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.badgeCount,
    this.onTap,
    this.width = 220,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return GranithPressable(
      onTap: onTap,
      premium: onTap != null,
      premiumColor: AppColors.accentGold,
      borderRadius: BorderRadius.circular(compact ? 14 : 16),
      hoverScale: 1.012,
      builder: (context, state) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width,
              padding: EdgeInsets.all(compact ? 16 : 20),
              decoration: AppDecorations.statCardSurface(
                color,
                radius: compact ? 14 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: GranithPremiumIconTile(
                          icon: icon,
                          color: color,
                          size: 28,
                          iconSize: 15,
                          radius: 9,
                          active: state.active && onTap != null,
                          progress: state.glowProgress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _AnimatedValue(
                    value: value,
                    color: color,
                    format: currency,
                    compact: compact,
                  ),
                ],
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.backgroundDark,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}

class _AnimatedValue extends StatelessWidget {
  final double value;
  final Color color;
  final NumberFormat format;
  final bool compact;

  const _AnimatedValue({
    required this.value,
    required this.color,
    required this.format,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, v, __) {
        return Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              format.format(v),
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: compact ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
