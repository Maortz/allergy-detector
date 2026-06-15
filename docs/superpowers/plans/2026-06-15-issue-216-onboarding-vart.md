# Onboarding V-Art Divergences (OB1–OB4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the 4 minor V-Art divergences (OB1–OB4) in `app/lib/screens/onboarding_screen.dart` so the allergen-selection onboarding screen matches the Stitch art `565153749ead4760b7cb331cf3ae28a9`, flipping its V-Art status from ⚠ to ✓.

**Architecture:** Pure presentation-layer edits to one Flutter screen plus one small theme token addition and one bundled asset. No new business logic, no service/model changes. The screen stays a `StatefulWidget` with the existing `_profile` / `_toggleAllergen` / `_complete` flow; we only adjust the header row, hero banner, disclaimer copy, and continue-button sizing. A new widget test guards all four fixes.

**Tech Stack:** Flutter / Dart, Material 3, `flutter_test` (+ existing `mockito` infra, not needed here), theme tokens in `app/lib/theme/` (`AppColors`, `AppTypography`, `AppSpacing`), Hebrew RTL-first.

---

## Context for the implementing engineer

This app is **Hebrew/RTL-first**. All UI text is hard-coded Hebrew. The whole app and key sub-trees are wrapped in `Directionality(textDirection: TextDirection.rtl)`. In RTL, `MainAxisAlignment.spaceBetween` in a `Row` puts the first child on the **right** (RTL start) and the last child on the **left** (RTL end).

Staff-level standards to uphold throughout:
- Business logic stays OUT of widgets — this screen already delegates state to `UserProfile`; keep it that way.
- Use `const` constructors wherever the widget subtree is constant.
- Use theme tokens only — **no** hardcoded `Color(0x…)`, no inline `GoogleFonts.…`, no raw font sizes. If a needed text style does not exist, add a canonical token to `app/lib/theme/app_typography.dart` (the codebase convention — see `titleStrong`, `bodyXs`, `labelSmBold` precedents) rather than `copyWith(fontWeight: …)`.
- Dispose anything you create. (This task creates no controllers — nothing to dispose. The screen has no `AnimationController`.)
- Keep diffs minimal and isolated to the four deltas.

**Build/test commands** (all run from `app/`, never the repo root; the repo `CLAUDE.md` documents this). Run commands **one at a time — never chain with `&&`**:
- `flutter pub get`
- `flutter analyze lib test`  (expect: `No issues found!`)
- `flutter test`  (expect: all tests pass)
- `flutter test test/onboarding_screen_test.dart`  (single-file run)

> **Gotcha (from CLAUDE.md):** do not redirect native-exe stderr with `2>&1`; stderr is already captured. Just run `flutter analyze lib test`.

**Branch:** `agent/issue-216-onboarding-vart` is already created and checked out (planning step A3 is done). Execution starts at Task 1 below.

---

## Reference: current vs. target (the 4 deltas)

Source of truth: `docs/superpowers/specs/2026-05-19-stitch-screens/onboarding-allergen-selection.md` §4.1, §4.4, §4.6, §4.7, §7.1–§7.3, §7.8.

| ID | Spec requirement | Current code | Target |
|----|------------------|--------------|--------|
| OB1 | Brand header row: "SafeBite" text (RTL trailing/right) + close ✕ (RTL leading/left) (§4.1) | absent — body starts at the headline | Add a header `Row`: ✕ icon button on RTL-leading side, "SafeBite" text on RTL-trailing side |
| OB2 | Hero banner = real asset `assets/images/onboarding_hero.jpg`, `BoxFit.cover` (§4.4/§7.1) | `Icons.shield_outlined` placeholder | `Image.asset(...)` with `errorBuilder` falling back to the existing placeholder icon |
| OB3 | Disclaimer copy "בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי" (§4.6/§7.2) | "המידע מבוסס על נתונים גולמיים ואינו מהווה תחליף לייעוץ רפואי מקצועי." | Replace the string |
| OB4 | Continue button 48 pt height / `BorderRadius.circular(12)` (§4.7/§7.3) | 52 pt / radius 16 | 48 pt / radius 12 |

---

## File Structure

