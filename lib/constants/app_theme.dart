import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constants.dart';

class AppTheme {
  AppTheme._();

  static const Color success = Color(0xFF1E8E3E);
  static const Color error = Color(0xFFD9503F);
  static const Color warning = Color(0xFFC9781E);
  static const Color info = Color(0xFF0B7A99);

  static const Color officialBadge = Color(0xFF1E8E3E);
  static const Color communityBadge = Color(0xFF0B7A99);

  static const Color myReportBadge = Color(0xFF7A4FC9);
  static const Color eventBadge = Color(0xFFD9822B);

  static const Color ai = Color(0xFF7B4FD6);
  static const Color aiDeep = Color(0xFF5B34B8);
  static const Color aiSoft = Color(0xFFB79CF2);
  static const Color aiTint = Color(0xFFF0EAFC);
  static const Color actionGreen = Color(0xFF2E9E5B);
  static const Color actionBlue = Color(0xFF2F80D9);
  static const Color actionTeal = Color(0xFF12909C);
  static const Color brandGreen = Color(0xFF2F7D5B);
  static const Color brandDeep = Color(0xFF1F5A44);

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E5CE6), Color(0xFF5B34B8)],
  );

  static const Color background = Color(0xFFF5F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEFF4F1);
  static const Color textPrimary = Color(0xFF16241C);
  static const Color textSecondary = Color(0xFF5B6B62);
  static const Color textTertiary = Color(0xFF93A39A);

  static const Color _darkBackground = Color(0xFF0E1512);
  static const Color _darkSurface = Color(0xFF16201B);
  static const Color _darkSurfaceLight = Color(0xFF202D26);
  static const Color _darkTextPrimary = Color(0xFFEAF2ED);
  static const Color _darkTextSecondary = Color(0xFF9FB0A7);
  static const Color _darkTextTertiary = Color(0xFF6C7D74);

  static const double spaceXSmall = 4;
  static const double spaceSmall = 8;
  static const double spaceMedium = 16;
  static const double spaceLarge = 24;
  static const double spaceXLarge = 32;

  static const double radiusSmall = 8;
  static const double radiusMedium = 14;
  static const double radiusLarge = 22;
  static const double radiusPill = 999;

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get cardShadowDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.36),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static TextStyle get bodyBold => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );
  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.4,
  );

  static Color primaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color secondaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color surfaceLightOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkSurfaceLight
      : surfaceLight;
  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkTextPrimary
      : textPrimary;
  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkTextSecondary
      : textSecondary;
  static Color textTertiaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkTextTertiary
      : textTertiary;
  static List<BoxShadow> shadowOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? cardShadowDark
      : cardShadow;

  static ButtonStyle primaryButtonOf(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: primaryOf(context),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: spaceMedium,
          horizontal: spaceLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: bodyBold,
        elevation: 0,
      );

  static ThemeData lightThemeFor(ColorThemeOption option) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: option.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: option.primary,
          secondary: option.secondary,
          surface: surface,
          error: error,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: h3.copyWith(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: option.primary.withValues(alpha: 0.16),
        labelStyle: bodyBold.copyWith(color: textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceXSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: option.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceMedium,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: option.primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData darkThemeFor(ColorThemeOption option) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: option.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: option.secondary,
          secondary: option.primary,
          surface: _darkSurface,
          error: error,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: _darkBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: _darkTextPrimary, displayColor: _darkTextPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: h3.copyWith(color: _darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceLight,
        selectedColor: option.secondary.withValues(alpha: 0.24),
        labelStyle: bodyBold.copyWith(color: _darkTextPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceXSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: option.secondary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceMedium,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: option.secondary,
        unselectedItemColor: _darkTextTertiary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
