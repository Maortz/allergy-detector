# Plan: Allergen management screen shows empty/error state instead of blank (#256)

Branch `agent/issue-256-allergen-mgmt-empty-state` is already created. Execution starts at the first code task.

## Root cause (investigated)

`AllergenManagementScreen` (`app/lib/screens/allergen_management_screen.dart`) is purely
presentational — it renders `widget.allergens` (injected, per the app's service-injection
architecture) in a `GridView.builder`. When the catalog is empty it builds a `GridView` with
`itemCount: 0` → a completely blank body, no message.

In `main.dart` `_AppShellState._loadProfileAndAllergens`, a Supabase allergen-fetch failure is
only surfaced (via `_buildErrorScreen`) **when onboarding is not yet completed** (L253:
`if (_allergenLoadError != null && !_profile.hasCompletedOnboarding)`). For a returning user
who has completed onboarding, a failed/empty fetch is swallowed: `_allergens` stays `[]` and is
passed down to `AllergenManagementScreen`, which then renders blank. This matches the report
("Screen is blank — no list items, no empty state message", "Always" on Android).

Catalog display (AC1) and selected-highlight (AC2) already work when allergens are present
(`AllergenCard` with `isSelected`). The missing piece is AC3: an empty/error state instead of a
blank screen. The reusable `StateView` widget (`app/lib/widgets/state_view.dart`) provides the
icon+title+message pattern used by the search/scan screens.

## Approach

In `AllergenManagementScreen.build`, when `widget.allergens.isEmpty`, render a centered
`StateView` (icon `Icons.error_outline`, a Hebrew title + message explaining the catalog could
not be loaded and to check the connection) in place of the counter + grid + footer. Otherwise
render the existing grid layout unchanged. No new dependency, no self-fetch (keeps the
injection architecture; the screen has no `SupabaseClient` and no retry channel).

## Tasks

### Task 1 — Render an empty/error state when the catalog is empty

In `app/lib/screens/allergen_management_screen.dart`:
- Import `../widgets/state_view.dart`.
- In `build`, after the `AppBar`, branch the `body`:
  - `widget.allergens.isEmpty` → `const StateView(icon: Icons.error_outline, title: 'לא ניתן לטעון את רשימת האלרגנים', message: 'בדקו את החיבור לאינטרנט ונסו שוב מאוחר יותר.')`.
  - else → the existing `Column` (counter + Expanded grid + footer).
- Extract the existing populated layout into a `_buildList()` method for readability.

### Task 2 — Tests

In `app/test/widgets/screens/allergen_management_screen_test.dart`:
- Add a test: with `allergens: const []`, the screen renders a `StateView` (and the
  empty-state title text), not a blank body — assert `find.byType(StateView)` /
  `find.text('לא ניתן לטעון את רשימת האלרגנים')` is found, and the counter
  ('אלרגנים פעילים: 0') is NOT shown.
- Keep all existing tests (they pass a non-empty list).
- Add a `buildSubject` overload or inline widget for the empty case (the existing helper
  hardcodes the 3-item list).

### Task 3 — Verify (one command at a time)

```
cd app
flutter pub get
flutter analyze lib test
flutter test
```

analyze 0 issues; tests green.

### Task 4 — A6 spec index update

Update the relevant Settings/AllergenManagement note in
`docs/superpowers/specs/2026-05-19-stitch-screens/index.md` to record #256 (empty/error
`StateView` when the injected catalog is empty — no more blank screen).

### Task 5 — A7 drift check

```
git fetch origin
git log origin/master..HEAD --oneline
```

Foreign commits → STOP.

### Task 6 — A8 commit + PR

Footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`; push; `gh pr create --base master`,
body `Closes #256`, root-cause summary, analyze/test results.

### Task 7 — A9 comment + release

Comment on #256 linking PR; `gh issue edit 256 --repo Maortz/allergy-detector --remove-label agent-in-progress`.
