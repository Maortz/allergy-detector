# Implementation Plan: issue #183 — replace hardcoded EdgeInsets in theme builders with AppSpacing tokens

**Branch:** `agent/issue-183-theme-spacing-tokens` (already created — execution starts at Task 1)
**Issue:** https://github.com/Maortz/allergy-detector/issues/183
**Area:** fix(theme) — Dart only. `app/lib/theme/app_theme.dart` + `app/test/unit/theme/app_theme_test.dart`.

## Goal

`buildAppTheme()` and `buildDarkAppTheme()` use raw `EdgeInsets` literals for button/input
padding, violating the CLAUDE.md convention that all spacing uses named `AppSpacing` tokens.
Replace every raw `EdgeInsets.symmetric(...)` padding in both builders with the equivalent
`AppSpacing` token, **preserving the exact pixel values**.

## Critical context (read before editing — the issue's token mapping is WRONG)

The issue suggests "`AppSpacing.xl` for 24, `AppSpacing.md` for 16". The first is incorrect
against the actual token table (`app/lib/theme/app_spacing.dart`):

```
xs = 4   sm = 8   gutter = 16   md = 16   lg = 24   xl = 32   margin = 20   chipH = 10
```

- `24` → **`AppSpacing.lg`** (24).  `AppSpacing.xl` is 32 — using it would change the padding.
- `16` → **`AppSpacing.md`** (16).  (`gutter` is also 16; use `md` for consistency with the
  vertical value and the input padding.)

Correctness (preserve pixels) overrides the issue's mistaken suggestion.

### Exact occurrences to replace (6 total — 3 per builder)

`app/lib/theme/app_theme.dart`:

- Light `elevatedButtonTheme` (line 55): `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16)`
- Light `outlinedButtonTheme` (line 64): `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16)`
- Light `inputDecorationTheme.contentPadding` (line 84): `EdgeInsets.symmetric(horizontal: 16, vertical: 16)`
- Dark `elevatedButtonTheme` (line 166): `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16)`
- Dark `outlinedButtonTheme` (line 175): `padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16)`
- Dark `inputDecorationTheme.contentPadding` (line 195): `EdgeInsets.symmetric(horizontal: 16, vertical: 16)`

Mapping:
- `EdgeInsets.symmetric(horizontal: 24, vertical: 16)`
  → `EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md)`
- `EdgeInsets.symmetric(horizontal: 16, vertical: 16)`
  → `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md)`

`AppSpacing` constants are `static const double`, so these `EdgeInsets.symmetric` calls remain
const-constructable.

### Import

`app/lib/theme/app_theme.dart` currently imports only `app_colors.dart` and `app_typography.dart`.
Add `import 'app_spacing.dart';` (relative, same directory — matches existing style).

### Tests

`app/test/unit/theme/app_theme_test.dart` currently asserts only colours/brightness inside
`testWidgets` (the builders pull in google_fonts via `AppTypography`, so assertions run in the
flutter test zone — keep that pattern). Add padding assertions that lock the token wiring + the
preserved pixel values.

`ThemeData.elevatedButtonTheme.style` is a `ButtonStyle`; its `padding` is a
`WidgetStateProperty<EdgeInsetsGeometry?>` — resolve with `.resolve(<WidgetState>{})`.
`InputDecorationTheme.contentPadding` is a plain `EdgeInsetsGeometry?`.

## Tasks

### Task 1 — TDD: add padding assertions first (red)

Edit `app/test/unit/theme/app_theme_test.dart`. Add the import and new tests.

Add to imports:

```dart
import 'package:app/theme/app_spacing.dart';
```

Add this group inside `main()` (after the existing groups):

