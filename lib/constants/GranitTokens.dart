import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// =============================================================================
// GRANIT TOKENS
// Fonte única de verdade para cores, espaçamentos e formatadores do Granith ERP.
// Substitui AppColors + a classe _C inline da ReportsPage.
//
// USO:
//   import 'package:project_granith/theme/granit_tokens.dart';
//   color: GranitTokens.green
//   GranitTokens.brl.format(value)
// =============================================================================

abstract final class GranitTokens {
  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0F1117); // scaffold background
  static const Color surface1 = Color(0xFF161B27); // cards
  static const Color surface2 = Color(0xFF1C2333); // inputs, nested
  static const Color surface3 = Color(0xFF222A3D); // tooltips, hovers

  // ── Borders ─────────────────────────────────────────────────────────────────
  static const Color border = Color(0x12FFFFFF); // sutil — cards
  static const Color border2 = Color(0x1FFFFFFF); // médio — botões, inputs

  // ── Gold (accent principal) ──────────────────────────────────────────────────
  static const Color gold = Color(0xFFC9A84C);
  static const Color gold2 = Color(0xFFE8C56A);
  static const Color goldDim = Color(0x22C9A84C); // fundo de ícones dourados

  // ── Texto ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8B93A8);
  static const Color textMuted = Color(0xFF5A6178);

  // ── Status ──────────────────────────────────────────────────────────────────
  static const Color green = Color(0xFF3ECF8E);
  static const Color greenDim = Color(0x1A3ECF8E);
  static const Color red = Color(0xFFF87171);
  static const Color redDim = Color(0x1AF87171);
  static const Color orange = Color(0xFFFB923C);
  static const Color orangeDim = Color(0x1AFB923C);
  static const Color blue = Color(0xFF60A5FA);
  static const Color blueDim = Color(0x1A60A5FA);
  static const Color purple = Color(0xFFA78BFA);
  static const Color purpleDim = Color(0x1AA78BFA);

  // ── Chart colors (índice estável p/ gráficos de categoria) ─────────────────
  static const List<Color> chartColors = [
    green,
    blue,
    gold,
    orange,
    purple,
    red,
  ];

  // ── Espaçamentos padrão ─────────────────────────────────────────────────────
  static const double paddingPage = 28.0; // desktop
  static const double paddingPageMob = 16.0; // mobile
  static const double cardPadding = 16.0;
  static const double gapCard = 14.0;
  static const double gapSection = 24.0;
  static const double radiusCard = 14.0;
  static const double radiusBtn = 9.0;

  // ── Border radius helpers ───────────────────────────────────────────────────
  static final BorderRadius cardRadius = BorderRadius.circular(radiusCard);
  static final BorderRadius btnRadius = BorderRadius.circular(radiusBtn);

  // ── Decorations reutilizáveis ───────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface1,
    borderRadius: cardRadius,
    border: Border.all(color: border),
  );

  static BoxDecoration get surface2Decoration => BoxDecoration(
    color: surface2,
    borderRadius: btnRadius,
    border: Border.all(color: border),
  );

  // ── Formatadores ────────────────────────────────────────────────────────────
  /// Real brasileiro: R$ 1.234,56
  static final NumberFormat brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

  /// Compacto: R$ 1,2M | R$ 450k | R$ 320
  static String brlCompact(double v) {
    if (v.abs() >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }

  // ── TextStyles base ─────────────────────────────────────────────────────────
  static const TextStyle labelSmall = TextStyle(
    color: textMuted,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle labelTiny = TextStyle(
    color: textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const TextStyle bodySmall = TextStyle(
    color: textSecondary,
    fontSize: 11,
  );

  static const TextStyle bodyMed = TextStyle(
    color: textSecondary,
    fontSize: 12,
  );

  static const TextStyle valueStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headingStyle = TextStyle(
    color: textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  // ── Compatibilidade com AppColors (alias — remover após migração) ───────────
  @Deprecated('Use GranitTokens.bg')
  static const Color backgroundDark = bg;
  @Deprecated('Use GranitTokens.surface1')
  static const Color surfaceDark = surface1;
  @Deprecated('Use GranitTokens.gold')
  static const Color accentGold = gold;
  @Deprecated('Use GranitTokens.textPrimary')
  static const Color textPrimaryLegacy = textPrimary;
  @Deprecated('Use GranitTokens.textSecondary')
  static const Color textSecondaryLegacy = textSecondary;
  @Deprecated('Use GranitTokens.textMuted')
  static const Color textMutedLegacy = textMuted;
  @Deprecated('Use GranitTokens.bg')
  static const Color primaryDark = bg;
}
