import 'package:flutter/material.dart';

// ─── Bloom Design Tokens ─────────────────────────────────────────────────────

class AppColors {
  // Brand Purple
  static const Color primary = Color(0xFF7C49E6);
  static const Color primaryLight = Color(0xFF9468F2);
  static const Color primaryDark = Color(0xFF6434C9);

  // Brand Lime
  static const Color lime = Color(0xFFD8FF4A);
  static const Color limeDark = Color(0xFFB8EE3A);
  static const Color limeAlt = Color(0xFFCCFF57);

  // Semantic
  static const Color error = Color(0xFFFF5C72);
  static const Color warning = Color(0xFFFFC15C);
  static const Color warningText = Color(0xFFC97B12);

  // ─── Dark Theme Surfaces ───────────────────────────────────────────────────
  static const Color darkPageBg = Color(0xFF0B1518);
  static const Color darkScreenBg = Color(0xFF12282E);
  static const Color darkSurface = Color(0xFF1C363D);
  static const Color darkGhost = Color(0xFF234049);
  static const Color darkBorder = Color(0x14FFFFFF); // 8% white
  static const Color darkBorderSubtle = Color(0x0DFFFFFF); // 5% white

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0x99FFFFFF); // 60%
  static const Color darkTextMuted = Color(0x66FFFFFF); // 40%

  // ─── Light Theme Surfaces ─────────────────────────────────────────────────
  static const Color lightPageBg = Color(0xFFF6F3FA);
  static const Color lightScreenBg = Color(0xFFFAF8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGhost = Color(0xFFF1ECFA);
  static const Color lightBorder = Color(0x14140A1E); // 8% dark
  static const Color lightBorderSubtle = Color(0x0D140A1E); // 5% dark

  static const Color lightTextPrimary = Color(0xFF1E1B24);
  static const Color lightTextSecondary = Color(0xA6140A1E); // 65%
  static const Color lightTextMuted = Color(0x6B140A1E); // 42%

  // Aliases used through codebase
  static const Color background = darkScreenBg;
  static const Color surface = darkSurface;
  static const Color surfaceVariant = darkGhost;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textTertiary = darkTextMuted;
  static const Color border = darkBorder;

  // Success/lime convenience
  static const Color success = lime;
  static const Color successLight = Color(0x28D8FF4A); // 16% lime

  // Secondary accent (lime, used alongside success in stat/badge contexts)
  static const Color secondary = lime;
  static const Color secondaryLight = Color(0x28D8FF4A); // 16% lime

  // Informational accent (purple-light, used for neutral/info badges & CTAs)
  static const Color info = primaryLight;
  static const Color infoLight = Color(0x289468F2); // 16% primaryLight

  // Warning/error tints
  static const Color warningLight = Color(0x28FFC15C); // 16% warning
  static const Color errorLight = Color(0x28FF5C72); // 16% error
}

/// Font-size scale (paired with BloomTextStyles / the shared TextTheme).
class AppTypography {
  static const double displayLarge = 26;
  static const double displayMedium = 22;
  static const double displaySmall = 19;
  static const double headlineLarge = 17;
  static const double headlineMedium = 15;
  static const double headlineSmall = 13.5;
  static const double titleLarge = 13.5;
  static const double titleMedium = 12.5;
  static const double titleSmall = 11.5;
  static const double bodyLarge = 12;
  static const double bodyMedium = 11;
  static const double bodySmall = 10.5;
  static const double labelLarge = 12;
  static const double labelMedium = 10.5;
  static const double labelSmall = 8.5;
}

/// Shared box-shadow presets for elevated surfaces on dark backgrounds.
class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 30, offset: Offset(0, 14)),
  ];
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 20.0; // alias of `card`, used by list/detail screens
  static const double card = 20.0;
  static const double tile = 14.0;
  static const double full = 999.0;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius tileAll = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

class BloomTextStyles {
  // Fraunces — display / headings
  static TextStyle fraunces({
    double size = 22,
    FontWeight weight = FontWeight.w300,
    Color color = AppColors.darkTextPrimary,
    double? height,
  }) => TextStyle(fontFamily: 'Fraunces', 
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  // Inter — body / UI
  static TextStyle inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.darkTextPrimary,
    double? letterSpacing,
    double? height,
  }) => TextStyle(fontFamily: 'Inter', 
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  // IBM Plex Mono — data / prices / timestamps
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.darkTextPrimary,
  }) =>
      TextStyle(fontFamily: 'IBM Plex Mono', fontSize: size, fontWeight: weight, color: color);
}

