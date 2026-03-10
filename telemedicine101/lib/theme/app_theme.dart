import 'package:flutter/material.dart';

/// Modern design tokens for the Telemedicine Flutter app
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF0D9488); // teal-600
  static const Color primaryLight = Color(0xFF14B8A6); // teal-500
  static const Color primaryDark = Color(0xFF0F766E); // teal-700

  // Secondary/Accent colors
  static const Color secondary = Color(0xFF8B5CF6); // violet-500
  static const Color secondaryLight = Color(0xFFA78BFA); // violet-400
  static const Color secondaryDark = Color(0xFF7C3AED); // violet-600

  // Background colors
  static const Color background = Color(0xFFF8FAFC); // slate-50
  static const Color backgroundAlt = Color(0xFFF1F5F9); // slate-100

  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Semantic colors
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color errorLight = Color(0xFFFEE2E2); // red-100
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color successLight = Color(0xFFD1FAE5); // emerald-100
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color warningLight = Color(0xFFFEF3C7); // amber-100
  static const Color info = Color(0xFF3B82F6); // blue-500
  static const Color infoLight = Color(0xFFDBEAFE); // blue-100

  // Text colors
  static const Color textPrimary = Color(0xFF1E293B); // slate-800
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textTertiary = Color(0xFF64748B); // slate-500
  static const Color textDisabled = Color(0xFF94A3B8); // slate-400
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Border colors
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderFocused = Color(0xFF0D9488); // primary

  // Divider
  static const Color divider = Color(0xFFE2E8F0);
}

/// Spacing constants following 4px base unit
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

/// Border radius constants
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

/// Shadow definitions for modern elevation
class AppShadows {
  static const BoxShadow sm = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow xl = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 20,
    offset: Offset(0, 8),
  );

  // Layered shadows for cards
  static List<BoxShadow> get card => [md];

  // Layered shadows for elevated elements
  static List<BoxShadow> get elevated => [md, lg];
}

/// Typography scale using system fonts for performance
class AppTypography {
  static const String fontFamily = 'System';

  // Font sizes
  static const double displayLarge = 32.0;
  static const double displayMedium = 28.0;
  static const double displaySmall = 24.0;
  static const double headlineLarge = 22.0;
  static const double headlineMedium = 20.0;
  static const double headlineSmall = 18.0;
  static const double titleLarge = 16.0;
  static const double titleMedium = 14.0;
  static const double titleSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;

  // Line heights
  static const double lineHeightTight = 1.25;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Letter spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
}

/// Main app theme builder
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnSecondary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    // Color scheme
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnSecondary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    ),

    // AppBar theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
    ),

    // Text theme with system fonts
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displayLarge,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displayMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displayMedium,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displaySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displaySmall,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightTight,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineSmall,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      titleLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleLarge,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      titleMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleMedium,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      titleSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleSmall,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: AppTypography.lineHeightNormal,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyLarge,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightRelaxed,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: AppTypography.lineHeightRelaxed,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: AppTypography.lineHeightNormal,
      ),
      labelLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelLarge,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      labelMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelMedium,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: AppTypography.lineHeightNormal,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSmall,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        height: AppTypography.lineHeightNormal,
        letterSpacing: AppTypography.letterSpacingWide,
      ),
    ),

    // Card theme
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      color: AppColors.surface,
      margin: EdgeInsets.all(AppSpacing.sm),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(88, 48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.labelLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size(88, 48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.labelLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(64, 40),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.labelLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
    ),

    // Input decoration theme
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: AppColors.borderFocused, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      hintStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      ),
      errorStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: FontWeight.w400,
        color: AppColors.error,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      ),
    ),

    // Chip theme
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelMedium,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSmall,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSmall,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Navigation bar theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryLight.withValues(alpha: 0.2),
      elevation: 0,
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.textTertiary, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.labelSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.labelSmall,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        );
      }),
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // List tile theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      tileColor: AppColors.surface,
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
      minLeadingWidth: 24,
    ),

    // Dialog theme
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineSmall,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
    ),

    // Snackbar theme
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: FontWeight.w400,
        color: AppColors.surface,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      behavior: SnackBarBehavior.floating,
    ),

    // Icon theme
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

    // Primary icon theme
    primaryIconTheme: const IconThemeData(color: AppColors.primary, size: 24),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      circularTrackColor: AppColors.surfaceVariant,
      linearTrackColor: AppColors.surfaceVariant,
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLight.withValues(alpha: 0.5);
        }
        return AppColors.border;
      }),
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.textTertiary, width: 2),
    ),

    // Radio theme
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.textTertiary;
      }),
    ),

    // Tab bar theme
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textTertiary,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelLarge,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelLarge,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Text selection theme
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primaryLight.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.primary,
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
