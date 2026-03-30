import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_granith/themes/app_theme.dart';

/// Card de métrica financeira usado no dashboard da FinancialPage.
///
/// [badgeCount] exibe um badge vermelho de alerta (ex: nº de itens vencidos).
/// [onTap] permite filtrar a lista ao tocar no card.
class FinancialStatCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final int? badgeCount;
  final VoidCallback? onTap;

  const FinancialStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: onTap != null
                    ? color.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
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
                _AnimatedValue(value: value, color: color, format: currency),
              ],
            ),
          ),

          // Badge de alerta (ex: nº de vencidos)
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.backgroundDark, width: 1.5),
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
      ),
    );
  }
}

/// Anima a troca de valor com um fade+slide suave.
class _AnimatedValue extends StatelessWidget {
  final double value;
  final Color color;
  final NumberFormat format;

  const _AnimatedValue({
    required this.value,
    required this.color,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, v, __) => Text(
        format.format(v),
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}