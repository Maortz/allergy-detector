import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_colors.dart';

void main() {
  group('AppColors - Design Tokens', () {
    test('primary color matches design spec', () {
      expect(AppColors.primary, const Color(0xFF00478d));
    });

    test('safeText color matches design spec', () {
      expect(AppColors.safeText, const Color(0xFF1E8E3E));
    });

    test('cautionText color matches design spec', () {
      expect(AppColors.cautionText, const Color(0xFFB05B00));
    });

    test('avoidText color matches design spec', () {
      expect(AppColors.avoidText, const Color(0xFFD93025));
    });

    test('safeBackground color matches design spec', () {
      expect(AppColors.safeBackground, const Color(0xFFE6F4EA));
    });

    test('cautionBackground color matches design spec', () {
      expect(AppColors.cautionBackground, const Color(0xFFFEF7E0));
    });

    test('avoidBackground color matches design spec', () {
      expect(AppColors.avoidBackground, const Color(0xFFFCE8E6));
    });

    test('scanFrame matches SS1/SS2 Medical Blue spec', () {
      expect(AppColors.scanFrame, const Color(0xFF1A8CF8));
    });
  });

  group('AppColors - Additional Colors', () {
    test('primaryContainer exists and is valid', () {
      expect(AppColors.primaryContainer, const Color(0xFF005eb8));
    });

    test('onPrimary exists and is valid', () {
      expect(AppColors.onPrimary, const Color(0xFFFFFFFF));
    });

    test('secondary exists and is valid', () {
      expect(AppColors.secondary, const Color(0xFF006B5B));
    });

    test('background exists and is valid', () {
      expect(AppColors.background, const Color(0xFFF8F9FA));
    });

    test('error exists and is valid', () {
      expect(AppColors.error, const Color(0xFFBA1A1A));
    });
  });
}