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

    expect(find.text('הוספת מוצר חדש'), findsOneWidget);
    // Camera-unavailable degraded scanner placeholder (S1-14).
    expect(find.text('המצלמה לא זמינה'), findsOneWidget);
    expect(find.byIcon(Icons.no_photography), findsOneWidget);
    expect(find.text('ברקוד ידני'), findsOneWidget);
    expect(find.text('שם המוצר *'), findsOneWidget);
    expect(find.text('מותג'), findsOneWidget);
  });

  // Spec §7.6 — required-field validation. Tapping המשך with empty name +
  // unselected brand surfaces inline errors and blocks advancing; filling the
  // fields clears the errors and lets the wizard proceed to step 2.
  testWidgets('Step 1 invalid->valid: shows inline errors then advances',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const AddProductWizard(
          allergens: <Allergen>[],
          brands: ['תנובה', 'שטראוס'],
        ),
      ),
    );

    // Pristine form: no error copy yet.
    expect(find.text('נא למלא שם מוצר'), findsNothing);
    expect(find.text('נא לבחור מותג'), findsNothing);

    // Tap המשך with empty fields → inline errors appear, still on step 1.
    await tester.ensureVisible(find.text('המשך'));
    await tester.tap(find.text('המשך'));
    await tester.pump();

    expect(find.text('נא למלא שם מוצר'), findsOneWidget);
    expect(find.text('נא לבחור מותג'), findsOneWidget);
    // Did not advance — step-2 photo cards absent.
    expect(find.byType(PhotoUploadCard), findsNothing);

    // Fill the product name → its error clears reactively.
    await tester.enterText(find.byType(TextFormField).last, 'ביסקוויטים');
    await tester.pump();
    expect(find.text('נא למלא שם מוצר'), findsNothing);
    expect(find.text('נא לבחור מותג'), findsOneWidget);

    // Select a brand → brand error clears.
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('תנובה').last);
    await tester.pumpAndSettle();
    expect(find.text('נא לבחור מותג'), findsNothing);

    // Now valid → המשך advances to step 2.
    await tester.ensureVisible(find.text('המשך'));
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoUploadCard), findsNWidgets(2));
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
        localizationsDelegates: _l10n,
        home: const AddProductWizard(allergens: <Allergen>[], brands: _brands),
      ),
    );

    await _completeStep1(tester);

    expect(find.byType(PhotoUploadCard), findsNWidgets(2));
    expect(find.text('חזית המוצר'), findsOneWidget);
    expect(find.text('רשימת רכיבים'), findsOneWidget);
  });

  testWidgets('Step 2 tap advances to step 3 with allergen grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _l10n,
        home: const AddProductWizard(allergens: _catalog, brands: _brands),
      ),
    );

    await _completeStep1(tester);
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
        localizationsDelegates: _l10n,
        home: const AddProductWizard(allergens: _catalog, brands: _brands),
      ),
    );

    await _completeStep1(tester);
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.text('המשך'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();
    }

    // Step 4 spec (S4-3, S4-8, S4-9): heading + primary CTA + back button.
    expect(find.text('האם יש חשש לעקבות?'), findsOneWidget);
    expect(find.text('סיום ושליחה'), findsOneWidget);
    expect(find.text('חזרה'), findsOneWidget);
  });

  // Regression for issue #59: when the allergen catalog fails to load
  // (AppShell's fetch returns []), steps 3/4 must show an error state instead
  // of an empty grid, and must NOT expose the advance/save button — otherwise
  // an empty allergen set could be submitted as if it were a deliberate choice.
  testWidgets('Step 3 with empty catalog shows error state and hides advance',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: _l10n,
        home: const AddProductWizard(allergens: <Allergen>[], brands: _brands),
      ),
    );

    // step 1 -> 2 (fill required fields first)
    await _completeStep1(tester);
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
        localizationsDelegates: _l10n,
        home: AddProductWizard(
          allergens: const [],
          brands: _brands,
          onRetryCatalog: () => retried = true,
        ),
      ),
    );

    // step 1 -> 2 (fill required fields first)
    await _completeStep1(tester);
    // step 2 -> 3
    await tester.ensureVisible(find.text('המשך'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('המשך'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('נסה שוב'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });
}

const _l10n = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

const _brands = ['תנובה', 'שטראוס'];

const _catalog = <Allergen>[
  Allergen(id: 'a0000000-0000-0000-0000-000000000004', nameHe: 'חלב'),
  Allergen(id: 'a0000000-0000-0000-0000-000000000005', nameHe: 'גלוטן'),
];

/// Fills the step-1 required fields (product name + brand) per spec §7.6 and
/// taps המשך to advance to step 2.
Future<void> _completeStep1(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).last, 'מוצר בדיקה');
  await tester.pump();
  // The brand dropdown sits in a scroll view; bring it on-screen, open it, and
  // give the menu route a timed pump (pumpAndSettle alone races the open).
  final dropdown = find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.text('תנובה').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('המשך'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('המשך'));
  await tester.pumpAndSettle();
}
