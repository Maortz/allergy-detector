import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  group('AppColorsExt - factories', () {
    test('light() returns a non-null instance with expected sample values', () {
      final light = AppColorsExt.light();
      expect(light, isNotNull);
      expect(light.safeBackground, const Color(0xFFE6F4EA));
      expect(light.borderSubtle, const Color(0xFFE5E7EB));
      expect(light.scanFrame, const Color(0xFF1A8CF8));
    });

    test('dark() returns a non-null instance with expected sample values', () {
      final dark = AppColorsExt.dark();
      expect(dark, isNotNull);
      expect(dark.safeBackground, const Color(0xFF1B3A24));
      expect(dark.borderSubtle, const Color(0xFF374151));
    });

    test('light() and dark() differ for theme-aware tokens', () {
      expect(
        AppColorsExt.light().safeBackground,
        isNot(AppColorsExt.dark().safeBackground),
      );
    });
  });

  group('AppColorsExt.copyWith', () {
    test('overrides only the named field, leaving others unchanged', () {
      final base = AppColorsExt.light();
      const override = Color(0xFF123456);
      final copy = base.copyWith(safeBackground: override);

      expect(copy.safeBackground, override);
      // Untouched fields are preserved.
      expect(copy.borderSubtle, base.borderSubtle);
      expect(copy.avoid, base.avoid);
      expect(copy.chipDetectedFg, base.chipDetectedFg);
      expect(copy.warningContainer, base.warningContainer);
    });

    test('with no arguments returns an equivalent instance', () {
      final base = AppColorsExt.light();
      final copy = base.copyWith();

      expect(copy.safeBackground, base.safeBackground);
      expect(copy.borderSubtle, base.borderSubtle);
      expect(copy.onDestructiveSubtle, base.onDestructiveSubtle);
    });
  });

  group('AppColorsExt.lerp', () {
    test('t=0.0 yields the source values', () {
      final a = AppColorsExt.light();
      final b = AppColorsExt.dark();
      final result = a.lerp(b, 0.0);

      expect(result.safeBackground, a.safeBackground);
      expect(result.borderSubtle, a.borderSubtle);
    });

    test('t=1.0 yields the target values', () {
      final a = AppColorsExt.light();
      final b = AppColorsExt.dark();
      final result = a.lerp(b, 1.0);

      expect(result.safeBackground, b.safeBackground);
      expect(result.borderSubtle, b.borderSubtle);
    });

    test('midpoint interpolates between source and target', () {
      final a = AppColorsExt.light();
      final b = AppColorsExt.dark();
      final result = a.lerp(b, 0.5);

      expect(
        result.safeBackground,
        Color.lerp(a.safeBackground, b.safeBackground, 0.5),
      );
      // Midpoint is distinct from both endpoints for a token that changes.
      expect(result.safeBackground, isNot(a.safeBackground));
      expect(result.safeBackground, isNot(b.safeBackground));
    });

    test('null other returns this unchanged', () {
      final a = AppColorsExt.light();
      final result = a.lerp(null, 0.5);

      expect(result.safeBackground, a.safeBackground);
      expect(result.borderSubtle, a.borderSubtle);
    });
  });

  group('AppColorsContext.colors', () {
    testWidgets('returns the extension registered by buildAppTheme()',
        (tester) async {
      late AppColorsExt captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) {
              captured = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.safeBackground, AppColorsExt.light().safeBackground);
      expect(captured.borderSubtle, AppColorsExt.light().borderSubtle);
    });

    testWidgets('falls back to light() when no extension is registered',
        (tester) async {
      late AppColorsExt captured;
      await tester.pumpWidget(
        MaterialApp(
          // A bare ThemeData with no AppColorsExt registered.
          theme: ThemeData(useMaterial3: true),
          home: Builder(
            builder: (context) {
              captured = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.safeBackground, AppColorsExt.light().safeBackground);
    });
  });
}
