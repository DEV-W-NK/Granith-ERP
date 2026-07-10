import 'package:flutter/material.dart';
import 'package:project_granith/constants/GranitTokens.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/animations/granith_motion.dart';

// =============================================================================
// GRANIT CARD
// Shell padrão de card para todas as telas do Granith ERP.
// Substitui a classe _Card inline da ReportsPage.
//
// USO BÁSICO:
//   GranitCard(child: Text('conteúdo'))
//
// COM PADDING CUSTOMIZADO:
//   GranitCard(
//     padding: EdgeInsets.all(20),
//     child: MinhaWidget(),
//   )
// =============================================================================

class GranitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Border? customBorder;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool emphasized;

  const GranitCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GranitTokens.cardPadding),
    this.backgroundColor,
    this.customBorder,
    this.borderRadius,
    this.onTap,
    this.accentColor,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    final decoration = AppDecorations.cardSurface(
      accent: accentColor,
      emphasized: emphasized,
    ).copyWith(
      color: backgroundColor ?? AppColors.surfaceDark.withValues(alpha: 0.76),
      borderRadius: radius,
      border: customBorder,
    );

    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GranithPressable(
        onTap: onTap,
        premium: true,
        premiumColor: AppColors.accentGold,
        borderRadius: radius,
        hoverScale: 1.01,
        child: content,
      );
    }

    return content;
  }
}

// =============================================================================
// GRANIT CARD TITLE
// Label em caixa alta para título de seção dentro de card.
// Substitui a classe _CardTitle inline da ReportsPage.
//
// USO:
//   GranitCardTitle('receita vs despesa — mensal')
// =============================================================================

class GranitCardTitle extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const GranitCardTitle(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GranitTokens.labelTiny,
      ),
    );
  }
}
