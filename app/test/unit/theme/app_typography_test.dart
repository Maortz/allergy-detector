import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_typography.dart';

void main() {
  group('AppTypography - Widget Test Style Values', () {
    testWidgets('Heading styles have correct font sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TypographyVerifier(),
          ),
        ),
      );

      final finder = find.byType(_TypographyVerifier);
      expect(finder, findsOneWidget);
      final widget = tester.widget<_TypographyVerifier>(finder);
      
      expect(widget.h1Size, 30);
      expect(widget.h2Size, 24);
      expect(widget.h3Size, 20);
    });

    testWidgets('Heading styles have correct font weights', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TypographyVerifier(),
          ),
        ),
      );

      final widget = tester.widget<_TypographyVerifier>(
        find.byType(_TypographyVerifier),
      );
      
      expect(widget.h1Weight, FontWeight.w700);
      expect(widget.h2Weight, FontWeight.w600);
      expect(widget.h3Weight, FontWeight.w600);
    });

    testWidgets('Body styles have correct font sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TypographyVerifier(),
          ),
        ),
      );

      final widget = tester.widget<_TypographyVerifier>(
        find.byType(_TypographyVerifier),
      );
      
      expect(widget.bodyLgSize, 18);
      expect(widget.bodyMdSize, 16);
      expect(widget.bodySmSize, 14);
    });

    testWidgets('bodySm has Inter Regular weight and 20/14 line-height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TypographyVerifier(),
          ),
        ),
      );

      final widget = tester.widget<_TypographyVerifier>(
        find.byType(_TypographyVerifier),
      );

      expect(widget.bodySmWeight, FontWeight.w400);
      expect(widget.bodySmHeight, 20 / 14);
    });

    testWidgets('Label styles have correct font sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TypographyVerifier(),
          ),
        ),
      );

      final widget = tester.widget<_TypographyVerifier>(
        find.byType(_TypographyVerifier),
      );
      
      expect(widget.labelBoldSize, 14);
      expect(widget.labelSmSize, 12);
    });

    testWidgets('All styles return TextStyle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TypographyVerifier(),
          ),
        ),
      );

      final widget = tester.widget<_TypographyVerifier>(
        find.byType(_TypographyVerifier),
      );
      
      expect(widget.h1Style, isA<TextStyle>());
      expect(widget.bodyMdStyle, isA<TextStyle>());
    });
  });
}

class _TypographyVerifier extends StatelessWidget {
  const _TypographyVerifier();

  double? get h1Size => AppTypography.h1.fontSize;
  double? get h2Size => AppTypography.h2.fontSize;
  double? get h3Size => AppTypography.h3.fontSize;
  double? get bodyLgSize => AppTypography.bodyLg.fontSize;
  double? get bodyMdSize => AppTypography.bodyMd.fontSize;
  double? get bodySmSize => AppTypography.bodySm.fontSize;
  double? get labelBoldSize => AppTypography.labelBold.fontSize;
  double? get labelSmSize => AppTypography.labelSm.fontSize;

  FontWeight? get h1Weight => AppTypography.h1.fontWeight;
  FontWeight? get h2Weight => AppTypography.h2.fontWeight;
  FontWeight? get h3Weight => AppTypography.h3.fontWeight;
  FontWeight? get bodySmWeight => AppTypography.bodySm.fontWeight;
  double? get bodySmHeight => AppTypography.bodySm.height;

  TextStyle? get h1Style => AppTypography.h1;
  TextStyle? get bodyMdStyle => AppTypography.bodyMd;

  @override
  Widget build(BuildContext context) => const SizedBox();
}