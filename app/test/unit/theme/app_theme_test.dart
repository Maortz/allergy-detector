import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_spacing.dart';

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

  group('theme spacing uses AppSpacing tokens (issue #183)', () {
    EdgeInsetsGeometry? buttonPadding(ButtonStyle? style) =>
        style?.padding?.resolve(<WidgetState>{});

    for (final entry in {
      'light': buildAppTheme,
      'dark': buildDarkAppTheme,
    }.entries) {
      final name = entry.key;
      final build = entry.value;

      testWidgets('$name elevated button padding is lg/md tokens',
          (tester) async {
        expect(
          buttonPadding(build().elevatedButtonTheme.style),
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        );
      });

      testWidgets('$name outlined button padding is lg/md tokens',
          (tester) async {
        expect(
          buttonPadding(build().outlinedButtonTheme.style),
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        );
      });

      testWidgets('$name input contentPadding is md/md tokens', (tester) async {
        expect(
          build().inputDecorationTheme.contentPadding,
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        );
      });
    }
  });
}
