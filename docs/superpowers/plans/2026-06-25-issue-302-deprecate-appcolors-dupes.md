# Implementation Plan — Issue #302: Deprecate duplicated AppColors static consts

## Goal

After PR #300 introduced `AppColorsExt` (theme-aware, light+dark) alongside the
legacy light-only `AppColors` static consts, ~32 tokens now exist in BOTH places
(two sources of truth). This issue removes the duplication risk by:

1. Migrating every remaining production call site off the duplicated
   `AppColors.<token>` static consts to the theme-aware `context.colors.<token>`.
2. Migrating test references off the deprecated consts (value-pinning tests
   re-point at `AppColorsExt.light()`).
3. Marking the duplicated static consts `@Deprecated('Use context.colors.X instead')`.
4. Verifying `flutter analyze lib test` reports **0 issues** (no
   `deprecated_member_use_from_same_package` warnings remain) and all tests green.

The duplicated light values are **identical** to `AppColorsExt._light` values
(verified token-by-token), so rendered light-mode appearance is unchanged — this
is a pure refactor. Migrating to `context.colors.*` additionally fixes dark-mode
for these widgets as a free side-effect.

The branch `agent/issue-302-deprecate-appcolors-dupes` is already created (A3 done).
Execution starts at Task 1.

## Duplicated token set (the 32 consts to deprecate)

These exist in `AppColors` (light-only static) AND `AppColorsExt` (light+dark):

```
borderSubtle, iconMuted, slate600, primaryTint, primaryTintBorder,
frostedSurface, closeButtonOverlay, cameraSurfaceUnavailable, scanFrame,
safeBackground, safeText, cautionBackground, cautionText, cautionHighlight,
avoidBackground, avoidText, avoid, onAvoid, success, onSuccess, warning,
warningContainer, chipDisplayBg, chipDisplayBorder, chipDetectedBg,
chipDetectedBorder, chipDetectedFg, chipCautionBg, chipCautionBorder,
chipCautionFg, destructiveSubtle, onDestructiveSubtle
```

**NOT in scope** (M3 ColorScheme roles / no `AppColorsExt` twin — keep as static
consts, do NOT deprecate): `primary`, `onPrimary`, `surfaceContainerLowest`,
`surfaceContainerHigh`, `onSurfaceVariant`, `error`, `onError`, `background`,
`secondary`, etc.

---

## Task 1 — Migrate `lib/widgets/status_badge.dart`

The `switch` is inside `build(BuildContext context)`. Replace the six
`AppColors.*` status tokens with `context.colors.*`.

Edit lines 19-33 in the switch:
- `AppColors.safeBackground` → `context.colors.safeBackground`
- `AppColors.safeText` → `context.colors.safeText`
- `AppColors.cautionBackground` → `context.colors.cautionBackground`
- `AppColors.cautionText` → `context.colors.cautionText`
- `AppColors.avoidBackground` → `context.colors.avoidBackground`
- `AppColors.avoidText` → `context.colors.avoidText`

Verify: `flutter analyze lib/widgets/status_badge.dart` — 0 issues.

## Task 2 — Migrate `lib/widgets/contribution_status_pill.dart`

Identical pattern (switch inside `build(BuildContext context)`), lines 19-30.
Replace the same six status tokens with `context.colors.*`.

## Task 3 — Migrate `lib/widgets/all_clear_banner.dart`

Check the build method has `BuildContext context` (it does — StatelessWidget
`build`). Replace at lines 25, 27, 35, 49, 56:
- `AppColors.safeBackground` → `context.colors.safeBackground`
- `AppColors.safeText` (4 occurrences) → `context.colors.safeText`

If any of these are inside a `const` Widget literal, drop `const` on that literal
(the surrounding `Container`/`Icon`). Read the file first to confirm exact context.

## Task 4 — Migrate `lib/widgets/brand_card.dart`

Lines 87, 95: `AppColors.safeText` → `context.colors.safeText`. Confirm the
ternaries are inside a method with `context` in scope; if they are in a helper
without `context`, thread `context` into that helper (read file first).

## Task 5 — Migrate `lib/widgets/state_view.dart`

Line 42: `iconColor ?? AppColors.iconMuted` → `iconColor ?? context.colors.iconMuted`.
Confirm `context` is in scope at that line (read file first).

## Task 6 — Migrate `lib/widgets/allergen_card.dart`

