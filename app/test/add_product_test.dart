import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/models/allergen.dart';
import 'package:app/widgets/photo_upload_card.dart';
import 'package:app/screens/add_product_screen.dart';

// No-op [MobileScanner] replacement for tests: renders an empty box and never
// starts camera hardware. Mirrors the seam in search_scan_screen_test.dart;
// tests drive the denial path via `state.onScannerError(...)` directly.
Widget _noOpMobileScannerBuilder(
  MobileScannerController controller,
  Widget Function(BuildContext, MobileScannerException) errorBuilder,
) =>
    const SizedBox.shrink();

void main() {
  testWidgets('Step 1 renders: live scanner card, manual barcode, product name, brand dropdown', (tester) async {
    final allergens = [
      const Allergen(id: 'milk', nameHe: 'חלב'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: AddProductWizard(
          allergens: allergens,
          mobileScannerBuilder: _noOpMobileScannerBuilder,
        ),
      ),
    );

    expect(find.text('הוספת מוצר חדש'), findsOneWidget);
    // On a native test host the live scanner viewport renders (issue #265):
    // the camera-unavailable placeholder is the fallback, not the default.
    expect(find.text('סריקת ברקוד'), findsOneWidget);
    expect(find.text('המצלמה לא זמינה'), findsNothing);
    expect(find.text('מספר ברקוד (ידני)'), findsOneWidget);
    expect(find.text('שם המוצר'), findsOneWidget);
    expect(find.text('מותג / יצרן'), findsOneWidget);
  });

  // Issue #265: a denied camera degrades the live viewport to the S1-14
  // placeholder while the manual barcode field stays usable.
  testWidgets('Step 1 camera-denied shows degraded placeholder, manual entry stays',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const AddProductWizard(
          allergens: <Allergen>[],
          mobileScannerBuilder: _noOpMobileScannerBuilder,
        ),
      ),
    );

    expect(find.text('סריקת ברקוד'), findsOneWidget);
    expect(find.text('המצלמה לא זמינה'), findsNothing);

    final state = tester.state<AddProductWizardState>(
      find.byType(AddProductWizard),
    );
    state.onScannerError(
      const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      ),
    );
    // setState is deferred to a post-frame callback (mirrors production).
    await tester.pump();
    await tester.pump();

    expect(find.text('המצלמה לא זמינה'), findsOneWidget);
    expect(find.byIcon(Icons.no_photography), findsOneWidget);
    // Manual barcode entry remains functional.
    expect(find.text('מספר ברקוד (ידני)'), findsOneWidget);
  });

  // Issue #265: scanning a barcode pre-fills the manual barcode field.
  testWidgets('Step 1 scan pre-fills the barcode field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const AddProductWizard(
          allergens: <Allergen>[],
          mobileScannerBuilder: _noOpMobileScannerBuilder,
        ),
      ),
    );

    final state = tester.state<AddProductWizardState>(
      find.byType(AddProductWizard),
    );
    state.handleBarcodeScan(
      const BarcodeCapture(barcodes: [Barcode(rawValue: '7290000000001')]),
    );
    await tester.pump();

    expect(find.text('7290000000001'), findsOneWidget);
  });

  // Spec §7.6 / issue AC #2 — required-field validation. The Continue button is
  // disabled until both required fields (name + brand) are valid; touching a
  // field surfaces inline error copy for any field still invalid. Filling both
  // clears the errors, enables the button, and lets the wizard reach step 2.
  testWidgets('Step 1 invalid->valid: button disabled + inline errors',
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

    // Pristine form: no error copy yet, and the Continue button is disabled.
    expect(find.text('נא למלא שם מוצר'), findsNothing);
    expect(find.text('נא לבחור מותג'), findsNothing);
    ElevatedButton continueButton() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'המשך'),
        );
    expect(continueButton().onPressed, isNull);

    // Tapping the disabled button does nothing — stays on step 1.
    await tester.ensureVisible(find.text('המשך'));
    await tester.tap(find.text('המשך'));
    await tester.pump();
    expect(find.byType(PhotoUploadCard), findsNothing);

    // Fill the product name → its error stays clear; brand error now shows
    // (the form has been touched) and the button is still disabled.
    await tester.enterText(find.byType(TextFormField).last, 'ביסקוויטים');
    await tester.pump();
    expect(find.text('נא למלא שם מוצר'), findsNothing);
    expect(find.text('נא לבחור מותג'), findsOneWidget);
    expect(continueButton().onPressed, isNull);

    // Select a brand → brand error clears and the button enables.
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('תנובה').last);
    await tester.pumpAndSettle();
    expect(find.text('נא לבחור מותג'), findsNothing);
    expect(continueButton().onPressed, isNotNull);

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

    expect(find.text('מהם האלרגנים במוצר?'), findsOneWidget);
    expect(find.text('חלב וביצים'), findsOneWidget);
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
    expect(find.text('מהם האלרגנים במוצר?'), findsNothing);
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