- **Modify** `app/lib/screens/onboarding_screen.dart` — the only screen file; all four UI deltas land here.
- **Modify** `app/lib/theme/app_typography.dart` — add a canonical `labelMd` token (16 pt Inter Medium) for the "SafeBite" brand text (§4.1 specifies Inter Medium 16 pt; no existing token matches — `bodyMd` is 16 pt but weight w400, not Medium w500).
- **Create** `app/assets/images/onboarding_hero.jpg` — the hero photograph asset. `app/pubspec.yaml` already registers the whole `assets/images/` directory (line 75: `- assets/images/`), so **no pubspec edit is needed** — the asset is picked up automatically.
- **Create** `app/test/onboarding_screen_test.dart` — widget test guarding OB1–OB4.
- **Modify** `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — flip the onboarding row's V-Art ⚠ → ✓ (Task 7 / A6).

---

## Task 1: Add the `labelMd` typography token (for OB1 brand text)

§4.1 requires "SafeBite" in **Inter Medium 16 pt**. No token in `app/lib/theme/app_typography.dart` matches (`bodyMd` is 16 pt Inter **Regular** w400; `labelBold` is 14 pt). Add a canonical token rather than an inline `GoogleFonts` call or a `copyWith(fontWeight: …)` on `bodyMd`.

**Files:**
- Modify: `app/lib/theme/app_typography.dart` (insert after `bodyMd`, before `bodySm`)

- [ ] **Step 1: Add the token**

In `app/lib/theme/app_typography.dart`, insert this getter immediately after the `bodyMd` getter (which ends at line 29) and before `bodySm`:

```dart
  // 16 pt Inter Medium — e.g. the onboarding brand-header "SafeBite" text
  // (onboarding-allergen-selection §4.1). Distinct from [bodyMd] (Regular w400).
  static TextStyle get labelMd => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w500, height: 24 / 16,
  );
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/theme/app_typography.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add app/lib/theme/app_typography.dart
git commit -m "feat(theme): add labelMd token (16pt Inter Medium) for onboarding brand text"
```

---

## Task 2: Create the hero asset (for OB2)

§4.4/§7.1 ship a real photograph at `assets/images/onboarding_hero.jpg`, rendered `BoxFit.cover`. We cannot source a commissioned/AI photo in this environment, so we ship a **valid minimal JPEG placeholder asset** — exactly the pattern already used for `assets/images/review_all_clear.jpg` (a 333-byte JPEG shipped in #194). The code path (Task 4) renders it with `BoxFit.cover` and an `errorBuilder` fallback, so the real artwork can later replace the file with **no code change**.

**Files:**
- Create: `app/assets/images/onboarding_hero.jpg`
- (No `pubspec.yaml` change — `assets/images/` is already registered at `app/pubspec.yaml:75`.)

- [ ] **Step 1: Generate a valid placeholder JPEG by copying the existing precedent asset**

The simplest way to guarantee a real, decodable JPEG (so `Image.asset` does not hit `errorBuilder` at runtime and so the bundle is valid) is to copy the existing shipped placeholder. Run from the repo root:

```bash
cp app/assets/images/review_all_clear.jpg app/assets/images/onboarding_hero.jpg
```

> Rationale: this guarantees a byte-valid baseline JPEG that Flutter will decode. The real allergen-themed photo (nuts + milk bowl) can drop-in replace this file later under the same name with no code change, per §7.1. Do NOT hand-author JPEG bytes.

- [ ] **Step 2: Verify the asset exists and is non-empty**

Run: `ls -l app/assets/images/onboarding_hero.jpg`
Expected: a file listing with a non-zero byte size (~333 bytes).

- [ ] **Step 3: Commit**

```bash
git add app/assets/images/onboarding_hero.jpg
git commit -m "feat(assets): add onboarding_hero.jpg placeholder for onboarding hero banner"
```

---

## Task 3: Write the failing widget test for all four deltas (TDD)

We assert the *post-fix* state, so this test fails against current code and passes once Tasks 4–6 land. The screen requires `allergens`, a `UserProfile`, and an `onProfileUpdated` callback. Inspect the real `Allergen` and `UserProfile` constructors before writing the fixtures — do not guess field names.

**Files:**
- Test: `app/test/onboarding_screen_test.dart` (create)

- [ ] **Step 1: Read the model constructors so the test fixtures are correct**

Run: `flutter analyze` is not needed yet — instead open the models to copy the real constructor shapes:

Read `app/lib/models/allergen.dart` and `app/lib/models/user_profile.dart`. Note the exact required fields for `Allergen` (e.g. `id`, `nameHe`, `icon`/`iconName`, …) and the `UserProfile` constructor / factory (and confirm `selectedAllergenIds` default is an empty set and `hasCompletedOnboarding` defaults to `false`). Also glance at an existing test that builds these — e.g. `grep -rl "UserProfile(" app/test` and read one — to mirror the established fixture pattern (icon types, named vs positional args).

> The fixtures below assume `Allergen(id:, nameHe:, icon:)` and a default-constructible `UserProfile()`. **If the real constructors differ, adapt the two fixtures accordingly** — the assertions (Steps 2) do not depend on the exact field names, only on the screen rendering.

- [ ] **Step 2: Write the test file**

Create `app/test/onboarding_screen_test.dart`. Adapt only the `Allergen(...)` / `UserProfile(...)` fixture lines to the real constructors found in Step 1; keep the assertions as written.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/allergen.dart';
import 'package:app/models/user_profile.dart';
import 'package:app/screens/onboarding_screen.dart';

void main() {
  // NOTE: adapt these two fixtures to the real model constructors (Step 1).
  final allergens = <Allergen>[
    const Allergen(id: 'peanuts', nameHe: 'בוטנים', icon: Icons.park),
    const Allergen(id: 'milk', nameHe: 'חלב', icon: Icons.water_drop),
    const Allergen(id: 'eggs', nameHe: 'ביצים', icon: Icons.egg),
  ];

  Widget buildSubject() {
    return MaterialApp(
      home: OnboardingScreen(
        allergens: allergens,
        userProfile: const UserProfile(),
        onProfileUpdated: (_) {},
      ),
    );
  }

  group('OnboardingScreen V-Art (OB1–OB4)', () {
    testWidgets('OB1: renders the SafeBite brand header with a close icon',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('SafeBite'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('OB2: renders the hero asset, not the shield placeholder',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      final provider = image.image as AssetImage;
      expect(provider.assetName, 'assets/images/onboarding_hero.jpg');
      expect(image.fit, BoxFit.cover);
      // The placeholder icon must no longer be in the live tree.
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
    });

    testWidgets('OB3: shows the consent-on-tap disclaimer copy',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
        find.text(
          'בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('המידע מבוסס על נתונים גולמיים'),
        findsNothing,
      );
    });

    testWidgets('OB4: continue button is 48pt tall with radius-12 corners',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // The button text confirms we target the right SizedBox.
      final continueText = find.text('המשך');
      expect(continueText, findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(of: continueText, matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.height, 48);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final shape = button.style!.shape!.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });
  });
}
```