Line 57: `const unselectedBorderColor = AppColors.borderSubtle;`
Change to `final unselectedBorderColor = context.colors.borderSubtle;`
(`context` is available — it's inside `build(BuildContext context)`).
Leave `const selectedBorderColor = AppColors.primary;` unchanged (`primary` is
NOT deprecated, stays a static const).

## Task 7 — Migrate `lib/screens/admin_destination_screen.dart`

Lines 126, 128: confirm `context` in scope (read file).
- `AppColors.primaryTint` → `context.colors.primaryTint`
- `AppColors.primaryTintBorder` → `context.colors.primaryTintBorder`
If inside a `const` BoxDecoration/Container, drop the `const`.

## Task 8 — Migrate `lib/screens/drawer_user_screen.dart`

Helper methods `_buildHeader()`, `_buildRow(_DrawerRow row)`, `_buildLogout()`,
`_buildVersion(String version)` do NOT take `context`. Thread `context` through:

1. Change signatures to:
   - `Widget _buildHeader(BuildContext context)`
   - `Widget _buildRow(BuildContext context, _DrawerRow row)`
   - `Widget _buildLogout(BuildContext context)`
   - `Widget _buildVersion(BuildContext context, String version)`
2. Update their call sites inside `build(BuildContext context)` accordingly
   (read the file to find each call; pass `context` as the first arg).
3. Replace tokens:
   - line ~137 `AppColors.iconMuted` → `context.colors.iconMuted` (inside the
     `const CircleAvatar` — drop `const` on the `CircleAvatar` since its child
     now references a non-const color)
   - line ~186 `selectedTileColor: AppColors.primaryTint` → `context.colors.primaryTint`
   - line ~207 `backgroundColor: AppColors.destructiveSubtle` → `context.colors.destructiveSubtle`
   - line ~208 `foregroundColor: AppColors.onDestructiveSubtle` → `context.colors.onDestructiveSubtle`
   - line ~230 `AppColors.iconMuted` → `context.colors.iconMuted`

Read the full file first; adjust `const` keywords on any literal that now holds a
runtime color. Verify analyze on the file is clean afterward.

## Task 9 — Migrate `lib/screens/favorites_screen.dart`

Line 194: `AppColors.avoid` → `context.colors.avoid`. Confirm `context` in scope
(read file; thread `context` into the helper if needed).

## Task 10 — Migrate `lib/screens/search_screen.dart`

Lines 284, 286, 292 (offline/stale banner):
- `AppColors.warningContainer` → `context.colors.warningContainer`
- `AppColors.warning` (x2) → `context.colors.warning`
Confirm `context` in scope; drop `const` on any enclosing literal as needed.

## Task 11 — Migrate `lib/utils/app_toast.dart`

`AppToast.success(BuildContext context, ...)` has `context`. Lines 31-32:
- `background: AppColors.success` → `background: context.colors.success`
- `foreground: AppColors.onSuccess` → `foreground: context.colors.onSuccess`
Leave `error`/`info` toasts' `AppColors.error/onError/primary/onPrimary` unchanged
(not deprecated). Add the `app_colors.dart` import already present — keep it (still
used for `AppColors.error` etc.).

## Task 12 — `lib/screens/add_product_screen.dart`

Line 534 is a **code comment** (`// ... (AppColors.avoid).`), not a reference.
No code change needed. Deprecation does not flag comments. (No action; listed for
completeness.)

## Task 13 — Migrate test references

Add `@Deprecated` would flag these. Migrate each:

- `test/unit/theme/app_colors_test.dart` — this pins design-token VALUES. Re-point
  the 8 duplicated-token assertions (safeText, cautionText, avoidText,
  safeBackground, cautionBackground, avoidBackground, scanFrame) from
  `AppColors.<token>` to `AppColorsExt.light().<token>`. Keep the non-deprecated
  assertions (`primary`, `primaryContainer`, `onPrimary`, `secondary`,
  `background`, `error`) on `AppColors.*` unchanged. Update the import if needed
  (`AppColorsExt` is in the same `app_colors.dart` file — already imported).
  The pinned values must stay identical (verified equal).
- `test/app_toast_test.dart:42` `AppColors.success` → `AppColorsExt.light().success`
  (or assert against `context.colors.success` if the test pumps a themed app —
  read the test; prefer the minimal change that keeps intent).
- `test/widgets/stat_card_test.dart:16` `AppColors.success` → `AppColorsExt.light().success`.
- `test/widgets/screens/community_screen_test.dart:73` `AppColors.success` → `AppColorsExt.light().success`.
- `test/widgets/screens/admin_navigation_drawer_test.dart:112` `AppColors.primaryTint` → `AppColorsExt.light().primaryTint`.
- `test/widgets/screens/drawer_user_screen_test.dart:79,83,137`
  `destructiveSubtle`/`onDestructiveSubtle`/`primaryTint` → `AppColorsExt.light().<token>`.
- `test/widgets/screens/product_details_screen_test.dart:84,85,172`
  `avoid`/`avoidBackground`/`chipDetectedBg` → `AppColorsExt.light().<token>`.
- `test/widgets/screens/settings_screen_test.dart:215,226,275,434`
  `safeBackground`/`cautionBackground`/`avoidBackground` → `AppColorsExt.light().<token>`.

Read each test file at the cited line before editing to preserve surrounding
intent (some assert widget color == token; `AppColorsExt.light().<token>` yields
the identical Color so assertions still pass). Ensure `AppColorsExt` is imported
in each (same `app_colors.dart` import line; add if absent).

## Task 14 — Add `@Deprecated` annotations to the 32 duplicated consts

In `lib/theme/app_colors.dart`, annotate ONLY the 32 duplicated static consts
(listed above) with:

```dart
@Deprecated('Use context.colors.<token> instead')
static const Color <token> = Color(0x........);
```

Use the exact token name in the message. Keep each const's value and doc comment.
Do NOT deprecate M3 role consts (primary, surface*, error, etc.) or `AppDarkColors`.

## Task 15 — Verify

Run one command at a time (no `&&` chaining):

```
flutter pub get
flutter analyze lib test
flutter test
```

`flutter analyze lib test` must report **0 issues** — specifically no
`deprecated_member_use_from_same_package`. If any remain, a call site was missed:
locate with `grep -rnE "AppColors\.(borderSubtle|iconMuted|...)" lib test` and
migrate it. `flutter test` must be fully green.

If a widget test now fails because a const literal was un-consted, that is
expected to still pass (same runtime value); investigate any real failure before
proceeding.

## Task 16 (A6) — Spec index note

`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` tracks per-screen
status. This refactor changes NO rendered light appearance and flips no
screen's Code/V-Spec/V-Art verdict, so do not change any status cells. If the
file has a changelog/notes section at the bottom, optionally append a one-line
note that #302 deprecated the duplicated `AppColors` consts and migrated remaining
call sites to `context.colors.*`. If there is no such section, skip — do not invent
one. (Read the tail of index.md to decide.)

## Task 17 (A7) — Drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Only this branch's own commit(s) should appear. Foreign commits on master not in
our history → STOP and report (do not build on someone else's work).

## Task 18 (A8) — Commit + PR

```
git add -A
git commit
```

Commit message:
```
refactor(theme): deprecate duplicated AppColors consts, migrate to context.colors (#302)

Migrate all remaining production + test call sites off the light-only
AppColors.<token> static consts (duplicated by AppColorsExt) to the
theme-aware context.colors.<token>, then mark the 32 duplicated consts
@Deprecated. Pure refactor — light values are identical; dark-mode now
adapts for the migrated widgets.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push and open PR:
```
git push -u origin agent/issue-302-deprecate-appcolors-dupes
gh pr create --repo Maortz/allergy-detector --base master \
  --title "refactor(theme): deprecate duplicated AppColors consts (#302)" \
  --body "<body>"
```

PR body must include: `Closes #302`, a change summary (files migrated, 32 consts
deprecated), and analyze/test results (`flutter analyze lib test` 0 issues,
`flutter test` all passing with count).

## Task 19 (A9) — Comment + release claim

```
gh issue comment 302 --repo Maortz/allergy-detector --body "Opened PR <url>"
gh issue edit 302 --repo Maortz/allergy-detector --remove-label agent-in-progress
```

## Staff-level standards (apply throughout)

- Business logic stays out of widgets (this task only touches color tokens).
- Keep `const` wherever the literal is still fully const; only drop `const` on a
  literal that now holds a runtime `context.colors.*` value.
- Idiomatic Dart, correct imports (remove no still-needed import).
- Theme tokens only — no hardcoded `Color(0x...)` introduced in widgets.
- Hebrew RTL-first — do not touch any UI strings.
