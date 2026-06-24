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

  /// Translucent white used for frosted overlay pills layered over imagery
  /// (review-next-item §4.4 alert badge). Pure-white base at 90% opacity.
  static const Color frostedSurface = Color(0xE6FFFFFF);

  /// Semi-transparent black scrim for the close-button circular overlay
  /// (report-issue §4.6, feedback_screen.dart). 40% opacity black over imagery.
  static const Color closeButtonOverlay = Color(0x66000000);

  /// Universal subtle hairline border used for cards, buttons, and allergen chips.
  /// Replaces separate slate-100 and gray-200 definitions to simplify the theme layer.
  /// Matches Tailwind `gray-200` for reliable visibility against pure white surfaces.
  static const Color borderSubtle = Color(0xFFE5E7EB);

  /// Muted gray for decorative/empty-state icons (lighter than [outline],
  /// which is reserved for borders/dividers). Per Tier-2 state specs.
  static const Color iconMuted = Color(0xFF9CA3AF);

  /// Slate-600 gray for subtle accent icons (community-hub.md §4.6 card 2).
  static const Color slate600 = Color(0xFF475569);

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

  /// Caution keyword highlight in ingredient text (product-details §7.8).
  /// Darker than [cautionText] for inline bold highlights.
  static const Color cautionHighlight = Color(0xFFCA8A04);

  // Allergen chip palettes (product-details glossary #allergen-chip).
  // Display variant (blue tint) — non-user-monitored allergens.
  static const Color chipDisplayBg = Color(0xFFEBF4FF);
  static const Color chipDisplayBorder = Color(0xFFBFDBFE);
  // chipDisplayFg uses [primary].

  // Detected variant (red) — allergen the user monitors + product contains.
  static const Color chipDetectedBg = Color(0xFFFEE2E2);
  static const Color chipDetectedBorder = Color(0xFFDC2626);
  static const Color chipDetectedFg = Color(0xFF991B1B);

  // Caution variant (amber) — allergen the user monitors + product may-contain.
  static const Color chipCautionBg = Color(0xFFFEF9C3);
  static const Color chipCautionBorder = Color(0xFFCA8A04);
  static const Color chipCautionFg = Color(0xFFA16207);
  static const Color avoidBackground = Color(0xFFFCE8E6);
  static const Color avoidText = Color(0xFFD93025);

  /// Scan-frame corners and laser line — Medical Blue (spec SS1/SS2).
  static const Color scanFrame = Color(0xFF1A8CF8);

  /// Dark slate backdrop for an inactive / unavailable camera viewport
  /// (add-product-step-1-barcode.md §7.8 #8, S1-14). Darker and cooler than
  /// the M3 [inverseSurface]; pairs with [iconMuted] for the placeholder icon.
  static const Color cameraSurfaceUnavailable = Color(0xFF1F2937);

  // Status cards/badges use the *Background/*Text tint pair above; the
  // product-details Avoid banner uses the solid pair below (canonical avoid red).
  static const Color avoid = Color(0xFFDC2626);
  static const Color onAvoid = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF0D9488);
  static const Color onSuccess = Color(0xFFFFFFFF);

  // Warning (offline / stale-data banner): solid accent + light container tint.
  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFF3E0);

}

