import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00478d);
  static const Color primaryContainer = Color(0xFF005eb8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFC8DAFF);
  static const Color primaryFixed = Color(0xFFD6E3FF);
  static const Color primaryFixedDim = Color(0xFFA9C7FF);

  /// Light azure tint used for the admin role chip background and active-row
  /// highlight (nav-drawer-admin §4.1/§4.3, DA2). Lighter than the M3
  /// [primaryFixed] swatch.
  static const Color primaryTint = Color(0xFFEBF4FF);

  /// Border companion to [primaryTint] (nav-drawer-admin §4.1, DA2).
  static const Color primaryTintBorder = Color(0xFFBFDBFE);
  static const Color onPrimaryFixed = Color(0xFF001B3D);
  static const Color onPrimaryFixedVariant = Color(0xFF00468C);

  static const Color secondary = Color(0xFF006B5B);
  static const Color secondaryContainer = Color(0xFF78F8DD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF007261);
  static const Color secondaryFixed = Color(0xFF78F8DD);
  static const Color secondaryFixedDim = Color(0xFF59DBC1);
  static const Color onSecondaryFixed = Color(0xFF00201A);
  static const Color onSecondaryFixedVariant = Color(0xFF005144);

  static const Color tertiary = Color(0xFF404850);
  static const Color tertiaryContainer = Color(0xFF576068);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFD1DAE4);
  static const Color tertiaryFixed = Color(0xFFDBE4ED);
  static const Color tertiaryFixedDim = Color(0xFFBFC8D0);
  static const Color onTertiaryFixed = Color(0xFF141D23);
  static const Color onTertiaryFixedVariant = Color(0xFF3F484F);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFD9DADB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHigh_ = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceVariant = Color(0xFFE1E3E4);
  static const Color surfaceTint = Color(0xFF005DB6);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF424752);

  static const Color outline = Color(0xFF727783);
  static const Color outlineVariant = Color(0xFFC2C6D4);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  /// Subtle salmon/rose pair for *destructive* affordances (e.g. logout),
  /// kept distinct from the M3 [errorContainer] error semantics used for
  /// form validation. Matches nav-drawer-admin.md §4.4.
  static const Color destructiveSubtle = Color(0xFFFECDD3);
  static const Color onDestructiveSubtle = Color(0xFF9F1239);

  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);
  static const Color inversePrimary = Color(0xFFA9C7FF);

  static const Color safeBackground = Color(0xFFE6F4EA);
  static const Color safeText = Color(0xFF1E8E3E);
  static const Color cautionBackground = Color(0xFFFEF7E0);
  static const Color cautionText = Color(0xFFB05B00);
  static const Color avoidBackground = Color(0xFFFCE8E6);
  static const Color avoidText = Color(0xFFD93025);
  // Status cards/badges use the *Background/*Text tint pair above; the
  // product-details Avoid banner uses the solid pair below (canonical avoid red).
  static const Color avoid = Color(0xFFDC2626);
  static const Color onAvoid = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF0D9488);
  static const Color onSuccess = Color(0xFFFFFFFF);
}
