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
  static const Color primaryDark = Color(0xFF070A0C);
  static const Color secondaryDark = Color(0xFF0D1214);
  static const Color surfaceDark = Color(0xFF141B1E);
  static const Color backgroundDark = Color(0xFF050708);
  static const Color backgroundMid = Color(0xFF0E1517);
  static const Color surfaceElevated = Color(0xFF1D272A);

  static const Color accentGold = Color(0xFFE3B84A);
  static const Color accentBlue = Color(0xFF41D9BE);
  static const Color accentGreen = Color(0xFF35D486);
  static const Color accentRed = Color(0xFFFF6B6B);

  static const Color duskBlue = Color(0xFF6CA8FF);
  static const Color auraBlue = Color(0xFF67D6FF);
  static const Color auraCyan = Color(0xFF2DE6D0);

  static const Color textPrimary = Color(0xFFF4F7F6);
  static const Color textSecondary = Color(0xFFBAC7C4);
  static const Color textMuted = Color(0xFF7C8B89);

  static const Color borderColor = Color(0xFF2A3A3D);
  static const Color dividerColor = Color(0xFF1A2528);

  static const Color accentGoldSubtle = Color(0x26E3B84A);
  static const Color accentGoldMedium = Color(0x4DE3B84A);
  static const Color accentGoldFaint = Color(0x1AE3B84A);
  static const Color accentBlueSubtle = Color(0x2641D9BE);
  static const Color accentBlueFaint = Color(0x1A41D9BE);
  static const Color accentRedSubtle = Color(0x33FF6B6B);
  static const Color surfaceDarkSubtle = Color(0x80141B1E);
  static const Color surfaceDarkFaint = Color(0x4D141B1E);
  static const Color borderSubtle = Color(0x4D2A3A3D);
  static const Color borderFaint = Color(0x332A3A3D);
  static const Color textMutedSubtle = Color(0xCC7C8B89);
  static const Color textMutedFaint = Color(0x997C8B89);
  static const Color textMutedGhost = Color(0x1A7C8B89);
  static const Color blackScrim10 = Color(0x1A000000);
  static const Color blackScrim15 = Color(0x26000000);
  static const Color blackScrim8 = Color(0x14000000);

  static const Color bg = Color(0xFF050708);
  static const Color s1 = Color(0xFF141B1E);
  static const Color s2 = Color(0xFF1A2326);
  static const Color s3 = Color(0xFF223033);
  static const Color border = Color(0x12FFFFFF);
  static const Color border2 = Color(0x1FFFFFFF);
  static const Color gold = Color(0xFFE3B84A);
  static const Color gold2 = Color(0xFFFFD782);
  static const Color goldDim = Color(0x22E3B84A);
  static const Color tx = Color(0xFFF4F7F6);
  static const Color tx2 = Color(0xFFBAC7C4);
  static const Color tx3 = Color(0xFF7C8B89);
  static const Color green = Color(0xFF35D486);
  static const Color greenDim = Color(0x1A35D486);
  static const Color red = Color(0xFFFF6B6B);
  static const Color redDim = Color(0x1AFF6B6B);
  static const Color orange = Color(0xFFFFA657);
  static const Color blue = Color(0xFF67D6FF);
  static const Color purple = Color(0xFFC39BFF);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050708),
      Color(0xFF0E1412),
      Color(0xFF071313),
      Color(0xFF15130E),
    ],
    stops: [0.0, 0.34, 0.72, 1.0],
  );

  static const LinearGradient pageSurfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xF01D272A), Color(0xE50E1517), Color(0xEE161710)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xF21E292C), Color(0xE812191B), Color(0xF0181A14)],
  );

  static List<BoxShadow> glowShadows([Color glowColor = accentBlue]) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.34),
      blurRadius: 30,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: glowColor.withValues(alpha: 0.08),
      blurRadius: 34,
      spreadRadius: -10,
      offset: const Offset(0, 14),
    ),
  ];

  static List<BoxShadow> auraShadows([Color glowColor = accentGold]) => [
    BoxShadow(
      color: glowColor.withValues(alpha: 0.12),
      blurRadius: 36,
      spreadRadius: -12,
      offset: const Offset(0, 14),
    ),
  ];
}

