import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LandingColors {
  LandingColors._();

  static const Color bg = Color(0xFFF8F9FC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF4B5563);
  static const Color textFaint = Color(0xFF6B7280);
}

ThemeData buildLandingTheme(BuildContext context) {
  const radius = 12.0;
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: LandingColors.surface,
      onSurface: LandingColors.textPrimary,
      outline: LandingColors.border,
    ),
    scaffoldBackgroundColor: LandingColors.bg,
    cardTheme: CardTheme(
      color: LandingColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: LandingColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LandingColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: LandingColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: LandingColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LandingColors.textPrimary,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: LandingColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 56, fontWeight: FontWeight.w700,
        color: LandingColors.textPrimary, height: 1.1, letterSpacing: -1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 40, fontWeight: FontWeight.w700,
        color: LandingColors.textPrimary, height: 1.15, letterSpacing: -0.8,
      ),
      headlineLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: LandingColors.textPrimary, height: 1.2, letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w600,
        color: LandingColors.textPrimary, height: 1.25,
      ),
      titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: LandingColors.textPrimary, height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w400,
        color: LandingColors.textMuted, height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: LandingColors.textMuted, height: 1.55,
      ),
      bodySmall: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: LandingColors.textFaint, height: 1.5,
      ),
    ),
  );
}