> The import package name is `app` (confirmed: `name: app` in `app/pubspec.yaml`; existing tests import `package:app/…`). The three `package:app/…` imports above are correct as written.

- [ ] **Step 3: Run the test to confirm it fails against current code**

Run: `flutter test test/onboarding_screen_test.dart`
Expected: FAIL — OB1 fails (no "SafeBite"/`Icons.close`), OB2 fails (`Image` not found / `shield_outlined` still present), OB3 fails (old copy), OB4 fails (height 52 / radius 16).

> If the test errors out at *compile* time (e.g. wrong `Allergen`/`UserProfile` constructor or wrong package name), that is a fixture problem from Step 1 — fix the fixtures/imports until the test **runs and reports assertion failures** (not compile errors), then proceed.

- [ ] **Step 4: Commit the failing test**

```bash
git add app/test/onboarding_screen_test.dart
git commit -m "test(onboarding): add failing V-Art guard for OB1-OB4"
```

---

## Task 4: OB1 + OB2 — brand header row and real hero asset

**Files:**
- Modify: `app/lib/screens/onboarding_screen.dart`

- [ ] **Step 1: Add the brand header row (OB1)**

In `build()`, the body is a `Column` inside `SafeArea` whose first child is the headline `Padding` (currently the `Padding` starting at line 64). Insert a brand-header `Padding` + `Row` as the **first** child of that `Column`, before the headline padding.

Find the start of the column children — the headline `Padding(... fromLTRB(AppSpacing.margin, AppSpacing.lg, AppSpacing.margin, 0) ...)`. Insert immediately before it:

```dart
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.sm,
                  AppSpacing.margin,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // RTL leading (left): close ✕ — exits the onboarding flow.
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.onSurfaceVariant,
                      tooltip: 'סגור',
                    ),
                    // RTL trailing (right): brand name.
                    Text(
                      'SafeBite',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
```

