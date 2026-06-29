# Plan: Issue #323 — [Scan][Web] Barcode input too large & accepts non-numeric chars

## Goal

The web manual-barcode `TextField` in `SearchScanScreen` (a) stretches full-width
(too large) and (b) accepts letters/symbols. Constrain its width and restrict
input to digits. Extract the manual-entry block into a small `@visibleForTesting`
widget so the fix is unit-testable without faking `kIsWeb` (the block is
`kIsWeb`-gated and currently has zero test coverage).

Branch `agent/issue-323-web-barcode-input` already created (A3 done).

## Acceptance criteria (from issue)

- Input width matches design-system sizing (consistent with other form fields).
- Input restricted to numeric digits (digit-only formatter).
- Non-numeric characters rejected on input.

## Files

- `app/lib/screens/search_scan_screen.dart` — add `package:flutter/services.dart`
  import; extract `ManualBarcodeEntry` widget with `maxWidth` constraint +
  `FilteringTextInputFormatter.digitsOnly`; `_buildManualBarcodeEntry` delegates
  to it.
- `app/test/widgets/screens/manual_barcode_entry_test.dart` — new test file.
- `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — A6 status note.

## Task 1 — Extract `ManualBarcodeEntry` widget

Add import at top (with the other package imports):
```dart
import 'package:flutter/services.dart';
```

Replace the body of `_buildManualBarcodeEntry()` so it delegates to a new named
widget, passing the existing submit logic:
```dart
  Widget _buildManualBarcodeEntry() {
    return ManualBarcodeEntry(
      onSubmitted: (barcode) {
        if (barcode.isNotEmpty) {
          _handleBarcodeScan(
            BarcodeCapture(barcodes: [Barcode(rawValue: barcode)]),
          );
        }
      },
    );
  }
```

Add the widget (top-level, after `SearchScanScreenState` or near `_RecentScanCard`):
```dart
/// Manual barcode entry shown on web (no camera). Extracted as a named,
/// [visibleForTesting] widget so its digit-only restriction and width
/// constraint (issue #323) are unit-testable without faking `kIsWeb`.
@visibleForTesting
class ManualBarcodeEntry extends StatelessWidget {
  /// Called with the trimmed entered barcode when the user submits the field.
  final ValueChanged<String> onSubmitted;

  /// Max width of the input, keeping it consistent with other form fields
  /// instead of stretching full-width on wide web viewports (issue #323).
  static const double maxFieldWidth = 320;

  const ManualBarcodeEntry({super.key, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הכנס ברקוד',
          style: AppTypography.h3.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: maxFieldWidth),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'הכנס ברקוד',
                      hintText: '72900...',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    // On web `keyboardType` is only a hint; the formatter is
                    // what actually blocks letters/symbols (issue #323).
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => onSubmitted(value.trim()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

## Task 2 — Test

New file `app/test/widgets/screens/manual_barcode_entry_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/screens/search_scan_screen.dart';

void main() {
  group('ManualBarcodeEntry (#323)', () {
    Widget host(ValueChanged<String> onSubmitted) => MaterialApp(
          home: Scaffold(
            body: ManualBarcodeEntry(onSubmitted: onSubmitted),
          ),
        );

    testWidgets('restricts input to digits only', (tester) async {
      await tester.pumpWidget(host((_) {}));

      await tester.enterText(find.byType(TextField), 'a1b2-3c');
      await tester.pump();

      expect(find.text('123'), findsOneWidget);
    });

    testWidgets('constrains the field width to the design-system max',
        (tester) async {
      await tester.pumpWidget(host((_) {}));

      final box = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(box.constraints.maxWidth, ManualBarcodeEntry.maxFieldWidth);
    });

    testWidgets('submits the trimmed entered barcode', (tester) async {
      String? submitted;
      await tester.pumpWidget(host((v) => submitted = v));

      await tester.enterText(find.byType(TextField), '7290000000001');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(submitted, '7290000000001');
    });
  });
}
```

## Task 3 — A6 spec/index update

Add a short note to the `search-scan` row Code cell in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` documenting #323
(web manual barcode field now digit-only + width-constrained, extracted into
`ManualBarcodeEntry`).

## Verify (one command at a time, from `app/`)

1. `flutter pub get`
2. `flutter analyze lib test` — 0 issues.
3. `flutter test` — all green.

## A7 — drift check
`git fetch origin` then `git log origin/master..HEAD --oneline`.

## A8 — commit + PR
Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; PR body
`Closes #323` + summary + analyze/test results.

## A9 — comment + release
Comment on #323 with PR link; `gh issue edit 323 --remove-label agent-in-progress`.
