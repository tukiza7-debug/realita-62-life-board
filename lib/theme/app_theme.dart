/// Realita +62 design tokens. Indonesian-inspired palette: batik red,
/// cream, deep teal, gold accent. Light + dark variants.
library;

import 'package:flutter/material.dart';

class AppColors {
  // Brand palette
  static const batikRed = Color(0xFFB31919);
  static const putihCream = Color(0xFFFFF8E7);
  static const tealDeep = Color(0xFF0E5A4F);
  static const goldAccent = Color(0xFFD4A23A);
  static const charcoal = Color(0xFF1F1F1F);
  static const corruptPurple = Color(0xFF6A2C8E);
  static const cleanGreen = Color(0xFF1E7D5C);
  static const softGray = Color(0xFFE5E5E5);

  // Dark theme
  static const darkSurface = Color(0xFF111827);
  static const darkOnSurface = Color(0xFFE5E5E5);
  static const darkPrimary = Color(0xFFE55353);
  static const darkAccent = Color(0xFFE8B647);
}

class AppGradients {
  static const creamToTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.putihCream, AppColors.tealDeep],
  );

  static const redToGold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.batikRed, AppColors.goldAccent],
  );
}

class AppMotionDurations {
  static const instant = Duration(milliseconds: 0);
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 400);
  static const emphasis = Duration(milliseconds: 700);
}

class AppMotionCurves {
  static const standard = Curves.easeOut;
  static const emphasized = Curves.easeInOutCubicEmphasized;
  static const springTokenLanding = Curves.elasticOut;
}

/// App-wide Material 3 theme.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = isDark
      ? ColorScheme.fromSeed(
          seedColor: AppColors.batikRed,
          brightness: brightness,
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkOnSurface,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkOnSurface,
          tertiary: AppColors.darkAccent,
        )
      : ColorScheme.fromSeed(
          seedColor: AppColors.batikRed,
          brightness: brightness,
          primary: AppColors.batikRed,
          onPrimary: AppColors.putihCream,
          surface: AppColors.putihCream,
          onSurface: AppColors.charcoal,
          tertiary: AppColors.goldAccent,
        );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
  );
}
