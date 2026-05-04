import 'package:flutter/material.dart';

class GranithPageTransitionsBuilder extends PageTransitionsBuilder {
  const GranithPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.016, 0.028),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.992, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class AppColors {
  static const Color primaryDark = Color(0xFF09111F);
  static const Color secondaryDark = Color(0xFF101B30);
  static const Color surfaceDark = Color(0xFF17243A);
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color backgroundMid = Color(0xFF111C31);
  static const Color surfaceElevated = Color(0xFF20304C);

  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentBlue = Color(0xFF6EA8FF);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color accentRed = Color(0xFFE74C3C);

  static const Color duskBlue = Color(0xFF5C8DFF);
  static const Color auraBlue = Color(0xFF7AB8FF);
  static const Color auraCyan = Color(0xFF57E3D0);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB9C7E1);
  static const Color textMuted = Color(0xFF74829D);

  static const Color borderColor = Color(0xFF29415F);
  static const Color dividerColor = Color(0xFF1E2A42);

  static const Color accentGoldSubtle = Color(0x26D4AF37);
  static const Color accentGoldMedium = Color(0x4DD4AF37);
  static const Color accentGoldFaint = Color(0x1AD4AF37);
  static const Color accentBlueSubtle = Color(0x264A90E2);
  static const Color accentBlueFaint = Color(0x1A4A90E2);
  static const Color accentRedSubtle = Color(0x33E74C3C);
  static const Color surfaceDarkSubtle = Color(0x802D2D2D);
  static const Color surfaceDarkFaint = Color(0x4D2D2D2D);
  static const Color borderSubtle = Color(0x4D3D3D3D);
  static const Color borderFaint = Color(0x333D3D3D);
  static const Color textMutedSubtle = Color(0xCC6C6C6C);
  static const Color textMutedFaint = Color(0x996C6C6C);
  static const Color textMutedGhost = Color(0x1A6C6C6C);
  static const Color blackScrim10 = Color(0x1A000000);
  static const Color blackScrim15 = Color(0x26000000);
  static const Color blackScrim8 = Color(0x14000000);

  static const Color bg = Color(0xFF0F1117);
  static const Color s1 = Color(0xFF161B27);
  static const Color s2 = Color(0xFF1C2333);
  static const Color s3 = Color(0xFF222A3D);
  static const Color border = Color(0x12FFFFFF);
  static const Color border2 = Color(0x1FFFFFFF);
  static const Color gold = Color(0xFFC9A84C);
  static const Color gold2 = Color(0xFFE8C56A);
  static const Color goldDim = Color(0x22C9A84C);
  static const Color tx = Color(0xFFE8EAF0);
  static const Color tx2 = Color(0xFF8B93A8);
  static const Color tx3 = Color(0xFF5A6178);
  static const Color green = Color(0xFF3ECF8E);
  static const Color greenDim = Color(0x1A3ECF8E);
  static const Color red = Color(0xFFF87171);
  static const Color redDim = Color(0x1AF87171);
  static const Color orange = Color(0xFFFB923C);
  static const Color blue = Color(0xFF60A5FA);
  static const Color purple = Color(0xFFA78BFA);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF142442),
      Color(0xFF0D1830),
      Color(0xFF101A2A),
      Color(0xFF19273F),
    ],
    stops: [0.0, 0.28, 0.68, 1.0],
  );

  static const LinearGradient pageSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCC20304C), Color(0xB316243A), Color(0xCC101B30)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE620304C), Color(0xD9142238), Color(0xE6111B30)],
  );

  static List<BoxShadow> glowShadows([Color glowColor = accentBlue]) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.24),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: glowColor.withValues(alpha: 0.10),
      blurRadius: 32,
      spreadRadius: -8,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> auraShadows([Color glowColor = accentGold]) => [
    BoxShadow(
      color: glowColor.withValues(alpha: 0.14),
      blurRadius: 38,
      spreadRadius: -10,
      offset: const Offset(0, 14),
    ),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.accentBlue,
      secondary: AppColors.accentGold,
      surface: Colors.transparent,
      error: AppColors.accentRed,
      onPrimary: AppColors.textPrimary,
      onSecondary: AppColors.primaryDark,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accentBlue,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      cardColor: Colors.transparent,
      dividerColor: AppColors.dividerColor,
      colorScheme: colorScheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark.withValues(alpha: 0.38),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.primaryDark.withValues(alpha: 0.82),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.92),
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.7)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.85),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark.withValues(alpha: 0.76),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    ).copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GranithPageTransitionsBuilder(),
          TargetPlatform.iOS: GranithPageTransitionsBuilder(),
          TargetPlatform.macOS: GranithPageTransitionsBuilder(),
          TargetPlatform.windows: GranithPageTransitionsBuilder(),
          TargetPlatform.linux: GranithPageTransitionsBuilder(),
        },
      ),
    );
  }
}