// ─── Dark Theme ───────────────────────────────────────────────────────────────

ThemeData buildDarkTheme() {
  const cs = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryDark,
    secondary: AppColors.lime,
    onSecondary: AppColors.darkPageBg,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    error: AppColors.error,
    onError: Colors.white,
    surfaceContainerHighest: AppColors.darkGhost,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.darkScreenBg,
    textTheme: _buildTextTheme(AppColors.darkTextPrimary),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.darkScreenBg,
      foregroundColor: AppColors.darkTextPrimary,
      centerTitle: false,
      titleTextStyle: BloomTextStyles.inter(
        size: 13.5,
        weight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextPrimary,
        size: 20,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(42),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        textStyle: BloomTextStyles.inter(
          size: 12,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkTextPrimary,
        minimumSize: const Size.fromHeight(42),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
        backgroundColor: AppColors.darkGhost,
        textStyle: BloomTextStyles.inter(size: 12, weight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: BloomTextStyles.inter(
        size: 12,
        color: AppColors.darkTextMuted,
      ),
      labelStyle: BloomTextStyles.inter(size: 10, weight: FontWeight.w600),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.lime,
      unselectedItemColor: Color(0x66FFFFFF),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.darkGhost,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkGhost,
      selectedColor: AppColors.primary,
      labelStyle: BloomTextStyles.inter(size: 10.5, weight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
      side: const BorderSide(color: AppColors.darkBorder, width: 1),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.darkTextSecondary,
      size: 20,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

// ─── Light Theme ──────────────────────────────────────────────────────────────

ThemeData buildLightTheme() {
  const cs = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.lightGhost,
    secondary: AppColors.primaryDark,
    onSecondary: Colors.white,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    error: AppColors.error,
    onError: Colors.white,
    surfaceContainerHighest: AppColors.lightGhost,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.lightScreenBg,
    textTheme: _buildTextTheme(AppColors.lightTextPrimary),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.lightScreenBg,
      foregroundColor: AppColors.lightTextPrimary,
      centerTitle: false,
      titleTextStyle: BloomTextStyles.inter(
        size: 13.5,
        weight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(42),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 1,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 0,
    ),
  );
}

// ─── Shared TextTheme ─────────────────────────────────────────────────────────

TextTheme _buildTextTheme(Color base) => TextTheme(
  displayLarge: TextStyle(fontFamily: 'Fraunces', 
    fontSize: 26,
    fontWeight: FontWeight.w300,
    color: base,
  ),
  displayMedium: TextStyle(fontFamily: 'Fraunces', 
    fontSize: 22,
    fontWeight: FontWeight.w300,
    color: base,
  ),
  displaySmall: TextStyle(fontFamily: 'Fraunces', 
    fontSize: 19,
    fontWeight: FontWeight.w400,
    color: base,
  ),
  headlineLarge: TextStyle(fontFamily: 'Fraunces', 
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: base,
  ),
  headlineMedium: TextStyle(fontFamily: 'Fraunces', 
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: base,
  ),
  headlineSmall: TextStyle(fontFamily: 'Inter', 
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: base,
  ),
  titleLarge: TextStyle(fontFamily: 'Inter', 
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: base,
  ),
  titleMedium: TextStyle(fontFamily: 'Inter', 
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: base,
  ),
  titleSmall: TextStyle(fontFamily: 'Inter', 
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: base,
  ),
  bodyLarge: TextStyle(fontFamily: 'Inter', 
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: base,
  ),
  bodyMedium: TextStyle(fontFamily: 'Inter', 
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: base,
  ),
  bodySmall: TextStyle(fontFamily: 'Inter', 
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    color: base,
  ),
  labelLarge: TextStyle(fontFamily: 'Inter', 
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: base,
  ),
  labelMedium: TextStyle(fontFamily: 'Inter', 
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: base,
    letterSpacing: 0.04,
  ),
  labelSmall: TextStyle(fontFamily: 'Inter', 
    fontSize: 8.5,
    fontWeight: FontWeight.w600,
    color: base,
    letterSpacing: 0.05,
  ),
);

// Legacy alias so existing code using buildAppTheme() still compiles
ThemeData buildAppTheme() => buildDarkTheme();
