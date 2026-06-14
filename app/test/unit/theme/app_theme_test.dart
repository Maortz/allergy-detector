import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/theme/app_colors.dart';

void main() {
  // The theme builders pull in AppTypography (google_fonts). Running the
  // assertions inside `testWidgets` keeps any async font-load failure scoped to
  // the flutter test zone (mirroring app_typography_test) rather than failing a
  // plain `test()` "after it had already completed". These tests assert
  // colours/brightness, not glyphs.
  group('buildAppTheme (light)', () {
    testWidgets('uses Material 3 with a light color scheme', (tester) async {
      final theme = buildAppTheme();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    testWidgets('primary is the Medical Blue brand colour', (tester) async {
      expect(buildAppTheme().colorScheme.primary, AppColors.primary);
    });
  });

  group('buildDarkAppTheme', () {
    testWidgets('uses Material 3 with a dark color scheme', (tester) async {
      final theme = buildDarkAppTheme();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('primary is the lightened dark-mode brand colour',
        (tester) async {
      expect(buildDarkAppTheme().colorScheme.primary, AppDarkColors.primary);
    });

    testWidgets('scaffold background is the dark surface, not the light one',
        (tester) async {
      final theme = buildDarkAppTheme();
      expect(theme.scaffoldBackgroundColor, AppDarkColors.background);
      expect(theme.scaffoldBackgroundColor, isNot(AppColors.background));
    });
  });
}
