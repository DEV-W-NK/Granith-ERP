import 'package:flutter/material.dart';

class AppColors {
  // Tons principais escuros e elegantes
  static const Color primaryDark = Color(0xFF0A0A0A);        // Preto principal
  static const Color secondaryDark = Color(0xFF1A1A1A);      // Cinza muito escuro
  static const Color surfaceDark = Color(0xFF2D2D2D);        // Superfície dos cards
  static const Color backgroundDark = Color(0xFF121212);     // Background geral
  
  // Tons de destaque elegantes
  static const Color accentGold = Color(0xFFD4AF37);         // Dourado elegante
  static const Color accentBlue = Color(0xFF4A90E2);         // Azul corporativo
  static const Color accentGreen = Color(0xFF27AE60);        // Verde sucesso
  static const Color accentRed = Color(0xFFE74C3C);          // Vermelho alerta
  
  // Tons de texto
  static const Color textPrimary = Color(0xFFFFFFFF);        // Texto principal
  static const Color textSecondary = Color(0xFFB0B0B0);     // Texto secundário
  static const Color textMuted = Color(0xFF6C6C6C);         // Texto discreto
  
  // Tons de borda e divisores
  static const Color borderColor = Color(0xFF3D3D3D);       // Bordas
  static const Color dividerColor = Color(0xFF2A2A2A);      // Divisores
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
      elevation: 0, // Remova a elevação padrão para controlar com border/boxShadow nos widgets
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Bordas mais arredondadas (moderno)
        side: const BorderSide(
          color: AppColors.borderColor, // Borda sutil global
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