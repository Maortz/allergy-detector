import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/add_product_screen.dart';
import 'package:app/models/allergen.dart';
import 'package:app/widgets/allergen_card.dart';
import 'package:app/widgets/progress_stepper.dart';
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

      expect(find.text('הוסף מוצר'), findsOneWidget);
    });

    testWidgets('displays progress stepper widget', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(ProgressStepper), findsOneWidget);
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
}