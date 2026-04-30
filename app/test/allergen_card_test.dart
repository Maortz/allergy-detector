import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/allergen_card.dart';
import 'package:app/models/allergen.dart';

void main() {
  testWidgets('AllergenCard renders allergen name', (tester) async {
    const allergen = Allergen(id: 'milk', nameHe: 'חלב');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AllergenCard(allergen: allergen),
        ),
      ),
    );

    expect(find.text('חלב'), findsOneWidget);
  });

  testWidgets('AllergenCard shows selected state', (tester) async {
    const allergen = Allergen(id: 'egg', nameHe: 'ביצה');

    await tester.pumpWidget(
      MaterialApp(
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
    expect(decoration.border?.top.color, equals(const Color(0xFF00478d)));
  });

  testWidgets('AllergenCard responds to tap', (tester) async {
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

  testWidgets('AllergenCard displays icon based on allergen type', (tester) async {
    const allergen = Allergen(id: 'milk', nameHe: 'חלב');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AllergenCard(allergen: allergen),
        ),
      ),
    );

    expect(find.byIcon(Icons.water_drop), findsOneWidget);
  });
}