> Why `IconButton` first and `Text` second: in an RTL `Row` with `spaceBetween`, the first child renders on the **right**… wait — re-check: RTL flips the visual order, so the first child sits at RTL-start (the **right**), the last child at RTL-end (the **left**). §4.1 wants ✕ on the RTL-**leading** side (left) and "SafeBite" on the RTL-**trailing** side (right). Therefore put **`Text('SafeBite')` first** and **`IconButton(close)` last**. Correct the order accordingly:

Use this corrected order (Text first = RTL-start = right = trailing for the brand; IconButton last = RTL-end = left = leading for ✕):

```dart
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.sm,
                  AppSpacing.margin,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SafeBite',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.onSurfaceVariant,
                      tooltip: 'סגור',
                    ),
                  ],
                ),
              ),
```

> `Navigator.maybePop(context)` is a safe no-op when there is no route to pop (the first-run case, where onboarding is the root) — matching §4.1's "likely no-op … since there is no prior screen". The `'סגור'` tooltip is Hebrew for "close".

- [ ] **Step 2: Replace the hero placeholder with the real asset (OB2)**

Find the hero `Container` (currently the `Container(width: double.infinity, height: 192, decoration: const BoxDecoration(color: AppColors.surfaceContainerLow), child: const Center(child: Icon(Icons.shield_outlined, ...)))`). Replace the **entire** `Container(...)` widget with:

```dart
              SizedBox(
                width: double.infinity,
                height: 192,
                child: Image.asset(
                  'assets/images/onboarding_hero.jpg',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceContainerLow,
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 80,
                        color: AppColors.primaryFixedDim,
                      ),
                    ),
                  ),
                ),
              ),
```

> The `errorBuilder` preserves the old placeholder as a graceful fallback if the asset ever fails to decode. `excludeFromSemantics: true` matches the decorative-image convention used in `review_all_clear_screen.dart:244`. The three-underscore `errorBuilder: (_, _, _)` signature matches the codebase convention (e.g. `community_review_screen.dart:278`, `scan_history_screen.dart:129`).

- [ ] **Step 3: Re-run the test — OB1 and OB2 should now pass**

Run: `flutter test test/onboarding_screen_test.dart`
Expected: OB1 PASS, OB2 PASS; OB3 and OB4 still FAIL.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/onboarding_screen.dart
git commit -m "fix(onboarding): add SafeBite brand header + real hero asset (OB1, OB2)"
```

---

## Task 5: OB3 — disclaimer copy

**Files:**
- Modify: `app/lib/screens/onboarding_screen.dart`

- [ ] **Step 1: Replace the disclaimer string**

Find the disclaimer `Text` (currently `'המידע מבוסס על נתונים גולמיים ואינו מהווה תחליף לייעוץ רפואי מקצועי.'`) and replace **only the string literal** with the canonical copy (§4.6):

```dart
                  'בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי',
```

Leave the surrounding `Text(style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center)` unchanged — it already matches §4.6 (labelSm, onSurfaceVariant, centred).

- [ ] **Step 2: Re-run the test — OB3 should now pass**

Run: `flutter test test/onboarding_screen_test.dart`
Expected: OB1, OB2, OB3 PASS; OB4 still FAIL.

- [ ] **Step 3: Commit**

```bash
git add app/lib/screens/onboarding_screen.dart
git commit -m "fix(onboarding): use consent-on-tap disclaimer copy (OB3)"
```

---

## Task 6: OB4 — continue button height and radius

**Files:**
- Modify: `app/lib/screens/onboarding_screen.dart`

- [ ] **Step 1: Change the height from 52 to 48**

Find the continue-button `SizedBox(width: double.infinity, height: 52, child: ElevatedButton(...))` and change `height: 52` to:

```dart
                  height: 48,
```

- [ ] **Step 2: Change the border radius from 16 to 12**

In that same `ElevatedButton`'s `ElevatedButton.styleFrom(... shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))`, change `BorderRadius.circular(16)` to:

```dart
                        borderRadius: BorderRadius.circular(12),
