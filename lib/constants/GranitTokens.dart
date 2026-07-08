import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Shared visual tokens for the Granith ERP interface.
abstract final class GranitTokens {
  static const Color bg = Color(0xFF050708);
  static const Color surface1 = Color(0xFF141B1E);
  static const Color surface2 = Color(0xFF1A2326);
  static const Color surface3 = Color(0xFF223033);

  static const Color border = Color(0x12FFFFFF);
  static const Color border2 = Color(0x1FFFFFFF);

  static const Color gold = Color(0xFFE3B84A);
  static const Color gold2 = Color(0xFFFFD782);
  static const Color goldDim = Color(0x22E3B84A);

  static const Color textPrimary = Color(0xFFF4F7F6);
  static const Color textSecondary = Color(0xFFBAC7C4);
  static const Color textMuted = Color(0xFF7C8B89);

  static const Color green = Color(0xFF35D486);
  static const Color greenDim = Color(0x1A35D486);
  static const Color red = Color(0xFFFF6B6B);
  static const Color redDim = Color(0x1AFF6B6B);
  static const Color orange = Color(0xFFFFA657);
  static const Color orangeDim = Color(0x1AFFA657);
  static const Color blue = Color(0xFF67D6FF);
  static const Color blueDim = Color(0x1A67D6FF);
  static const Color purple = Color(0xFFC39BFF);
  static const Color purpleDim = Color(0x1AC39BFF);

  static const List<Color> chartColors = [
    green,
    blue,
    gold,
    orange,
    purple,
    red,
  ];

  static const double paddingPage = 28.0;
  static const double paddingPageMob = 16.0;
  static const double cardPadding = 16.0;
  static const double gapCard = 14.0;
  static const double gapSection = 24.0;
  static const double radiusCard = 12.0;
  static const double radiusBtn = 10.0;

  static final BorderRadius cardRadius = BorderRadius.circular(radiusCard);
  static final BorderRadius btnRadius = BorderRadius.circular(radiusBtn);

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

  static final NumberFormat brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

  static String brlCompact(double v) {
    if (v.abs() >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }

  static const TextStyle labelSmall = TextStyle(
    color: textMuted,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const TextStyle labelTiny = TextStyle(
    color: textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
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
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  static const TextStyle headingStyle = TextStyle(
    color: textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

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
