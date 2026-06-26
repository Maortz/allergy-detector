# Plan: Issue #330 — Step 2 "דילוג והזנה ידנית" (Skip) is a no-op

## Root cause

In the Add Product wizard step 2 (photos), both "המשך" (Continue) and the
"דילוג והזנה ידנית" skip link call `_nextStep` with identical effect, so Skip
appears to do nothing. Photos are **optional** per spec (add-product-step-2-
photos.md §2), so there are no required fields to gate "המשך" on — the
issue's "disable Next" path does not apply.

The spec defines distinct semantics (§7.4 / S2-9, line 206 / state-table line
169): Skip advances to step 3 with both photo fields **null** (discarding any
photos the user added), whereas Continue keeps the selected photos. Implement
that (Option B): give Skip its spec'd distinct, non-no-op behavior.

Branch `agent/issue-330-step2-skip-semantics` already created (A3 done).

## Fix

### Task 1 — `add_product_screen.dart`

1. Add a skip handler near `_nextStep`:
   ```dart
   /// Step-2 skip handler (spec §7.4 / S2-9): "דילוג והזנה ידנית" discards any
   /// photos the user added and advances to step 3 with both photo fields null
   /// — distinct from "המשך", which keeps the selected photos. Photos are
   /// optional (§2), so neither control is gated (#330).
   void _skipPhotos() {
     setState(() {
       _frontImagePath = null;
       _ingredientsImagePath = null;
       _frontUploadFailed = false;
       _ingredientsUploadFailed = false;
     });
     _nextStep();
   }
   ```
2. Wire the step-2 Skip `TextButton` `onPressed: _nextStep` → `onPressed: _skipPhotos`.
3. Add test-only getters next to the existing `@visibleForTesting` getters:
   ```dart
   @visibleForTesting
   String? get frontImagePathForTest => _frontImagePath;

   @visibleForTesting
   String? get ingredientsImagePathForTest => _ingredientsImagePath;
   ```

### Task 2 — test (`add_product_test.dart`)

```dart
  // Issue #330: the step-2 "דילוג והזנה ידנית" link must do something distinct
  // from "המשך" — it discards any added photos and advances to step 3.
  testWidgets('Step 2 skip discards added photos and advances to step 3',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: const AddProductWizard(
          allergens: [Allergen(id: 'milk', nameHe: 'חלב')],
          mobileScannerBuilder: _noOpMobileScannerBuilder,
        ),
      ),
    );

    final state = tester.state<AddProductWizardState>(
      find.byType(AddProductWizard),
    );
    state.goToStepForTest(2);
    await tester.pump();

    await state.selectFrontPhotoForTest('/tmp/front.jpg');
    await tester.pump();
    expect(state.frontImagePathForTest, '/tmp/front.jpg');

    await tester.ensureVisible(find.text('דילוג והזנה ידנית'));
    await tester.tap(find.text('דילוג והזנה ידנית'));
    await tester.pump();

    // Skip discarded the photo and advanced to step 3 (allergen grid heading).
    expect(state.frontImagePathForTest, isNull);
    expect(state.ingredientsImagePathForTest, isNull);
    expect(find.text('מהם האלרגנים במוצר?'), findsOneWidget);
  });
```

### Task 3 — A6 spec/index update
Add a #330 note to the add-product-step-2-photos row in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

## Verify (from `app/`, one at a time)
1. `flutter pub get`
2. `flutter analyze lib test` — 0 issues.
3. `flutter test` — all green.

## A7 drift · A8 commit+PR · A9 comment+release
Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; body `Closes #330`
explaining Option B (photos optional → no field-gating; Skip given distinct
discard-and-advance semantics per spec).
