import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/allergen.dart';
import 'package:app/widgets/photo_upload_card.dart';
import 'package:app/screens/add_product_screen.dart';

void main() {
  testWidgets('Step 1 renders: barcode scanner, manual barcode, product name, brand dropdown', (tester) async {
    final allergens = [
      const Allergen(id: 'milk', nameHe: 'חלב'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: AddProductWizard(allergens: allergens),
      ),
    );

    expect(find.text('הוסף מוצר'), findsOneWidget);
    expect(find.text('סריקת ברקוד'), findsOneWidget);
    expect(find.text('ברקוד ידני'), findsOneWidget);
    expect(find.text('שם המוצר *'), findsOneWidget);
    expect(find.text('מותג'), findsOneWidget);
  });

  testWidgets('Step 1 continue button exists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddProductWizard(allergens: const []),
      ),
    );

    await tester.ensureVisible(find.text('המשך'));
    await tester.pumpAndSettle();

    expect(find.text('המשך'), findsOneWidget);
  });

  testWidgets('Step 1 tap advances to step 2 with photo cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddProductWizard(allergens: const []),
      ),
    );

    await tester.ensureVisible(find.text('המשך'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoUploadCard), findsNWidgets(2));
    expect(find.text('חזית המוצר'), findsOneWidget);
    expect(find.text('רשימת רכיבים'), findsOneWidget);
  });

  testWidgets('Step 2 tap advances to step 3 with allergen grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddProductWizard(allergens: _catalog),
      ),
    );

    await tester.ensureVisible(find.text('המשך'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('המשך'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();

    expect(find.text('בחר אלרגנים שהמוצר מכיל:'), findsOneWidget);
    expect(find.text('אגוזים וזרעים'), findsOneWidget);
  });

  testWidgets('Step 3 tap advances to step 4 with may contain grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddProductWizard(allergens: _catalog),
      ),
    );

    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(find.text('המשך'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();
    }

    expect(find.text('בחר אלרגנים שהמוצר עשוי להכיל:'), findsOneWidget);
    expect(find.text('שמור מוצר'), findsOneWidget);
  });

  // Regression for issue #59: when the allergen catalog fails to load
  // (AppShell's fetch returns []), steps 3/4 must show an error state instead
  // of an empty grid, and must NOT expose the advance/save button — otherwise
  // an empty allergen set could be submitted as if it were a deliberate choice.
  testWidgets('Step 3 with empty catalog shows error state and hides advance',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddProductWizard(allergens: const []),
      ),
    );

    // step 1 -> 2
    await tester.ensureVisible(find.text('המשך'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();
    // step 2 -> 3
    await tester.ensureVisible(find.text('המשך'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();

    expect(find.text('טעינת רשימת האלרגנים נכשלה. נסה שוב.'), findsOneWidget);
    expect(find.text('בחר אלרגנים שהמוצר מכיל:'), findsNothing);
    // advance button is gone, so the empty-set submit path is closed
    expect(find.text('המשך'), findsNothing);
  });

  testWidgets('empty-catalog error state shows retry when handler is wired',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AddProductWizard(
          allergens: const [],
          onRetryCatalog: () => retried = true,
        ),
      ),
    );

    // step 1 -> 2 -> 3
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.text('המשך'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('נסה שוב'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });
}

const _catalog = <Allergen>[
  Allergen(id: 'a0000000-0000-0000-0000-000000000004', nameHe: 'חלב'),
  Allergen(id: 'a0000000-0000-0000-0000-000000000005', nameHe: 'גלוטן'),
];
