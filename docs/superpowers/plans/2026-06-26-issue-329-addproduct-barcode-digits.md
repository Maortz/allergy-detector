# Plan: Issue #329 — [Add Product][Web] barcode field accepts non-numeric chars

## Root cause

The manual barcode `TextFormField` in `add_product_screen.dart` (~line 517) has
no `keyboardType` and no `inputFormatters`, so on web any character is accepted.
Mirror the #323 fix.

Branch `agent/issue-329-addproduct-barcode-digits` already created (A3 done).

## Fix

### Task 1 — `add_product_screen.dart`
1. Add `import 'package:flutter/services.dart';` (after the material import).
2. On the barcode `TextFormField` add:
   ```dart
   keyboardType: TextInputType.number,
   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
   ```
   Keep the existing `controller`/`decoration`.

### Task 2 — test (`add_product_test.dart`)
Add:
```dart
  // Issue #329: the manual barcode field rejects non-numeric input.
  testWidgets('Step 1 barcode field strips non-numeric characters',
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

    // The barcode field is the first TextFormField (product name is .last).
    await tester.enterText(find.byType(TextFormField).first, 'a12b3-c4');
    await tester.pump();

    expect(find.text('1234'), findsOneWidget);
  });
```

### Task 3 — A6 spec/index update
Add a #329 note to the add-product-step-1-barcode row in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

## Verify (from `app/`, one at a time)
1. `flutter pub get`
2. `flutter analyze lib test` — 0 issues.
3. `flutter test` — all green.

## A7 drift · A8 commit+PR · A9 comment+release
Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; body `Closes #329`.