/// App-specific semantic colour tokens as a [ThemeExtension].
///
/// Carries every colour that is NOT a standard M3 [ColorScheme] role —
/// status pairs (safe/caution/avoid), chip variants, scan-frame, admin tints, etc.
/// Widgets access these via [BuildContext.colors] (see the extension below).
///
/// Two factory constructors — [AppColorsExt.light] and [AppColorsExt.dark] —
/// provide the Clinical Clarity RTL palettes for [buildAppTheme] and
/// [buildDarkAppTheme] respectively.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  const AppColorsExt({
    required this.borderSubtle,
    required this.iconMuted,
    required this.slate600,
    required this.primaryTint,
    required this.primaryTintBorder,
    required this.frostedSurface,
    required this.closeButtonOverlay,
    required this.cameraSurfaceUnavailable,
    required this.scanFrame,
    required this.safeBackground,
    required this.safeText,
    required this.cautionBackground,
    required this.cautionText,
    required this.cautionHighlight,
    required this.avoidBackground,
    required this.avoidText,
    required this.avoid,
    required this.onAvoid,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.warningContainer,
    required this.chipDisplayBg,
    required this.chipDisplayBorder,
    required this.chipDetectedBg,
    required this.chipDetectedBorder,
    required this.chipDetectedFg,
    required this.chipCautionBg,
    required this.chipCautionBorder,
    required this.chipCautionFg,
    required this.destructiveSubtle,
    required this.onDestructiveSubtle,
  });

  final Color borderSubtle;
  final Color iconMuted;
  final Color slate600;
  final Color primaryTint;
  final Color primaryTintBorder;
  final Color frostedSurface;
  final Color closeButtonOverlay;
  final Color cameraSurfaceUnavailable;
  final Color scanFrame;
  final Color safeBackground;
  final Color safeText;
  final Color cautionBackground;
  final Color cautionText;
  final Color cautionHighlight;
  final Color avoidBackground;
  final Color avoidText;
  final Color avoid;
  final Color onAvoid;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color warningContainer;
  final Color chipDisplayBg;
  final Color chipDisplayBorder;
  final Color chipDetectedBg;
  final Color chipDetectedBorder;
  final Color chipDetectedFg;
  final Color chipCautionBg;
  final Color chipCautionBorder;
  final Color chipCautionFg;
  final Color destructiveSubtle;
  final Color onDestructiveSubtle;

  static const AppColorsExt _light = AppColorsExt(
    borderSubtle: Color(0xFFE5E7EB),
    iconMuted: Color(0xFF9CA3AF),
    slate600: Color(0xFF475569),
    primaryTint: Color(0xFFEBF4FF),
    primaryTintBorder: Color(0xFFBFDBFE),
    frostedSurface: Color(0xE6FFFFFF),
    closeButtonOverlay: Color(0x66000000),
    cameraSurfaceUnavailable: Color(0xFF1F2937),
    scanFrame: Color(0xFF1A8CF8),
    safeBackground: Color(0xFFE6F4EA),
    safeText: Color(0xFF1E8E3E),
    cautionBackground: Color(0xFFFEF7E0),
    cautionText: Color(0xFFB05B00),
    cautionHighlight: Color(0xFFCA8A04),
    avoidBackground: Color(0xFFFCE8E6),
    avoidText: Color(0xFFD93025),
    avoid: Color(0xFFDC2626),
    onAvoid: Color(0xFFFFFFFF),
    success: Color(0xFF0D9488),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFFF9800),
    warningContainer: Color(0xFFFFF3E0),
    chipDisplayBg: Color(0xFFEBF4FF),
    chipDisplayBorder: Color(0xFFBFDBFE),
    chipDetectedBg: Color(0xFFFEE2E2),
    chipDetectedBorder: Color(0xFFDC2626),
    chipDetectedFg: Color(0xFF991B1B),
    chipCautionBg: Color(0xFFFEF9C3),
    chipCautionBorder: Color(0xFFCA8A04),
    chipCautionFg: Color(0xFFA16207),
    destructiveSubtle: Color(0xFFFECDD3),
    onDestructiveSubtle: Color(0xFF9F1239),
  );

  static const AppColorsExt _dark = AppColorsExt(
    borderSubtle: Color(0xFF374151),
    iconMuted: Color(0xFF6B7280),
    slate600: Color(0xFF94A3B8),
    primaryTint: Color(0xFF1E3A5F),
    primaryTintBorder: Color(0xFF2563EB),
    frostedSurface: Color(0xE61F2937),
    closeButtonOverlay: Color(0x66FFFFFF),
    cameraSurfaceUnavailable: Color(0xFF111827),
    scanFrame: Color(0xFF3B9EFF),
    safeBackground: Color(0xFF1B3A24),
    safeText: Color(0xFF4ADE80),
    cautionBackground: Color(0xFF3D2E00),
    cautionText: Color(0xFFFBB740),
    cautionHighlight: Color(0xFFFCD34D),
    avoidBackground: Color(0xFF3B0F0A),
    avoidText: Color(0xFFFF6B6B),
    avoid: Color(0xFFEF4444),
    onAvoid: Color(0xFFFFFFFF),
    success: Color(0xFF2DD4BF),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF3E2000),
    chipDisplayBg: Color(0xFF1E3A5F),
    chipDisplayBorder: Color(0xFF2563EB),
    chipDetectedBg: Color(0xFF3B0F0A),
    chipDetectedBorder: Color(0xFFEF4444),
    chipDetectedFg: Color(0xFFFF6B6B),
    chipCautionBg: Color(0xFF3D2E00),
    chipCautionBorder: Color(0xFFFFB74D),
    chipCautionFg: Color(0xFFFBB740),
    destructiveSubtle: Color(0xFF3B0F0A),
    onDestructiveSubtle: Color(0xFFFF6B6B),
  );

  static AppColorsExt light() => _light;
  static AppColorsExt dark() => _dark;

  @override
  AppColorsExt copyWith({
    Color? borderSubtle,
    Color? iconMuted,
    Color? slate600,
    Color? primaryTint,
    Color? primaryTintBorder,
    Color? frostedSurface,
    Color? closeButtonOverlay,
    Color? cameraSurfaceUnavailable,
    Color? scanFrame,
    Color? safeBackground,
    Color? safeText,
    Color? cautionBackground,
    Color? cautionText,
    Color? cautionHighlight,
    Color? avoidBackground,
    Color? avoidText,
    Color? avoid,
    Color? onAvoid,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? warningContainer,
    Color? chipDisplayBg,
    Color? chipDisplayBorder,
    Color? chipDetectedBg,
    Color? chipDetectedBorder,
    Color? chipDetectedFg,
    Color? chipCautionBg,
    Color? chipCautionBorder,
    Color? chipCautionFg,
    Color? destructiveSubtle,
    Color? onDestructiveSubtle,
  }) {
    return AppColorsExt(
      borderSubtle: borderSubtle ?? this.borderSubtle,
      iconMuted: iconMuted ?? this.iconMuted,
      slate600: slate600 ?? this.slate600,
      primaryTint: primaryTint ?? this.primaryTint,
      primaryTintBorder: primaryTintBorder ?? this.primaryTintBorder,
      frostedSurface: frostedSurface ?? this.frostedSurface,
      closeButtonOverlay: closeButtonOverlay ?? this.closeButtonOverlay,
      cameraSurfaceUnavailable:
          cameraSurfaceUnavailable ?? this.cameraSurfaceUnavailable,
      scanFrame: scanFrame ?? this.scanFrame,
      safeBackground: safeBackground ?? this.safeBackground,
      safeText: safeText ?? this.safeText,
      cautionBackground: cautionBackground ?? this.cautionBackground,
      cautionText: cautionText ?? this.cautionText,
      cautionHighlight: cautionHighlight ?? this.cautionHighlight,
      avoidBackground: avoidBackground ?? this.avoidBackground,
      avoidText: avoidText ?? this.avoidText,
      avoid: avoid ?? this.avoid,
      onAvoid: onAvoid ?? this.onAvoid,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      chipDisplayBg: chipDisplayBg ?? this.chipDisplayBg,
      chipDisplayBorder: chipDisplayBorder ?? this.chipDisplayBorder,
      chipDetectedBg: chipDetectedBg ?? this.chipDetectedBg,
      chipDetectedBorder: chipDetectedBorder ?? this.chipDetectedBorder,
      chipDetectedFg: chipDetectedFg ?? this.chipDetectedFg,
      chipCautionBg: chipCautionBg ?? this.chipCautionBg,
      chipCautionBorder: chipCautionBorder ?? this.chipCautionBorder,
      chipCautionFg: chipCautionFg ?? this.chipCautionFg,
      destructiveSubtle: destructiveSubtle ?? this.destructiveSubtle,
      onDestructiveSubtle: onDestructiveSubtle ?? this.onDestructiveSubtle,
    );
  }

  @override
  AppColorsExt lerp(AppColorsExt? other, double t) {
    if (other == null) return this;
    return AppColorsExt(
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      slate600: Color.lerp(slate600, other.slate600, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
      primaryTintBorder:
          Color.lerp(primaryTintBorder, other.primaryTintBorder, t)!,
      frostedSurface: Color.lerp(frostedSurface, other.frostedSurface, t)!,
      closeButtonOverlay:
          Color.lerp(closeButtonOverlay, other.closeButtonOverlay, t)!,
      cameraSurfaceUnavailable: Color.lerp(
          cameraSurfaceUnavailable, other.cameraSurfaceUnavailable, t)!,
      scanFrame: Color.lerp(scanFrame, other.scanFrame, t)!,
      safeBackground: Color.lerp(safeBackground, other.safeBackground, t)!,
      safeText: Color.lerp(safeText, other.safeText, t)!,
      cautionBackground:
          Color.lerp(cautionBackground, other.cautionBackground, t)!,
      cautionText: Color.lerp(cautionText, other.cautionText, t)!,
      cautionHighlight:
          Color.lerp(cautionHighlight, other.cautionHighlight, t)!,
      avoidBackground: Color.lerp(avoidBackground, other.avoidBackground, t)!,
      avoidText: Color.lerp(avoidText, other.avoidText, t)!,
      avoid: Color.lerp(avoid, other.avoid, t)!,
      onAvoid: Color.lerp(onAvoid, other.onAvoid, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      chipDisplayBg: Color.lerp(chipDisplayBg, other.chipDisplayBg, t)!,
      chipDisplayBorder:
          Color.lerp(chipDisplayBorder, other.chipDisplayBorder, t)!,
      chipDetectedBg: Color.lerp(chipDetectedBg, other.chipDetectedBg, t)!,
      chipDetectedBorder:
          Color.lerp(chipDetectedBorder, other.chipDetectedBorder, t)!,
      chipDetectedFg: Color.lerp(chipDetectedFg, other.chipDetectedFg, t)!,
      chipCautionBg: Color.lerp(chipCautionBg, other.chipCautionBg, t)!,
      chipCautionBorder:
          Color.lerp(chipCautionBorder, other.chipCautionBorder, t)!,
      chipCautionFg: Color.lerp(chipCautionFg, other.chipCautionFg, t)!,
      destructiveSubtle:
          Color.lerp(destructiveSubtle, other.destructiveSubtle, t)!,
      onDestructiveSubtle:
          Color.lerp(onDestructiveSubtle, other.onDestructiveSubtle, t)!,
    );
  }
}

/// Convenience accessor — `context.colors.safeBackground` instead of
/// `Theme.of(context).extension<AppColorsExt>()!.safeBackground`.
extension AppColorsContext on BuildContext {
  AppColorsExt get colors => Theme.of(this).extension<AppColorsExt>()!;
}

/// Dark-mode palette for the **Clinical Clarity RTL** design system (issue #168).
///
/// These tokens mirror the role names in [AppColors] but are tuned for dark
/// surfaces: the Medical Blue brand is lightened for contrast against near-black
/// backgrounds, and the semantic status pairs (safe/caution/avoid) are darkened
/// tints — not inverted — so they stay legible without losing their hue.
///
/// They feed [buildDarkAppTheme] only. Widgets that reference the light
/// [AppColors] constants directly are unaffected; full per-widget theming is out
/// of scope for #168 (its acceptance criteria cover the theme wiring + the
/// appearance picker, not migrating every widget off the constants).
class AppDarkColors {
  AppDarkColors._();

  // Brand — lightened Medical Blue for contrast on dark surfaces.
  static const Color primary = Color(0xFFA9C7FF);
  static const Color onPrimary = Color(0xFF002F65);
  static const Color primaryContainer = Color(0xFF00468C);
  static const Color onPrimaryContainer = Color(0xFFD6E3FF);

  static const Color secondary = Color(0xFF59DBC1);
  static const Color onSecondary = Color(0xFF00382E);
  static const Color secondaryContainer = Color(0xFF005144);
  static const Color onSecondaryContainer = Color(0xFF78F8DD);

  static const Color tertiary = Color(0xFFBFC8D0);
  static const Color onTertiary = Color(0xFF293138);
  static const Color tertiaryContainer = Color(0xFF3F484F);
  static const Color onTertiaryContainer = Color(0xFFDBE4ED);

  // Surfaces — graded near-black greys (M3 dark surface roles).
  static const Color background = Color(0xFF111416);
  static const Color surface = Color(0xFF111416);
  static const Color surfaceContainerLowest = Color(0xFF0C0F11);
  static const Color surfaceContainerLow = Color(0xFF191C1E);
  static const Color surfaceContainer = Color(0xFF1D2022);
  static const Color surfaceContainerHigh = Color(0xFF272A2D);
  static const Color surfaceContainerHighest = Color(0xFF323538);
  static const Color onSurface = Color(0xFFE1E3E4);
  static const Color onSurfaceVariant = Color(0xFFC2C6D4);

  static const Color outline = Color(0xFF8C9199);
  static const Color outlineVariant = Color(0xFF42474E);

  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color inverseSurface = Color(0xFFE1E3E4);
  static const Color inverseOnSurface = Color(0xFF2E3132);
  static const Color inversePrimary = Color(0xFF00478D);

  // Semantic status — darkened tints, hue preserved (not inverted) so the
  // safe/caution/avoid meaning still reads at a glance on dark backgrounds.
  static const Color safeBackground = Color(0xFF103A1E);
  static const Color safeText = Color(0xFF6FD68A);
  static const Color cautionBackground = Color(0xFF3D2E05);
  static const Color cautionText = Color(0xFFF5C04E);
  static const Color avoidBackground = Color(0xFF44181A);
  static const Color avoidText = Color(0xFFF2897F);
}
