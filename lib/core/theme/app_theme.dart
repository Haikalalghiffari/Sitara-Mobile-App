import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'radius.dart';
import 'spacing.dart';
import 'text_theme.dart';

/// Konfigurasi tema Material 3 SITARA Health.
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(
        colorScheme: AppColors.lightColorScheme,
        brightness: Brightness.light,
        scaffoldBackground: AppColors.background,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      );

  static ThemeData get dark => _buildTheme(
        colorScheme: AppColors.darkColorScheme,
        brightness: Brightness.dark,
        scaffoldBackground: AppColors.backgroundDark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      );

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackground,
    required SystemUiOverlayStyle systemOverlayStyle,
  }) {
    final textTheme = brightness == Brightness.light
        ? AppTextTheme.light(colorScheme)
        : AppTextTheme.dark(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      fontFamily: AppTextTheme.fontFamily,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: AppSpacing.appBarHeight,
        backgroundColor: scaffoldBackground,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: systemOverlayStyle,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppSpacing.iconLg,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Buttons ───────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: BorderSide(color: AppColors.secondaryBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.component),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Input ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: textTheme.titleSmall,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textDisabled,
        ),
      ),

      // ── Navigation ──────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.navActive : AppColors.navInactive,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.onPrimary : AppColors.navInactive,
            size: AppSpacing.iconLg,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
        elevation: 0,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxlRadius),
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.component),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 3,
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 2,
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet),
        showDragHandle: true,
      ),

      // ── List Tile ───────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.sm,
        minTileHeight: AppSpacing.minTouchTarget,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ── Progress ────────────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.progressFill,
        linearTrackColor: AppColors.progressTrack,
        circularTrackColor: AppColors.progressTrack,
      ),

      // ── Switch / Checkbox / Radio ───────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xsRadius),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),

      // ── Icon ────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSpacing.iconLg,
      ),
    );
  }
}