class AppDecorations {
  static BoxDecoration cardSurface({
    Color? accent,
    bool emphasized = false,
    bool elevated = true,
    double radius = 16,
  }) {
    final resolvedAccent = accent ?? AppColors.accentBlue;
    final borderColor = accent ?? AppColors.borderColor;

    return BoxDecoration(
      gradient: AppColors.cardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor.withValues(alpha: accent == null ? 0.62 : 0.34),
      ),
      boxShadow:
          elevated
              ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: emphasized ? 0.38 : 0.30,
                  ),
                  blurRadius: emphasized ? 34 : 24,
                  offset: Offset(0, emphasized ? 18 : 12),
                ),
                BoxShadow(
                  color: resolvedAccent.withValues(
                    alpha: emphasized ? 0.12 : 0.08,
                  ),
                  blurRadius: emphasized ? 38 : 28,
                  spreadRadius: -12,
                  offset: const Offset(0, 12),
                ),
              ]
              : null,
    );
  }

  static BoxDecoration statCardSurface(Color accent, {double radius = 16}) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.surfaceElevated.withValues(alpha: 0.80),
            AppColors.backgroundMid.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 30,
            spreadRadius: -12,
            offset: const Offset(0, 12),
          ),
        ],
      );

  static BoxDecoration cardInnerSurface({Color? accent, double radius = 12}) =>
      BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (accent ?? AppColors.borderColor).withValues(
            alpha: accent == null ? 0.48 : 0.24,
          ),
        ),
      );

  static BoxDecoration dialogSurface({Color? glowColor}) => BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.72)),
    boxShadow: AppColors.glowShadows(glowColor ?? AppColors.accentBlue),
  );

  static BoxDecoration dialogHeader({Color? accent}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.surfaceElevated.withValues(alpha: 0.98),
        AppColors.backgroundMid.withValues(alpha: 0.96),
      ],
    ),
    border: Border(
      bottom: BorderSide(
        color: (accent ?? AppColors.accentBlue).withValues(alpha: 0.22),
      ),
    ),
  );

  static BoxDecoration formPanel({Color? borderColor}) => BoxDecoration(
    color: AppColors.surfaceDark.withValues(alpha: 0.58),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: (borderColor ?? AppColors.borderColor).withValues(alpha: 0.42),
    ),
  );

  static BoxDecoration formHintPanel({Color color = AppColors.accentBlue}) =>
      BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      );

  static BoxDecoration iconTile(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: color.withValues(alpha: 0.30)),
    boxShadow: AppColors.auraShadows(color),
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.accentBlue,
      secondary: AppColors.accentGold,
      tertiary: AppColors.accentGreen,
      primaryContainer: const Color(0xFF0E3D39),
      secondaryContainer: const Color(0xFF3D3010),
      tertiaryContainer: const Color(0xFF113A29),
      surface: AppColors.backgroundMid,
      surfaceDim: AppColors.backgroundDark,
      surfaceBright: AppColors.surfaceElevated,
      surfaceContainerLowest: AppColors.primaryDark,
      surfaceContainerLow: AppColors.secondaryDark,
      surfaceContainer: AppColors.surfaceDark,
      surfaceContainerHigh: AppColors.surfaceElevated,
      surfaceContainerHighest: AppColors.s3,
      error: AppColors.accentRed,
      outline: AppColors.borderColor,
      outlineVariant: AppColors.dividerColor,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
      inverseSurface: AppColors.textPrimary,
      inversePrimary: AppColors.primaryDark,
      onPrimary: AppColors.primaryDark,
      onSecondary: AppColors.primaryDark,
      onTertiary: AppColors.primaryDark,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      onError: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accentBlue,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: AppColors.surfaceDark.withValues(alpha: 0.98),
      cardColor: Colors.transparent,
      dividerColor: AppColors.dividerColor,
      colorScheme: colorScheme,
      focusColor: AppColors.accentBlue.withValues(alpha: 0.16),
      hoverColor: AppColors.accentBlue.withValues(alpha: 0.08),
      highlightColor: AppColors.accentBlue.withValues(alpha: 0.12),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark.withValues(alpha: 0.58),
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
          foregroundColor: AppColors.primaryDark,
          disabledBackgroundColor: AppColors.surfaceElevated.withValues(
            alpha: 0.52,
          ),
          disabledForegroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.primaryDark,
          disabledBackgroundColor: AppColors.surfaceElevated.withValues(
            alpha: 0.52,
          ),
          disabledForegroundColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.82),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          hoverColor: AppColors.accentBlue.withValues(alpha: 0.10),
          highlightColor: AppColors.accentBlue.withValues(alpha: 0.14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            AppColors.surfaceDark.withValues(alpha: 0.98),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.75),
              ),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevated.withValues(alpha: 0.54),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            AppColors.surfaceDark.withValues(alpha: 0.98),
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.62),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.primaryDark.withValues(alpha: 0.82),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.textMuted.withValues(alpha: 0.42),
        ),
        trackColor: WidgetStatePropertyAll(
          AppColors.surfaceDark.withValues(alpha: 0.20),
        ),
        radius: const Radius.circular(999),
        thickness: const WidgetStatePropertyAll(6),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.75),
          ),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        minLeadingWidth: 28,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textSecondary,
        selectedColor: AppColors.textPrimary,
        selectedTileColor: AppColors.accentBlue.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
          if (states.contains(WidgetState.selected)) {
            return AppColors.textPrimary;
          }
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceElevated.withValues(alpha: 0.32);
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue.withValues(alpha: 0.72);
          }
          return AppColors.surfaceElevated.withValues(alpha: 0.72);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue.withValues(alpha: 0.75);
          }
          return AppColors.borderColor.withValues(alpha: 0.75);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.9)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return AppColors.surfaceDark.withValues(alpha: 0.8);
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.textPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return AppColors.textMuted;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.58),
        selectedColor: AppColors.accentBlue.withValues(alpha: 0.18),
        disabledColor: AppColors.surfaceElevated.withValues(alpha: 0.35),
        deleteIconColor: AppColors.textMuted,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        side: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.68)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.accentBlue,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.24),
          ),
        ),
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
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.72),
          ),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.42,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated.withValues(alpha: 0.52),
        hoverColor: AppColors.accentBlue.withValues(alpha: 0.07),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.72),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.72),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.35),
          ),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.accentBlue),
        errorStyle: const TextStyle(
          color: AppColors.accentRed,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderColor.withValues(alpha: 0.42),
        space: 1,
        thickness: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surfaceDark.withValues(alpha: 0.98),
        modalBarrierColor: Colors.black.withValues(alpha: 0.62),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.42),
        collapsedBackgroundColor: Colors.transparent,
        iconColor: AppColors.accentBlue,
        collapsedIconColor: AppColors.textMuted,
        textColor: AppColors.textPrimary,
        collapsedTextColor: AppColors.textSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        headingRowColor: WidgetStatePropertyAll(
          AppColors.surfaceElevated.withValues(alpha: 0.36),
        ),
        dividerThickness: 1,
        decoration: AppDecorations.formPanel(),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
          overlayColor: WidgetStatePropertyAll(
            AppColors.accentBlue.withValues(alpha: 0.08),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.72),
          ),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accentBlue,
        circularTrackColor: AppColors.surfaceElevated.withValues(alpha: 0.42),
        linearTrackColor: AppColors.surfaceElevated.withValues(alpha: 0.42),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentBlue,
        inactiveTrackColor: AppColors.surfaceElevated.withValues(alpha: 0.72),
        thumbColor: AppColors.textPrimary,
        overlayColor: AppColors.accentBlue.withValues(alpha: 0.16),
        trackHeight: 4,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
        headerForegroundColor: AppColors.textPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          if (states.contains(WidgetState.disabled)) return AppColors.textMuted;
          return AppColors.textSecondary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accentBlue;
          }
          return Colors.transparent;
        }),
        todayForegroundColor: const WidgetStatePropertyAll(
          AppColors.accentGold,
        ),
        todayBorder: const BorderSide(color: AppColors.accentGold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.72),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.12,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.16,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.28,
        ),
        titleSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.28,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        labelSmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.46,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.42,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          height: 1.35,
        ),
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