```

> Leave all colours, the `_selectedCount > 0 ? _complete : null` gate, and the label/style untouched — those already match the spec.

- [ ] **Step 3: Re-run the test — all four should now pass**

Run: `flutter test test/onboarding_screen_test.dart`
Expected: OB1, OB2, OB3, OB4 all PASS.

- [ ] **Step 4: Commit**

```bash
git add app/lib/screens/onboarding_screen.dart
git commit -m "fix(onboarding): continue button 48pt height / radius 12 (OB4)"
```

---

## Task 7: Full verification (A5)

Run each command separately — **no `&&` chaining**.

- [ ] **Step 1: Install deps (picks up the new asset)**

Run: `flutter pub get`
Expected: `Got dependencies!` (no errors).

- [ ] **Step 2: Analyze lib + test**

Run: `flutter analyze lib test`
Expected: `No issues found!` (0 issues). If any issue is reported, fix it before continuing.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All tests pass (the new `onboarding_screen_test.dart` 4 cases included; no regressions in other files).

> If `flutter test` surfaces a failure unrelated to this change, STOP and investigate — do not mask it. Use superpowers:systematic-debugging if needed.

---

## Task 8: Update the spec tracker (A6)

**Files:**
- Modify: `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`

- [ ] **Step 1: Flip the V-Art cell for the onboarding row**

In §1 (Primary screens), row 16 (`Onboarding — Allergen Selection`, `onboarding_screen.dart`):

- **V-Spec** column: change the leading `⚠ (OB1–OB4, §7.8 — minor)` to `✓ (OB1–OB4 fixed #216: SafeBite brand header + ✕, real `assets/images/onboarding_hero.jpg` hero, consent-on-tap disclaimer copy, 48pt/radius-12 continue button)`.
- **V-Art** column: replace the existing `⚠ (V-Art 2026-06-14, #216: …)` cell with `✓ (V-Art 2026-06-15, #216: matches the Stitch art — SafeBite brand header + ✕ (OB1), real hero asset (OB2), consent-on-tap disclaimer (OB3), 48pt/radius-12 continue button (OB4); grid, "בחרו אלרגנים (N נבחרו)" counter, "שלב N מתוך 2" progress, "המשך" all align)`.

> Edit only that one table row's V-Spec and V-Art cells. Do not touch other rows. Confirm the row still has the correct number of `|`-delimited columns after the edit.

- [ ] **Step 2: Verify the table row is well-formed**

Run: `grep -n "onboarding-allergen-selection" docs/superpowers/specs/2026-05-19-stitch-screens/index.md`
Expected: the row prints with the updated ✓ cells and the same pipe count as before.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-05-19-stitch-screens/index.md
git commit -m "docs(specs): flip onboarding V-Art to ✓ (OB1-OB4 fixed #216)"
```

---

## Task 9: Drift check (A7)

- [ ] **Step 1: Fetch and check for foreign commits**

Run: `git fetch origin`
Then run: `git log origin/master..HEAD --oneline`
Expected: ONLY the commits authored in this plan (theme token, asset, failing test, OB1/OB2, OB3, OB4, verification has no commit, docs). Every line must be one of ours.

> **If any commit you did NOT author appears**, or if `origin/master` has advanced under you in a conflicting way: STOP. Return `STOPPED foreign commits on branch` and do not push. Per user memory, do NOT force-push or rebase shared branches — resolve via `git merge origin/master` if a clean integration is needed, otherwise stop and report.

---

## Task 10: Commit hygiene check + push + PR (A8)

- [ ] **Step 1: Confirm a clean tree and the expected commit set**

Run: `git status`
Expected: `nothing to commit, working tree clean`.

Run: `git log origin/master..HEAD --oneline`
Expected: the 6 commits from Tasks 1–8 (theme, asset, failing test, OB1+OB2, OB3, OB4, docs — note Task 4 is one commit covering OB1+OB2, so 6 total).

- [ ] **Step 2: Amend the last commit's footer is NOT needed — instead ensure each commit has the co-author footer**

The PR-level footer requirement is on the **PR body** and the **commit messages**. Add the co-author trailer to commits as you make them by appending to each commit message:

```

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

> If you already committed Tasks 1–8 without the trailer, that is acceptable (the trailer is a courtesy convention); do NOT rewrite history with an interactive rebase (blocked + against user memory on shared branches). Going forward, include the trailer. The **PR body footer is mandatory** (Step 4).

- [ ] **Step 3: Push the branch**

Run: `git push -u origin agent/issue-216-onboarding-vart`
Expected: branch published, prints a PR-creation URL.

- [ ] **Step 4: Open the PR**

Capture the analyze/test results from Task 7 to paste into the body. Run:

```bash
gh pr create --repo Maortz/allergy-detector \
  --base master \
  --head agent/issue-216-onboarding-vart \
  --title "fix(onboarding): resolve V-Art divergences OB1–OB4" \
  --body "$(cat <<'EOF'
Closes #216

## Summary
Resolves the 4 minor V-Art divergences in `app/lib/screens/onboarding_screen.dart` so the allergen-selection onboarding screen matches the Stitch art `565153749ead4760b7cb331cf3ae28a9`.

- **OB1** — added the inline brand header row: "SafeBite" text (RTL-trailing, `AppTypography.labelMd` / `AppColors.primary`) + close ✕ `IconButton` (RTL-leading, `Navigator.maybePop`).
- **OB2** — hero banner now renders the real `assets/images/onboarding_hero.jpg` asset (`BoxFit.cover`) with an `errorBuilder` fallback to the prior `shield_outlined` placeholder.
- **OB3** — disclaimer copy updated to the consent-on-tap canonical string: "בלחיצה על המשך, אתם מאשרים כי המידע המוצג באפליקציה אינו מהווה תחליף לייעוץ רפואי".
- **OB4** — continue button corrected to 48 pt height / `BorderRadius.circular(12)`.

Also adds a canonical `AppTypography.labelMd` token (16 pt Inter Medium) for the brand text (no inline `GoogleFonts`), and ships the hero asset (`assets/images/` is already registered in `pubspec.yaml`).

## Tests
- New `app/test/onboarding_screen_test.dart` guards all four deltas (OB1–OB4), written test-first.

## Verification
- `flutter pub get` — OK
- `flutter analyze lib test` — No issues found!
- `flutter test` — all tests pass

## Spec tracker
- `index.md` onboarding row V-Art flipped ⚠ → ✓ (and V-Spec OB1–OB4 marked fixed).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

> Paste the **actual** analyze/test output lines into the body if they differ from the expected "No issues found!" / "all tests pass". Evidence before assertions.

---

## Task 11: Comment on the issue + release the claim (A9)

- [ ] **Step 1: Comment on issue 216 linking the PR**

Run (substitute the real PR URL printed by `gh pr create`):

```bash
gh issue comment 216 --repo Maortz/allergy-detector \
  --body "Implemented in <PR_URL> — OB1 (SafeBite brand header + ✕), OB2 (real hero asset), OB3 (consent-on-tap disclaimer copy), OB4 (48pt/radius-12 continue button). index.md V-Art flipped ⚠→✓. analyze clean, tests green."
```

- [ ] **Step 2: Release the agent claim**

Run: `gh issue edit 216 --repo Maortz/allergy-detector --remove-label agent-in-progress`
Expected: the label is removed (no error).

---

## Self-Review (performed during planning)

**Spec coverage:** OB1 (§4.1) → Task 4 Step 1; OB2 (§4.4/§7.1) → Task 2 + Task 4 Step 2; OB3 (§4.6/§7.2) → Task 5; OB4 (§4.7/§7.3) → Task 6. The brand-text font (§4.1 "Inter Medium 16 pt") had no existing token → Task 1 adds `labelMd`. Asset registration is already covered by `pubspec.yaml:75` (`- assets/images/`) → no pubspec task needed. All four acceptance-criteria items + the index.md flip (Task 8) + analyze/test (Task 7) are covered.

**Placeholder scan:** Every code step shows the literal Dart to write; every command shows the exact invocation and expected output. The only intentional "adapt-on-read" point is Task 3's model fixtures, which depend on the real `Allergen`/`UserProfile` constructors — the engineer is directed to read those files first and the assertions are written to be independent of the exact field names.

**Type consistency:** `labelMd` defined in Task 1 is consumed in Task 4. `onboarding_hero.jpg` path is identical in Task 2 (create), Task 3 (test assertion), and Task 4 (`Image.asset`). The test's `BoxFit.cover` and radius-12 assertions match the implementation in Tasks 4 and 6.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-06-15-issue-216-onboarding-vart.md`.** A separate execution agent will implement it task-by-task using superpowers:subagent-driven-development (recommended) or superpowers:executing-plans, starting at Task 1 (the branch `agent/issue-216-onboarding-vart` is already created).
