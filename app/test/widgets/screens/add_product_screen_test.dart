import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/add_product_screen.dart';
import 'package:app/models/allergen.dart';
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

    testWidgets('displays progress stepper with Hebrew labels', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('ברקוד'), findsOneWidget);
      expect(find.text('תמונות'), findsOneWidget);
      expect(find.text('מכיל'), findsOneWidget);
      expect(find.text('עשוי להכיל'), findsOneWidget);
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
}