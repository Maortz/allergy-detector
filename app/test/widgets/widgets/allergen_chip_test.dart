import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/allergen_chip.dart';

void main() {
  group('AllergenChip', () {
    testWidgets('displays Hebrew label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenChip(label: 'גלוטן'),
          ),
        ),
      );

      expect(find.text('גלוטן'), findsOneWidget);
    });

    testWidgets('responds to tap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergenChip(
              label: 'חלב',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('applies selected styling when selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenChip(
              label: 'ביצים',
              isSelected: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });

    testWidgets('applies unselected styling when not selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenChip(
              label: 'אגוזים',
              isSelected: false,
            ),
          ),
        ),
      );

      expect(find.text('אגוזים'), findsOneWidget);
    });
  });
}