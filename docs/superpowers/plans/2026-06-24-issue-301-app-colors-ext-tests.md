# Implementation Plan — Issue #301: Unit tests for AppColorsExt ThemeExtension

**Issue:** Maortz/allergy-detector#301
**Branch:** `agent/issue-301-app-colors-ext-tests` (already created — execution starts at the first code task)
**Effort:** S · **Phase:** 4-verify

## Goal

`AppColorsExt` (added in merged PR #300, lives in `app/lib/theme/app_colors.dart`) has no unit-test coverage. It implements `copyWith`, `lerp`, the `light()`/`dark()` factories, and the `AppColorsContext.colors` `BuildContext` extension — all of which can silently regress when fields are added or values change. This plan adds a dedicated test file covering those four surfaces.

## Constraints / standards

- Test-only change. No production code is modified.
- New file: `app/test/unit/theme/app_colors_ext_test.dart` (keeps `app_colors_test.dart` focused on the static-const design tokens; mirrors the existing one-concern-per-file layout in `app/test/unit/theme/`).
- Import style and `expect(... , const Color(0x...))` assertions follow the existing `app_colors_test.dart`.
- One verify command at a time — no `&&` chaining.
- Hebrew/RTL not relevant here (no UI strings).

## Reference values (from `app/lib/theme/app_colors.dart`, do not guess)

- `AppColorsExt.light().safeBackground == const Color(0xFFE6F4EA)`
- `AppColorsExt.light().borderSubtle == const Color(0xFFE5E7EB)`
- `AppColorsExt.dark().safeBackground == const Color(0xFF1B3A24)`
- `AppColorsExt.dark().borderSubtle == const Color(0xFF374151)`
- `context.colors` falls back to `AppColorsExt.light()` when no extension is registered; `buildAppTheme()` registers `AppColorsExt.light()` via `extensions: [...]`.

---

## Task 1 — Write the test file

Create `app/test/unit/theme/app_colors_ext_test.dart` with the following content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  group('AppColorsExt - factories', () {
    test('light() returns a non-null instance with expected sample values', () {
      final light = AppColorsExt.light();
      expect(light, isNotNull);
      expect(light.safeBackground, const Color(0xFFE6F4EA));
      expect(light.borderSubtle, const Color(0xFFE5E7EB));
      expect(light.scanFrame, const Color(0xFF1A8CF8));
    });

    test('dark() returns a non-null instance with expected sample values', () {
      final dark = AppColorsExt.dark();
      expect(dark, isNotNull);
      expect(dark.safeBackground, const Color(0xFF1B3A24));
      expect(dark.borderSubtle, const Color(0xFF374151));
    });

    test('light() and dark() differ for theme-aware tokens', () {
      expect(
        AppColorsExt.light().safeBackground,
        isNot(AppColorsExt.dark().safeBackground),
      );
    });
  });

  group('AppColorsExt.copyWith', () {
    test('overrides only the named field, leaving others unchanged', () {
      final base = AppColorsExt.light();
      const override = Color(0xFF123456);
      final copy = base.copyWith(safeBackground: override);

      expect(copy.safeBackground, override);
      // Untouched fields are preserved.
      expect(copy.borderSubtle, base.borderSubtle);
      expect(copy.avoid, base.avoid);
      expect(copy.chipDetectedFg, base.chipDetectedFg);
      expect(copy.warningContainer, base.warningContainer);
    });

    test('with no arguments returns an equivalent instance', () {
      final base = AppColorsExt.light();
      final copy = base.copyWith();

      expect(copy.safeBackground, base.safeBackground);
      expect(copy.borderSubtle, base.borderSubtle);
      expect(copy.onDestructiveSubtle, base.onDestructiveSubtle);
    });
  });

  group('AppColorsExt.lerp', () {
    test('t=0.0 yields the source values', () {
      final a = AppColorsExt.light();
      final b = AppColorsExt.dark();
      final result = a.lerp(b, 0.0);

      expect(result.safeBackground, a.safeBackground);
      expect(result.borderSubtle, a.borderSubtle);
    });

    test('t=1.0 yields the target values', () {
      final a = AppColorsExt.light();
      final b = AppColorsExt.dark();
      final result = a.lerp(b, 1.0);

      expect(result.safeBackground, b.safeBackground);
      expect(result.borderSubtle, b.borderSubtle);
    });

    test('midpoint interpolates between source and target', () {
      final a = AppColorsExt.light();
      final b = AppColorsExt.dark();
      final result = a.lerp(b, 0.5);

      expect(
        result.safeBackground,
        Color.lerp(a.safeBackground, b.safeBackground, 0.5),
      );
      // Midpoint is distinct from both endpoints for a token that changes.
      expect(result.safeBackground, isNot(a.safeBackground));
      expect(result.safeBackground, isNot(b.safeBackground));
    });

    test('null other returns this unchanged', () {
      final a = AppColorsExt.light();
      final result = a.lerp(null, 0.5);

      expect(result.safeBackground, a.safeBackground);
      expect(result.borderSubtle, a.borderSubtle);
    });
  });

  group('AppColorsContext.colors', () {
    testWidgets('returns the extension registered by buildAppTheme()',
        (tester) async {
      late AppColorsExt captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) {
              captured = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.safeBackground, AppColorsExt.light().safeBackground);
      expect(captured.borderSubtle, AppColorsExt.light().borderSubtle);
    });

    testWidgets('falls back to light() when no extension is registered',
        (tester) async {
      late AppColorsExt captured;
      await tester.pumpWidget(
        MaterialApp(
          // A bare ThemeData with no AppColorsExt registered.
          theme: ThemeData(useMaterial3: true),
          home: Builder(
            builder: (context) {
              captured = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured.safeBackground, AppColorsExt.light().safeBackground);
    });
  });
}
```

This covers all four items in the issue's suggested fix: (1) factories return non-null with correct sample values, (2) `copyWith` override smoke test, (3) `lerp` at 0.0 / 1.0 / midpoint (plus the null-other branch), (4) `context.colors` widget test against `buildAppTheme()` (plus the fallback branch).

## Task 2 — Verify: pub get

Run (from `app/`):

```
flutter pub get
```

Expect success.

## Task 3 — Verify: analyze

Run (from `app/`):

```
flutter analyze lib test
```

Expect **0 issues**. (Use `analyze lib test`, not bare `analyze` — the gitignored `app/test_app/` scaffold produces false errors otherwise, per MEMORY.)

## Task 4 — Verify: test

Run (from `app/`):

```
flutter test test/unit/theme/app_colors_ext_test.dart
```

Expect all green. Then run the full suite to confirm no regressions:

```
flutter test
```

Expect all green.

## Task 5 — A6 spec index

`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` is a per-screen table. Issue #301 is a theme-infrastructure unit-test addition that maps to no screen row and changes no screen's Code/V-Spec/V-Art status. **No index.md update required** — note this explicitly in the PR body so the reviewer knows it was considered, not skipped.

## Task 6 — A7 drift check

```
git fetch origin
```

```
git log origin/master..HEAD --oneline
```

Only the single commit from this branch should appear. If any foreign commit is visible → STOP and return `STOPPED foreign commits on master`.

## Task 7 — A8 commit + push + PR

Stage and commit:

```
git add app/test/unit/theme/app_colors_ext_test.dart docs/superpowers/plans/2026-06-24-issue-301-app-colors-ext-tests.md
```

```
git commit -m "test(theme): add unit tests for AppColorsExt (copyWith, lerp, context.colors)

Covers AppColorsExt.light()/dark() factories, copyWith field-override
smoke test, lerp at t=0/1/midpoint + null-other branch, and the
context.colors extension (buildAppTheme registration + light() fallback).

Closes #301

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

Push:

```
git push -u origin agent/issue-301-app-colors-ext-tests
```

Create PR:

```
gh pr create --repo Maortz/allergy-detector --base master --title "test(theme): unit tests for AppColorsExt ThemeExtension (#301)" --body "<body below>"
```

PR body:

```
Closes #301

## Summary
Adds dedicated unit-test coverage for `AppColorsExt` (added in #300), which previously had none.

New file `app/test/unit/theme/app_colors_ext_test.dart` covers:
- `light()` / `dark()` factories return non-null instances with correct sample values, and differ for theme-aware tokens.
- `copyWith` — overriding one field leaves the rest unchanged; no-arg copy is equivalent.
- `lerp` — `t=0.0` → source, `t=1.0` → target, midpoint interpolated, `null` other returns `this`.
- `AppColorsContext.colors` — returns the extension registered by `buildAppTheme()`, and falls back to `AppColorsExt.light()` when none is registered.

Test-only change; no production code modified.

## Spec index
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` is a per-screen table; this theme-infrastructure test maps to no screen row, so no Code/V-Spec/V-Art update applies.

## Verification
- `flutter analyze lib test` — 0 issues
- `flutter test` — all green
```

## Task 8 — A9 comment + release claim

Comment on the issue linking the PR:

```
gh issue comment 301 --repo Maortz/allergy-detector --body "PR opened: <PR_URL>"
```

Release the claim:

```
gh issue edit 301 --repo Maortz/allergy-detector --remove-label agent-in-progress
```

## Return

`PR_OPENED <PR_URL>`
