import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHigh,
      primaryFixed: AppColors.primaryFixed,
      onPrimaryFixed: AppColors.onPrimaryFixed,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary: AppColors.inversePrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      displayLarge: AppTypography.h1.copyWith(color: AppColors.onSurface),
      displayMedium: AppTypography.h2.copyWith(color: AppColors.onSurface),
      displaySmall: AppTypography.h3.copyWith(color: AppColors.onSurface),
      bodyLarge: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
      bodyMedium: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      labelLarge: AppTypography.labelBold.copyWith(color: AppColors.onSurface),
      labelSmall: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceContainerLowest,
      foregroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.h3,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.outlineVariant),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.labelBold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryFixed,
      labelStyle: AppTypography.labelSm.copyWith(color: AppColors.onPrimaryFixed),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainerLowest,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    extensions: [AppColorsExt.light()],
  );
}

/// Dark counterpart to [buildAppTheme] (issue #168). Mirrors the light theme's
/// structure with the [AppDarkColors] palette so the OS / user dark preference
/// produces a brand-consistent Clinical Clarity RTL dark mode. No hex literals
/// live here — every colour comes from a named token.
ThemeData buildDarkAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppDarkColors.primary,
      onPrimary: AppDarkColors.onPrimary,
      primaryContainer: AppDarkColors.primaryContainer,
      onPrimaryContainer: AppDarkColors.onPrimaryContainer,
      secondary: AppDarkColors.secondary,
      onSecondary: AppDarkColors.onSecondary,
      secondaryContainer: AppDarkColors.secondaryContainer,
      onSecondaryContainer: AppDarkColors.onSecondaryContainer,
      tertiary: AppDarkColors.tertiary,
      onTertiary: AppDarkColors.onTertiary,
      tertiaryContainer: AppDarkColors.tertiaryContainer,
      onTertiaryContainer: AppDarkColors.onTertiaryContainer,
      error: AppDarkColors.error,
      onError: AppDarkColors.onError,
      errorContainer: AppDarkColors.errorContainer,
      onErrorContainer: AppDarkColors.onErrorContainer,
      surface: AppDarkColors.surface,
      onSurface: AppDarkColors.onSurface,
      onSurfaceVariant: AppDarkColors.onSurfaceVariant,
      surfaceContainerLowest: AppDarkColors.surfaceContainerLowest,
      surfaceContainerLow: AppDarkColors.surfaceContainerLow,
      surfaceContainer: AppDarkColors.surfaceContainer,
      surfaceContainerHigh: AppDarkColors.surfaceContainerHigh,
      surfaceContainerHighest: AppDarkColors.surfaceContainerHighest,
      // M3 "fixed" accent colours are intentionally constant across brightness,
      // so the dark scheme reuses the light AppColors values (AppDarkColors has
      // no fixed-colour tokens by design).
      primaryFixed: AppColors.primaryFixed,
      onPrimaryFixed: AppColors.onPrimaryFixed,
      outline: AppDarkColors.outline,
      outlineVariant: AppDarkColors.outlineVariant,
      inverseSurface: AppDarkColors.inverseSurface,
      onInverseSurface: AppDarkColors.inverseOnSurface,
      inversePrimary: AppDarkColors.inversePrimary,
    ),
    scaffoldBackgroundColor: AppDarkColors.background,
    textTheme: TextTheme(
      displayLarge: AppTypography.h1.copyWith(color: AppDarkColors.onSurface),
      displayMedium: AppTypography.h2.copyWith(color: AppDarkColors.onSurface),
      displaySmall: AppTypography.h3.copyWith(color: AppDarkColors.onSurface),
      bodyLarge: AppTypography.bodyLg.copyWith(color: AppDarkColors.onSurface),
      bodyMedium: AppTypography.bodyMd.copyWith(color: AppDarkColors.onSurface),
      labelLarge:
          AppTypography.labelBold.copyWith(color: AppDarkColors.onSurface),
      labelSmall:
          AppTypography.labelSm.copyWith(color: AppDarkColors.onSurfaceVariant),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppDarkColors.surfaceContainerLow,
      foregroundColor: AppDarkColors.primary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDarkColors.primaryContainer,
        foregroundColor: AppDarkColors.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.h3,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDarkColors.primary,
        side: BorderSide(color: AppDarkColors.outlineVariant),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.labelBold,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDarkColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppDarkColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppDarkColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppDarkColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppDarkColors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppDarkColors.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppDarkColors.surfaceContainerHigh,
      labelStyle:
          AppTypography.labelSm.copyWith(color: AppDarkColors.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppDarkColors.surfaceContainerLow,
      selectedItemColor: AppDarkColors.primary,
      unselectedItemColor: AppDarkColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    extensions: [AppColorsExt.dark()],
  );
}