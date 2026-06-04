import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/add_product_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/widgets/allergen_card.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('AddProductWizard Widget Tests', () {
    late List<Allergen> testAllergens;

    setUp(() {
      testAllergens = TestFixtures.sampleAllergens;
    });

    Widget createWidgetUnderTest({
      List<String> brands = const [],
    }) {
      return MaterialApp(
        home: AddProductWizard(
          allergens: testAllergens,
          brands: brands,
        ),
      );
    }

    testWidgets('displays Hebrew app bar title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Spec S4-1 (and shared with steps 1–3): canonical title is the
      // fixed "הוספת מוצר חדש" — see add-product-step-4-may-contain §7.1.
      expect(find.text('הוספת מוצר חדש'), findsOneWidget);
    });

    testWidgets('displays linear progress with step label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Spec S4-2: canonical wizard chrome is a LinearProgressIndicator with
      // right-aligned "שלב N מתוך 4" copy (no numbered-node stepper).
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('שלב 1 מתוך 4'), findsOneWidget);
    });

    testWidgets('step 1 displays barcode scanning placeholder with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('סריקת ברקוד'), findsOneWidget);
    });

    testWidgets('step 1 displays manual barcode input field with Hebrew label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('ברקוד ידני'), findsOneWidget);
    });

    testWidgets('step 1 displays product name input field with Hebrew label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('שם המוצר *'), findsOneWidget);
    });

    testWidgets('step 1 displays brand dropdown with Hebrew label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('מותג'), findsOneWidget);
      expect(find.text('בחר מותג (אופציונלי)'), findsOneWidget);
    });

    testWidgets('step 1 displays continue button with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('המשך'), findsOneWidget);
    });

    testWidgets('step 1 product name field accepts text input', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final nameField = find.widgetWithText(TextFormField, 'שם המוצר *');
      expect(nameField, findsOneWidget);

      await tester.enterText(nameField, 'פסטו');
      await tester.pump();

      expect(find.text('פסטו'), findsOneWidget);
    });

    testWidgets('step 1 barcode field accepts text input', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final barcodeField = find.widgetWithText(TextFormField, 'ברקוד ידני');
      expect(barcodeField, findsOneWidget);

      await tester.enterText(barcodeField, '7290123456789');
      await tester.pump();

      expect(find.text('7290123456789'), findsOneWidget);
    });
  });

  // Regression for issue #42 (follow-up to #13): steps 3 and 4 used to render
  // a hardcoded slug list (`'milk'`, `'egg'`, ...), so the IDs collected and
  // later sent to `ProductService.addProduct` were not real catalog UUIDs and
  // the `product_allergens` insert failed at runtime with
  // `invalid input syntax for type uuid: "milk"`.
  group('AddProductWizard allergen catalog (issue #42)', () {
    const catalog = <Allergen>[
      Allergen(
        id: 'a0000000-0000-0000-0000-000000000004',
        nameHe: 'חלב',
        nameEn: 'Dairy',
      ),
      Allergen(
        id: 'a0000000-0000-0000-0000-000000000005',
        nameHe: 'גלוטן',
        nameEn: 'Gluten',
      ),
    ];

    Future<void> advanceTo(WidgetTester tester, int step) async {
      for (var i = 1; i < step; i++) {
        final next = find.widgetWithText(ElevatedButton, 'המשך').first;
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pump();
      }
    }

    testWidgets('step 3 renders one card per catalog allergen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceTo(tester, 3);

      expect(find.byType(AllergenCard), findsNWidgets(catalog.length));
      expect(find.text('חלב'), findsOneWidget);
      expect(find.text('גלוטן'), findsOneWidget);
    });

    testWidgets('step 4 renders one card per catalog allergen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceTo(tester, 4);

      expect(find.byType(AllergenCard), findsNWidgets(catalog.length));
      expect(find.text('חלב'), findsOneWidget);
      expect(find.text('גלוטן'), findsOneWidget);
    });

    testWidgets('tapping a step-3 card stores the catalog UUID, not a slug',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceTo(tester, 3);

      await tester.tap(find.text('חלב'));
      await tester.pump();

      final state =
          tester.state<AddProductWizardState>(find.byType(AddProductWizard));
      expect(state.containsAllergenIds, {catalog[0].id});
      expect(state.containsAllergenIds.first, 'a0000000-0000-0000-0000-000000000004');
      expect(state.containsAllergenIds, isNot(contains('milk')));
    });

    testWidgets('tapping a step-4 card stores the catalog UUID, not a slug',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceTo(tester, 4);

      await tester.tap(find.text('גלוטן'));
      await tester.pump();

      final state =
          tester.state<AddProductWizardState>(find.byType(AddProductWizard));
      expect(state.mayContainAllergenIds, {catalog[1].id});
      expect(state.mayContainAllergenIds.first, 'a0000000-0000-0000-0000-000000000005');
      expect(state.mayContainAllergenIds, isNot(contains('wheat')));
    });

    testWidgets('an empty catalog renders no allergen cards on step 3',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: [])),
      );
      await advanceTo(tester, 3);

      expect(find.byType(AllergenCard), findsNothing);
    });
  });

  // Spec parity coverage for issue #57 (step-4 divergences S4-1..S4-6, S4-8,
  // S4-9). See docs/superpowers/specs/2026-05-19-stitch-screens/
  // add-product-step-4-may-contain.md §7.9.
  group('AddProductWizard step 4 spec parity (issue #57)', () {
    const catalog = <Allergen>[
      Allergen(id: 'id-milk', nameHe: 'חלב', nameEn: 'Dairy'),
      Allergen(id: 'id-eggs', nameHe: 'ביצים', nameEn: 'Eggs'),
      Allergen(id: 'id-gluten', nameHe: 'גלוטן', nameEn: 'Gluten'),
      Allergen(id: 'id-peanuts', nameHe: 'בוטנים', nameEn: 'Peanuts'),
      Allergen(id: 'id-nuts', nameHe: 'אגוזים', nameEn: 'Tree Nuts'),
      Allergen(id: 'id-sesame', nameHe: 'שומשום', nameEn: 'Sesame'),
    ];

    Future<void> advanceToStep4(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        final next = find.widgetWithText(ElevatedButton, 'המשך').first;
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pump();
      }
    }

    testWidgets('S4-3 step 4 renders the spec heading + sub-instruction',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceToStep4(tester);

      expect(find.text('האם יש חשש לעקבות?'), findsOneWidget);
      expect(
        find.text("סמן אלרגנים המצוינים תחת 'עלול להכיל' או 'בסביבת עבודה'"),
        findsOneWidget,
      );
    });

    testWidgets('S4-2 step 4 progress reads "שלב 4 מתוך 4" + "100% הושלם"',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceToStep4(tester);

      expect(find.text('שלב 4 מתוך 4'), findsOneWidget);
      expect(find.text('100% הושלם'), findsOneWidget);
    });

    testWidgets('S4-4 step 4 renders the 3 sub-section group headers',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceToStep4(tester);

      expect(find.text('חלב וביצים'), findsOneWidget);
      expect(find.text('גלוטן וקטניות'), findsOneWidget);
      expect(find.text('אגוזים וזרעים'), findsOneWidget);
    });

    testWidgets('S4-4 allergens chosen in step 3 are locked on step 4',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      // Advance to step 3, pick "חלב", then continue to step 4.
      for (var i = 0; i < 2; i++) {
        final next = find.widgetWithText(ElevatedButton, 'המשך').first;
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pump();
      }
      await tester.ensureVisible(find.text('חלב'));
      await tester.tap(find.text('חלב'));
      await tester.pump();
      final continueBtn = find.widgetWithText(ElevatedButton, 'המשך').first;
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pump();

      // Tapping the locked "חלב" chip on step 4 must NOT add it to
      // _selectedMayContain (the chip is wrapped in IgnorePointer).
      final state =
          tester.state<AddProductWizardState>(find.byType(AddProductWizard));
      expect(state.containsAllergenIds, contains('id-milk'));

      // Sanity: tapping an unlocked sibling DOES toggle.
      await tester.ensureVisible(find.text('ביצים'));
      await tester.tap(find.text('ביצים'));
      await tester.pump();
      expect(state.mayContainAllergenIds, contains('id-eggs'));
      expect(state.mayContainAllergenIds, isNot(contains('id-milk')));
    });

    testWidgets('S4-8 step 4 primary CTA is "סיום ושליחה" with a send icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceToStep4(tester);

      final cta = find.widgetWithText(ElevatedButton, 'סיום ושליחה');
      expect(cta, findsOneWidget);
      expect(
        find.descendant(of: cta, matching: find.byIcon(Icons.send)),
        findsOneWidget,
      );
    });

    testWidgets('S4-9 step 4 footer has a "חזרה" button that returns to step 3',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AddProductWizard(allergens: catalog)),
      );
      await advanceToStep4(tester);

      final back = find.widgetWithText(OutlinedButton, 'חזרה');
      expect(back, findsOneWidget);

      await tester.ensureVisible(back);
      await tester.tap(back);
      await tester.pump();

      // Step 3 heading is back, step-4 heading is gone.
      expect(find.text('בחר אלרגנים שהמוצר מכיל:'), findsOneWidget);
      expect(find.text('האם יש חשש לעקבות?'), findsNothing);
    });
  });
}