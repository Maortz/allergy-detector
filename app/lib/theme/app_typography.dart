import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get h1 => GoogleFonts.publicSans(
    fontSize: 30, fontWeight: FontWeight.w700, height: 38 / 30,
  );
  static TextStyle get h2 => GoogleFonts.publicSans(
    fontSize: 24, fontWeight: FontWeight.w600, height: 32 / 24,
  );
  static TextStyle get h3 => GoogleFonts.publicSans(
    fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20,
  );
  static TextStyle get titleMd => GoogleFonts.publicSans(
    fontSize: 18, fontWeight: FontWeight.w600, height: 28 / 18,
  );
  // Bold 18 pt Public Sans heading (e.g. add-product step-4 section title) —
  // distinct from [titleMd]'s SemiBold weight. See add-product-step-4 §4.1.
  static TextStyle get titleStrong => GoogleFonts.publicSans(
    fontSize: 18, fontWeight: FontWeight.w700, height: 24 / 18,
  );
  // SemiBold 22 pt Public Sans heading — onboarding welcome headline per
  // onboarding-allergen-selection §4.2. Sits between [h2] (24) and [h3] (20);
  // distinct from [titleMd]'s 18 pt. Issue #237.
  static TextStyle get titleLg => GoogleFonts.publicSans(
    fontSize: 22, fontWeight: FontWeight.w600, height: 30 / 22,
  );
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w400, height: 28 / 18,
  );
  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16,
  );
  // 16 pt Inter Medium — e.g. the onboarding brand-header "SafeBite" text
  // (onboarding-allergen-selection §4.1). Distinct from [bodyMd] (Regular w400).
  static TextStyle get labelMd => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w500, height: 24 / 16,
  );
  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14,
  );
  static TextStyle get labelBold => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, height: 20 / 14,
  );
  /// [bodyMd] at semibold weight — e.g. empty/error state titles (StateView).
  static TextStyle get bodyMdBold => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600, height: 24 / 16,
  );
  // 13 pt Inter Regular body — sub-instruction copy too small for [bodySm]
  // (14 pt). See add-product-step-4 §4.1.
  static TextStyle get bodyXs => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400, height: 18 / 13,
  );
  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12,
  );
  // 12 pt Inter weight variants of [labelSm] used by the step-progress footer
  // (percent label is SemiBold, "שלב X מתוך Y" is Regular).
  static TextStyle get labelSmBold => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w600, height: 16 / 12,
  );
  static TextStyle get labelSmRegular => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12,
  );
  // 22 pt Inter SemiBold — initial-letter brand-logo fallback chip.
  // See admin-trusted-brands §7.4 / TB7 (the only 22 pt size in the system).
  static TextStyle get brandInitial => GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w600, height: 28 / 22,
  );
}