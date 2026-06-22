# Plan: Fix camera "not available" on Add New Product screen (#265)

## Problem

`AddProductWizard._buildStep1()` (`app/lib/screens/add_product_screen.dart`)
unconditionally renders `const _CameraUnavailablePlaceholder()`. No
`ScannerService` / `MobileScanner` is ever instantiated, so on a real Android
device with a working camera the user always sees "המצלמה לא זמינה". The spec
(`add-product-step-1-barcode.md` §6 Camera lifecycle, §7.8 #8) requires a live
barcode viewport that degrades to the placeholder only when the camera is
genuinely unavailable (web, emulator, or denied permission).

`SearchScanScreen` already implements the correct, test-seamed pattern. This
fix ports that pattern into `AddProductWizard` step 1, keeping the existing
placeholder as the genuine fallback and keeping the manual barcode field
functional throughout.

Branch `agent/issue-265-add-product-camera` is already created (A3 done).
Execution starts at Task 1.

## Constraints / conventions

- Hebrew RTL-first; theme tokens only (`AppColors`/`AppTypography`/`AppSpacing`).
- `const` constructors where possible; correct controller disposal.
- Tests must NOT touch real camera hardware: inject a `mobileScannerBuilder`
  and/or `scannerService` seam, exactly like `SearchScanScreen`.
- Do NOT `pumpAndSettle` against a widget with a repeating animation if one is
  added — `AddProductWizard` currently has none; do not introduce a repeating
  animation controller (the scanner card in step 1 does not need the laser
  overlay; keep it simple per the placeholder card aesthetics + a live feed).
- One verify command at a time, no `&&` chaining for analyze/test.

## Task 1 — Add scanner imports + test seams to `AddProductWizard`

File: `app/lib/screens/add_product_screen.dart`.

Add imports at the top (after existing imports):

```dart
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/scanner_service.dart';
```

Add two optional fields to the widget (mirroring `SearchScanScreen`), keeping
the constructor `const`:

```dart
  /// Optional scanner-service override. Tests inject a pre-configured service
  /// so the camera path is exercised without real hardware. Production passes
  /// null and a fresh [ScannerService] is created in [initState].
  final ScannerService? scannerService;

  /// Optional factory that wraps the [MobileScanner] widget. In production this
  /// is null and the real [MobileScanner] is used; tests inject a no-op builder
  /// to avoid platform-channel camera init in the test VM.
  @visibleForTesting
  final Widget Function(
    MobileScannerController controller,
    Widget Function(BuildContext, MobileScannerException) errorBuilder,
  )? mobileScannerBuilder;
```

Add them to the constructor parameter list:

```dart
    this.scannerService,
    this.mobileScannerBuilder,
```

## Task 2 — Wire scanner lifecycle in state

File: `app/lib/screens/add_product_screen.dart`, `AddProductWizardState`.

Add state fields:

```dart
  ScannerService? _scannerService;
  bool _cameraDenied = false;
  bool _cameraPermanentlyDenied = false;
  bool _scanBusy = false;
```

Add `initState` (the class currently has none — it relies on field initializers;
add an `initState` override that calls `super.initState()` first):

```dart
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scannerService = widget.scannerService ?? ScannerService();
      _scannerService!.initialize();
    }
  }
```

Update `dispose()` to also dispose the scanner (keep existing controller
disposes):

```dart
    _scannerService?.dispose();
```
(added before `super.dispose();`)

## Task 3 — Replace the unconditional placeholder in `_buildStep1`

File: `app/lib/screens/add_product_screen.dart`, `_buildStep1()`.

Replace `const _CameraUnavailablePlaceholder(),` (the first child) with a call
to a new `_buildScannerCard()` method. Add the heading + sub-text per spec §3
above the viewport.

New methods on the state:

```dart
  /// Step-1 scanner card. Shows the live camera viewport on native platforms,
  /// degrading to [_CameraUnavailablePlaceholder] on web or when the OS denied
  /// camera permission. The manual barcode field below stays functional in all
  /// states (spec §6 / §7.8 #8).
  Widget _buildScannerCard() {
    if (kIsWeb || _cameraDenied) {
      return const _CameraUnavailablePlaceholder();
    }
    final controller = _scannerService?.controller;
    if (controller == null) {
      return const _CameraUnavailablePlaceholder();
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: widget.mobileScannerBuilder != null
            ? widget.mobileScannerBuilder!(
                controller,
                (ctx, error) {
                  onScannerError(error);
                  return const _CameraUnavailablePlaceholder();
                },
              )
            : MobileScanner(
                controller: controller,
                onDetect: _handleBarcodeScan,
                errorBuilder: (context, error) {
                  onScannerError(error);
                  return const _CameraUnavailablePlaceholder();
                },
                placeholderBuilder: (_) => const _CameraUnavailablePlaceholder(),
              ),
      ),
    );
  }
```

In `_buildStep1`, the first child becomes:

```dart
        Text(
          'סריקת ברקוד',
          style: AppTypography.h3.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'כוון את המצלמה אל הברקוד שעל גבי אריזת המוצר',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildScannerCard(),
```

(Verify `AppSpacing.xs` exists; if not, use `AppSpacing.sm`. Verify
`AppTypography.h3` and `AppTypography.bodySm` exist — they are used by
`SearchScanScreen`, so they do.)

## Task 4 — Error routing + barcode handling

File: `app/lib/screens/add_product_screen.dart`, `AddProductWizardState`.

Port the `onScannerError` post-frame pattern from `SearchScanScreen` (deferred
setState to avoid "setState during build"):

```dart
  /// Routes camera errors. Permission-denied flips [_cameraDenied] so the card
  /// degrades to the placeholder. Deferred to the next frame because
  /// errorBuilder runs during MobileScanner's build.
  @visibleForTesting
  void onScannerError(MobileScannerException error) {
    if (ScannerService.isPermissionDenied(error.errorCode) && !_cameraDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_cameraDenied) {
          setState(() => _cameraDenied = true);
        }
      });
    }
  }
```

Add the barcode handler. On a successful scan, pre-fill the barcode field (per
issue AC "User can scan a barcode to pre-fill the product barcode field"):

```dart
  /// Test seam mirroring [MobileScanner.onDetect].
  @visibleForTesting
  void handleBarcodeScan(BarcodeCapture capture) => _handleBarcodeScan(capture);

  void _handleBarcodeScan(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty || _scanBusy) return;
    _scanBusy = true;
    setState(() => _barcodeController.text = barcode);
    _scanBusy = false;
  }
```

(Confirm `firstOrNull` is available — it comes from `dart:collection`
extensions via `package:collection` or the SDK iterable extension used in
`search_scan_screen.dart`; SearchScanScreen uses `capture.barcodes.firstOrNull`
without an extra import, so the SDK extension is in scope.)

## Task 5 — Update the existing widget test

File: `app/test/add_product_test.dart`.

The first test ("Step 1 renders…") currently asserts the placeholder shows
unconditionally. After the fix, on the non-web test VM the scanner card renders
a `MobileScanner` unless a builder is injected. Update that test to inject a
no-op `mobileScannerBuilder` and a stub `scannerService`, then assert the live
viewport path renders (heading "סריקת ברקוד") AND the manual field/name/brand
still render. Keep all other tests passing (they don't assert on the scanner).

Plan for the test changes:
- Import `package:mobile_scanner/mobile_scanner.dart` and
  `package:app/services/scanner_service.dart`.
- Provide a fake `ScannerService` subclass exposing a non-null controller, OR
  inject only `mobileScannerBuilder` returning a `SizedBox` and a real
  `ScannerService` whose `initialize()` is a no-op in tests. Simpler: inject
  `mobileScannerBuilder: (_, __) => const SizedBox()` AND a fake service whose
  `controller` is non-null. Because `MobileScannerController()` construction may
  hit a platform channel, the fake must override `initialize()` to set a
  controller without the real constructor — but the controller type is sealed.
  Cleanest approach that matches `SearchScanScreen` tests: check how
  `search_scan_screen_test.dart` injects the scanner and replicate exactly.
  (Execution agent: read that test first and mirror its fake/seam precisely.)
- Update the first test to assert `find.text('סריקת ברקוד')` is present and the
  manual barcode field / name / brand labels remain. Drop the unconditional
  `המצלמה לא זמינה` assertion (or move it to a dedicated web/denied test if the
  seam supports forcing that state without real hardware).

Execution note: prefer the minimal change that keeps the suite green. If the
controller cannot be faked cleanly, fall back to asserting via the injected
`mobileScannerBuilder` (which receives the real controller only when
`_scannerService?.controller != null`). Inspect `search_scan_screen_test.dart`
for the canonical seam before writing.

## Task 6 — Verify

Run from `app/`, one at a time:

```
flutter pub get
flutter analyze lib test
flutter test
```

All must be clean / green (0 analyze issues, all tests pass).

## Task 7 — Spec index update (A6)

File: `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

Update the row `add-product step-1 — camera unavailable` (line ~90) Code column
to note that #265 wired the live `MobileScanner` viewport (degrading to the
S1-14 placeholder only on web/denied/no-controller), with scan pre-filling the
barcode field. Update the main `add-product-step-1-barcode` row (line 30) Code
column similarly if appropriate.

## Task 8 — Drift check (A7)

```
git fetch origin
git log origin/master..HEAD --oneline
```

Only this branch's own commit(s) should appear. Foreign commits → STOPPED.

## Task 9 — Commit + PR (A8)

```
git add -A
git commit   # message below
git push -u origin agent/issue-265-add-product-camera
gh pr create --base master --repo Maortz/allergy-detector --title "fix(add-product): wire live camera scanner into step 1 (#265)" --body ...
```

Commit message footer:
```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

PR body: `Closes #265`, change summary, analyze/test results.

## Task 10 — Comment + release claim (A9)

```
gh issue comment 265 --repo Maortz/allergy-detector --body "<PR link + summary>"
gh issue edit 265 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
