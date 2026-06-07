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
    fontSize: 18, fontWeight: FontWeight.w600, height: 28 / 20,
  );
  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w400, height: 28 / 18,
  );
  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16,
  );
  static TextStyle get bodySm => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14,
  );
  static TextStyle get labelBold => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w600, height: 20 / 14,
  );
  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12,
  );
}