```dart
  group('theme spacing uses AppSpacing tokens (issue #183)', () {
    EdgeInsetsGeometry? buttonPadding(ButtonStyle? style) =>
        style?.padding?.resolve(<WidgetState>{});

    for (final entry in {
      'light': buildAppTheme,
      'dark': buildDarkAppTheme,
    }.entries) {
      final name = entry.key;
      final build = entry.value;

      testWidgets('$name elevated button padding is lg/md tokens',
          (tester) async {
        expect(
          buttonPadding(build().elevatedButtonTheme.style),
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        );
      });

      testWidgets('$name outlined button padding is lg/md tokens',
          (tester) async {
        expect(
          buttonPadding(build().outlinedButtonTheme.style),
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        );
      });

      testWidgets('$name input contentPadding is md/md tokens', (tester) async {
        expect(
          build().inputDecorationTheme.contentPadding,
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        );
      });
    }
  });
```

Run `flutter test test/unit/theme/app_theme_test.dart` — the new assertions hold *numerically*
even before the lib change (24==lg, 16==md), so they may already pass. That's acceptable: their
purpose is to lock the values so a future raw-literal regression with a wrong number fails. The
real enforcement of "tokens, not literals" is Task 3's analyze/grep check. Proceed to Task 2
regardless.

### Task 2 — Replace literals with tokens (lib change)

Edit `app/lib/theme/app_theme.dart`:

1. Add the import after the existing theme imports:

```dart
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
```

2. Replace all four button paddings (light lines ~55, 64; dark ~166, 175):

```dart
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
```

   (Add `const` — the literal was non-const before; the token form is const-constructable, which
   is the preferred idiom.)

3. Replace both input `contentPadding`s (light ~84, dark ~195):

```dart
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
```

Leave every other line (colours, borderRadius, etc.) untouched — the issue scopes this to the raw
`EdgeInsets` paddings only. `BorderRadius.circular(n)` literals are out of scope (not `EdgeInsets`,
and there is no spacing token for radii).

### Task 3 — Verify

Run from `app/`, one command at a time (no `&&`), flutter on PATH
(`export PATH="$PATH:/sdks/flutter/bin"`):

1. `flutter pub get` — succeeds.
2. `flutter analyze lib test` — **0 issues**.
3. `flutter test` — all green.
4. Confirm no raw `EdgeInsets` padding literals remain in the file:
   `grep -nE "EdgeInsets\.symmetric\((horizontal|vertical): [0-9]" app/lib/theme/app_theme.dart`
   → must print nothing.

### Task 4 — A6 spec-table update — N/A

`docs/.../index.md` tracks **screen** implementations. This is a theme-layer token cleanup
touching no screen and changing no screen's Code/V-Spec/V-Art status — skip A6 explicitly.

### Task 5 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Only this branch's commit(s). Foreign commits → STOP.

### Task 6 — A8 commit + PR

```
git add app/lib/theme/app_theme.dart app/test/unit/theme/app_theme_test.dart docs/superpowers/plans/2026-06-15-issue-183-theme-spacing-tokens.md
git commit -m "<message>"
```

Commit message:

```
fix(theme): use AppSpacing tokens for theme padding (#183)

Replace the raw EdgeInsets.symmetric literals in the elevated/outlined
button and input-decoration themes of buildAppTheme and buildDarkAppTheme
with AppSpacing tokens (24 -> AppSpacing.lg, 16 -> AppSpacing.md),
preserving the exact pixel values and matching the CLAUDE.md
named-spacing-token convention. Note: the issue's suggested xl-for-24
mapping was wrong (xl is 32); lg is the 24 token. Adds tests locking the
resolved button/input padding to the token values.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push and open the PR:

```
git push -u origin agent/issue-183-theme-spacing-tokens
gh pr create --repo Maortz/allergy-detector --base master --title "fix(theme): replace hardcoded EdgeInsets in theme builders with AppSpacing tokens (#183)" --body "<body>"
```

PR body: `Closes #183`, change summary (6 paddings across both builders → `lg`/`md` tokens,
pixels preserved), the corrected token mapping note (issue said `xl` for 24 but `xl`=32, so `lg`
is correct), new tests, and `flutter analyze`/`flutter test` results.

### Task 7 — A9 comment + release claim

```
gh issue comment 183 --repo Maortz/allergy-detector --body "Opened PR <url> — <one-line summary>."
gh issue edit 183 --repo Maortz/allergy-detector --remove-label agent-in-progress
```
