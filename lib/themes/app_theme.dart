import 'package:flutter/material.dart';

class AppColors {
  // ─── TONS PRINCIPAIS (Design System Oficial) ──────────────────────────────
  static const Color primaryDark = Color(0xFF0A0A0A);
  static const Color secondaryDark = Color(0xFF1A1A1A);
  static const Color surfaceDark = Color(0xFF2D2D2D);
  static const Color backgroundDark = Color(0xFF121212);

  // ─── TONS DE DESTAQUE ───────────────────────────────────────────────────
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentRed = Color(0xFFE74C3C);

  // ─── TONS DE TEXTO ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6C6C6C);

  // ─── TONS DE BORDA E DIVISORES ──────────────────────────────────────────
  static const Color borderColor = Color(0xFF3D3D3D);
  static const Color dividerColor = Color(0xFF2A2A2A);

  // ─── PRE-BLENDED VARIANTS (Opacidades) ──────────────────────────────────
  static const Color accentGoldSubtle   = Color(0x26D4AF37);
  static const Color accentGoldMedium   = Color(0x4DD4AF37);
  static const Color accentGoldFaint    = Color(0x1AD4AF37);
  static const Color accentBlueSubtle   = Color(0x264A90E2);
  static const Color accentBlueFaint    = Color(0x1A4A90E2);
  static const Color accentRedSubtle    = Color(0x33E74C3C);
  static const Color surfaceDarkSubtle  = Color(0x802D2D2D);
  static const Color surfaceDarkFaint   = Color(0x4D2D2D2D);
  static const Color borderSubtle       = Color(0x4D3D3D3D);
  static const Color borderFaint        = Color(0x333D3D3D);
  static const Color textMutedSubtle    = Color(0xCC6C6C6C);
  static const Color textMutedFaint     = Color(0x996C6C6C);
  static const Color textMutedGhost     = Color(0x1A6C6C6C);
  static const Color blackScrim10       = Color(0x1A000000);
  static const Color blackScrim15       = Color(0x26000000);
  static const Color blackScrim8        = Color(0x14000000);

  // ─── TOKENS LEGADOS / MIGRAÇÃO (Mantidos para não quebrar componentes) ────
  // Com o tempo, substitua `bg` por `backgroundDark`, `s1` por `surfaceDark`, etc.
  static const bg      = Color(0xFF0F1117);
  static const s1      = Color(0xFF161B27);
  static const s2      = Color(0xFF1C2333);
  static const s3      = Color(0xFF222A3D);
  static const border  = Color(0x12FFFFFF);
  static const border2 = Color(0x1FFFFFFF);
  static const gold    = Color(0xFFC9A84C);
  static const gold2   = Color(0xFFE8C56A);
  static const goldDim = Color(0x22C9A84C);
  static const tx      = Color(0xFFE8EAF0);
  static const tx2     = Color(0xFF8B93A8);
  static const tx3     = Color(0xFF5A6178);
  static const green   = Color(0xFF3ECF8E);
  static const greenDim= Color(0x1A3ECF8E);
  static const red     = Color(0xFFF87171);
  static const redDim  = Color(0x1AF87171);
  static const orange  = Color(0xFFFB923C);
  static const blue    = Color(0xFF60A5FA);
  static const purple  = Color(0xFFA78BFA);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.accentGold,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.dividerColor,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGold,
        secondary: AppColors.accentBlue,
        surface: AppColors.surfaceDark,
        error: AppColors.accentRed,
        onPrimary: AppColors.primaryDark,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
    );
  }
}