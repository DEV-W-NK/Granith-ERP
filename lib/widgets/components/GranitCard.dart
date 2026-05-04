import 'package:flutter/material.dart';
import 'package:project_granith/constants/GranitTokens.dart';
import 'package:project_granith/themes/app_theme.dart';

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

  const GranitCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GranitTokens.cardPadding),
    this.backgroundColor,
    this.customBorder,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      gradient: AppColors.cardGradient,
      color: backgroundColor ?? AppColors.surfaceDark.withValues(alpha: 0.76),
      borderRadius: borderRadius ?? GranitTokens.cardRadius,
      border:
          customBorder ??
          Border.all(color: AppColors.borderColor.withValues(alpha: 0.72)),
      boxShadow: AppColors.glowShadows(),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? GranitTokens.cardRadius,
        child: Ink(
          decoration: decoration,
          child: Padding(padding: padding, child: child),
        ),
      );
    }

    return Container(padding: padding, decoration: decoration, child: child);
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
      child: Text(text.toUpperCase(), style: GranitTokens.labelTiny),
    );
  }
}
