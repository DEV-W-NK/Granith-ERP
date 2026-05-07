import 'package:flutter/material.dart';
// Certifique-se de que o caminho de importação bate com o seu projeto
import 'package:project_granith/themes/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: AppColors.cardGradient,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.72)),
      boxShadow: AppColors.glowShadows(),
    ),
    child: child,
  );
}

class AppCardTitle extends StatelessWidget {
  final String text;
  const AppCardTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text.toUpperCase(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.dividerColor, height: 1, thickness: 1);
}
