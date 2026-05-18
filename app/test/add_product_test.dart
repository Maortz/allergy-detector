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
        home: AddProductWizard(allergens: const []),
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
        home: AddProductWizard(allergens: const []),
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
}