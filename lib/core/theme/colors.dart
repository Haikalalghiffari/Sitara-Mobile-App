import 'package:flutter/material.dart';

/// Palet warna SITARA Health berbasis Material 3.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F766E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFF134E4A);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color primaryContainer = Color(0xFFE6F4F1);
  static const Color onPrimaryContainer = Color(0xFF042F2E);

  static const Color secondary = Color(0xFF0284C7);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEFF6FF);
  static const Color onSecondaryContainer = Color(0xFF082F49);
  static const Color secondaryBorder = Color(0xFFDBEAFE);

  static const Color tertiary = Color(0xFF0D9488);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFCCFBF1);
  static const Color onTertiaryContainer = Color(0xFF042F2E);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF052E16);

  static const Color warning = Color(0xFFD97706);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF451A03);

  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF450A0A);

  static const Color info = Color(0xFF0284C7);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFE0F2FE);
  static const Color onInfoContainer = Color(0xFF082F49);

  // ── Surface — Light ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFE8F0F5);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);
  static const Color inverseSurface = Color(0xFF0F172A);
  static const Color onInverseSurface = Color(0xFFF8FAFC);

  // ── Surface — Dark ───────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceContainerLowDark = Color(0xFF1E293B);
  static const Color surfaceContainerDark = Color(0xFF334155);
  static const Color surfaceContainerHighDark = Color(0xFF475569);
  static const Color surfaceContainerHighestDark = Color(0xFF64748B);

  // ── Text — Light ─────────────────────────────────────────────────────────
  static const Color onBackground = Color(0xFF0F172A);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Text — Dark ──────────────────────────────────────────────────────────
  static const Color onBackgroundDark = Color(0xFFF8FAFC);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);
  static const Color onSurfaceVariantDark = Color(0xFFCBD5E1);

  // ── Border & Divider ─────────────────────────────────────────────────────
  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);
  static const Color outlineDark = Color(0xFF64748B);
  static const Color outlineVariantDark = Color(0xFF475569);

  // ── Navigation ───────────────────────────────────────────────────────────
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF94A3B8);
  static const Color navIndicator = primary;
  static const Color navBadge = error;

  // ── Progress ─────────────────────────────────────────────────────────────
  static const Color progressFill = primary;
  static const Color progressTrack = Color(0xFFE2E8F0);

  // ── Gradient stops ───────────────────────────────────────────────────────
  static const Color gradientTop = Color(0xFFEFF6FF);
  static const Color gradientBottom = Color(0xFFF8FAFC);

  // ── Aliases (kompatibilitas kode existing) ───────────────────────────────
  static const Color healthPrimary = primary;
  static const Color healthPrimaryDark = primaryDark;
  static const Color healthPrimaryLight = primaryLight;
  static const Color loginGradientTop = gradientTop;
  static const Color loginGradientBottom = gradientBottom;
  static const Color loginSecondarySurface = secondaryContainer;
  static const Color loginSecondaryBorder = secondaryBorder;
  static const Color loginSecuritySurface = primaryContainer;
  static const Color textLabel = Color(0xFF334155);
  static const Color textMuted = textSecondary;
  static const Color textHint = textDisabled;
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color surfaceContainerLight = surfaceContainerLow;
  static const Color surfaceContainerHighLight = surfaceContainerHigh;
  static const Color outlineLight = outline;
  static const Color outlineVariantLight = outlineVariant;
  static const Color onSurfaceLight = onSurface;
  static const Color onSurfaceVariantLight = onSurfaceVariant;
  static const Color dashboardOvalBackground = surfaceContainer;

  // ── ColorScheme ──────────────────────────────────────────────────────────
  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: inverseSurface,
        onInverseSurface: onInverseSurface,
        inversePrimary: primaryLight,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainer: surfaceContainer,
        surfaceContainerLow: surfaceContainerLow,
      );

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF5EEAD4),
        onPrimary: Color(0xFF042F2E),
        primaryContainer: Color(0xFF115E59),
        onPrimaryContainer: Color(0xFFCCFBF1),
        secondary: Color(0xFF7DD3FC),
        onSecondary: Color(0xFF082F49),
        secondaryContainer: Color(0xFF0C4A6E),
        onSecondaryContainer: Color(0xFFE0F2FE),
        tertiary: Color(0xFF5EEAD4),
        onTertiary: Color(0xFF042F2E),
        tertiaryContainer: Color(0xFF115E59),
        onTertiaryContainer: Color(0xFFCCFBF1),
        error: Color(0xFFFCA5A5),
        onError: Color(0xFF450A0A),
        errorContainer: Color(0xFF991B1B),
        onErrorContainer: Color(0xFFFEE2E2),
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        onSurfaceVariant: onSurfaceVariantDark,
        outline: outlineDark,
        outlineVariant: outlineVariantDark,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFF8FAFC),
        onInverseSurface: Color(0xFF0F172A),
        inversePrimary: primary,
        surfaceContainerHighest: surfaceContainerHighestDark,
        surfaceContainerHigh: surfaceContainerHighDark,
        surfaceContainer: surfaceContainerDark,
        surfaceContainerLow: surfaceContainerLowDark,
      );
}
