import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/allergen_card.dart';
import 'package:app/models/allergen.dart';

void main() {
  group('AllergenCard', () {
    testWidgets('displays Hebrew allergen name', (tester) async {
      const allergen = Allergen(id: 'milk', nameHe: 'חלב');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenCard(allergen: allergen),
          ),
        ),
      );

      expect(find.text('חלב'), findsOneWidget);
    });

    testWidgets('shows selected state with border', (tester) async {
      const allergen = Allergen(id: 'egg', nameHe: 'ביצים');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenCard(
              allergen: allergen,
              isSelected: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('responds to tap callback', (tester) async {
      const allergen = Allergen(id: 'soy', nameHe: 'סויה');
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllergenCard(
              allergen: allergen,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('displays water_drop icon for milk allergen', (tester) async {
      const allergen = Allergen(id: 'milk', nameHe: 'חלב');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenCard(allergen: allergen),
          ),
        ),
      );

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('displays egg icon for egg allergen', (tester) async {
      const allergen = Allergen(id: 'egg', nameHe: 'ביצים');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenCard(allergen: allergen),
          ),
        ),
      );

      expect(find.byIcon(Icons.egg), findsOneWidget);
    });

    testWidgets('displays grass icon for wheat/gluten allergen', (tester) async {
      const allergen = Allergen(id: 'wheat', nameHe: 'חיטה');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenCard(allergen: allergen),
          ),
        ),
      );

      expect(find.byIcon(Icons.grass), findsOneWidget);
    });

    testWidgets('displays spa icon for nut allergen', (tester) async {
      const allergen = Allergen(id: 'nut', nameHe: 'אגוזים');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllergenCard(allergen: allergen),
          ),
        ),
      );

      expect(find.byIcon(Icons.spa), findsOneWidget);
    });
  });
}