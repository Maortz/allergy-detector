import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/allergen_card.dart';
import 'package:app/models/allergen.dart';
import 'package:app/theme/app_theme.dart';

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
        theme: buildAppTheme(),
        home: const Scaffold(
          body: AllergenCard(
            allergen: allergen,
            isSelected: true,
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    // Selected border is theme primary (light colorScheme.primary == #00478d).
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

  testWidgets(
      'selected and unselected cards fill identical constraints (#335)',
      (tester) async {
    const allergen = Allergen(id: 'milk', nameHe: 'חלב');
    const cell = Size(150, 150);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox.fromSize(
                size: cell,
                child: const AllergenCard(
                  key: Key('unselected'),
                  allergen: allergen,
                ),
              ),
              SizedBox.fromSize(
                size: cell,
                child: const AllergenCard(
                  key: Key('selected'),
                  allergen: allergen,
                  isSelected: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Size cardSize(Key key) => tester.getSize(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(Container),
          ),
        );

    final unselectedSize = cardSize(const Key('unselected'));
    final selectedSize = cardSize(const Key('selected'));

    // Both cards must fully occupy their (identical) cell — a selected card
    // must not collapse to its intrinsic content size.
    expect(unselectedSize, equals(cell));
    expect(selectedSize, equals(unselectedSize));
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