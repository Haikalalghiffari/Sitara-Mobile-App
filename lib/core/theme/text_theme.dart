import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Tipografi SITARA berbasis Material 3 Type Scale.
abstract final class AppTextTheme {
  static const String fontFamily = 'Plus Jakarta Sans';

  static TextTheme light(ColorScheme colorScheme) => _build(
        brightness: Brightness.light,
        defaultColor: AppColors.onSurface,
        mutedColor: AppColors.onSurfaceVariant,
        accentColor: AppColors.primary,
      );

  static TextTheme dark(ColorScheme colorScheme) => _build(
        brightness: Brightness.dark,
        defaultColor: AppColors.onSurfaceDark,
        mutedColor: AppColors.onSurfaceVariantDark,
        accentColor: colorScheme.primary,
      );

  static TextTheme _build({
    required Brightness brightness,
    required Color defaultColor,
    required Color mutedColor,
    required Color accentColor,
  }) {
    final base = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return base.copyWith(
      // Display
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        letterSpacing: -0.25,
        color: defaultColor,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
        color: defaultColor,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
        color: defaultColor,
      ),

      // Headline
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: defaultColor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.29,
        color: defaultColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        color: defaultColor,
      ),

      // Title
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.27,
        color: defaultColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.15,
        color: defaultColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.1,
        color: defaultColor,
      ),

      // Body
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.5,
        color: defaultColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
        color: defaultColor,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.4,
        color: mutedColor,
      ),

      // Label
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: 0.1,
        color: defaultColor,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.33,
        letterSpacing: 0.5,
        color: defaultColor,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.45,
        letterSpacing: 0.5,
        color: mutedColor,
      ),
    );
  }

  /// Label section uppercase (contoh: "YOUR PROGRESS").
  static TextStyle sectionLabel(ColorScheme colorScheme) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.45,
        letterSpacing: 1.2,
        color: colorScheme.primary,
      );

  /// Angka countdown / timer monospace.
  static TextStyle timerDisplay({
    required Color color,
    double fontSize = 40,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 2,
        color: color,
      );
}
