# ProductCard Token Substitution (#284) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every raw `Colors.*` literal in `app/lib/widgets/product_card.dart` with the existing semantic `AppColors` tokens, so the card stops hardcoding palette values and routes all colour through the design-system token layer.

**Architecture:** Pure, mechanical token substitution inside one stateless widget. No behavioural change, no new widgets, no signature changes. Each `Colors.*` reference maps 1:1 to an `AppColors` constant per the issue's substitution table. A widget test pins the resolved status colours to the tokens so the substitution can't silently regress.

**Tech Stack:** Flutter / Dart, Material 3, project theme tokens in `app/lib/theme/app_colors.dart`.

---

## Scope & Context (read before starting)

- **Branch is already created** (orchestrator step A3 done): you are on `agent/issue-284-product-card-dark-mode`, cut from an up-to-date `master`. Execution starts at Task 1 below.
- **All Flutter/Dart commands run from `/workspace/app`.** Per `CLAUDE.md`, `flutter`/`dart` run from `app/`, not the repo root. Use that as the working directory. Flutter is not always on `PATH` — if `flutter` is not found, locate it (e.g. `which flutter` / check the toolchain) before proceeding; do not skip the verify gates.
- **Single production file changes:** `app/lib/widgets/product_card.dart`. The package name is `app` (imports use `package:app/...`).
- **`AppColors` is light-mode only by design.** The dark palette lives in a *separate* `AppDarkColors` class (`app/lib/theme/app_colors.dart:153`) that feeds `buildDarkAppTheme()` only — widgets reference the light `AppColors` tokens directly. This issue is therefore a **cosmetic token-substitution task**, not a full dark-mode rewire. That is the explicit, accepted scope of #284 (its acceptance criteria are satisfied by token substitution alone). Do NOT attempt to make `AppColors` theme-aware or thread a `BuildContext`-resolved palette through the card — that is out of scope and belongs to the parent epic #258.
- **Token existence is already verified.** Every target token below exists in `AppColors` (light section, lines noted): `primary` (6), `surfaceContainerLow` (46), `onSurfaceVariant` (54), `iconMuted` (74), `safeBackground` (94), `safeText` (95), `cautionText` (97), `avoidText` (119), `avoid` (131), `success` (133), `warning` (137).

### Substitution table (the complete change set — from the issue)

| Current literal | Replace with | Context in file |
|---|---|---|
| `Colors.red` (statusColor → avoid) | `AppColors.avoid` | `statusColor` getter |
| `Colors.orange` (statusColor → caution) | `AppColors.warning` | `statusColor` getter |
| `Colors.green` (statusColor → safe) | `AppColors.success` | `statusColor` getter |
| `Colors.green[50]` | `AppColors.safeBackground` | kosher badge bg |
| `Colors.green[200]!` | `AppColors.safeText` | kosher badge border |
| `Colors.green[700]` (icon) | `AppColors.safeText` | kosher badge icon |
| `Colors.green[700]` (text) | `AppColors.safeText` | kosher badge text |
| `Colors.grey[100]` | `AppColors.surfaceContainerLow` | image placeholder bg |
| `Colors.grey[400]` (errorBuilder icon) | `AppColors.iconMuted` | image fallback icon |
| `Colors.grey[400]` (no-image icon) | `AppColors.iconMuted` | image fallback icon |
| `Colors.grey[600]` | `AppColors.onSurfaceVariant` | brand-name text |
| `Colors.blue` | `AppColors.primary` | verified brand icon |
| `Colors.red[700]` | `AppColors.avoidText` | "מכיל:" label |
| `Colors.red` (contains chips) | `AppColors.avoid` | `_buildContainsRow` chip colour |
| `Colors.orange[700]` | `AppColors.cautionText` | "עשוי להכיל:" label |
| `Colors.orange` (may-contain chips) | `AppColors.warning` | `_buildMayContainRow` chip colour |

### Staff-level standards to uphold

- Keep business logic (the `statusFor`/`status` mapping) where it already is — in the widget's pure getters reading from `userProfile`; do not move or reshape it.
- Preserve `const` on every constructor/widget that is already `const`. Note: several `Icon`/`Text` widgets are currently **non-`const`** *only because* they reference `Colors.grey[400]` etc. (subscript access is not a compile-time constant). After substituting `AppColors.iconMuted` (a `static const Color`), those widgets can — and should — become `const` where all other arguments are already constant. Make them `const` (see Task 3, `_buildImage`).
- No disposal concerns (stateless widget, no controllers).
- Hebrew/RTL strings are untouched — this is colour-only.
- After the change, **zero** `Colors.*` and **zero** `Color(0xFF...)` literals may remain in the file.

---

## File Structure

- **Modify:** `app/lib/widgets/product_card.dart` — add the `AppColors` import; replace all 16 colour literals.
- **Modify (test):** `app/test/widgets/widgets/product_card_test.dart` — add a test group pinning the three status colours to their tokens.

No files are created.

---

## Task 1: Pin status colours to tokens (failing test first)

The `statusColor` getter is the cleanest seam to lock down: it is pure and returns the colour driving the badge/chip. We assert it equals the exact `AppColors` token per status. This will fail today because the getter still returns `Colors.red` / `Colors.orange` / `Colors.green`.

**Files:**
- Test: `app/test/widgets/widgets/product_card_test.dart`

- [ ] **Step 1: Add the failing test group**

Open `app/test/widgets/widgets/product_card_test.dart`. It already imports:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/widgets/product_card.dart';
import 'package:app/models/product.dart';
import 'package:app/models/user_profile.dart';
```

Add this import alongside the others (keep imports grouped/alphabetical-ish with the existing `package:app/...` ones):

```dart
import 'package:app/theme/app_colors.dart';
```

The existing `main()` opens with `group('ProductCard', () {` and defines `safeProduct`, `avoidProduct`, and `cautionProduct` at the top of that group. The `avoidProduct` uses allergen id `'1'` (גלוטן) with severity `contains`; `cautionProduct` uses id `'1'` with `may_contain`. A `UserProfile(selectedAllergenIds: {'1'})` therefore yields `avoid` for `avoidProduct` and `caution` for `cautionProduct`; an empty profile yields `safe` for any product.

Add this new group **inside** `main()`, after the existing `group('ProductCard', () { ... });` block closes (i.e. as a sibling top-level group, before the final `}` of `main`):

```dart
  group('ProductCard statusColor tokens', () {
    final glutenContains = Product(
      id: 'prod-token-1',
      nameHe: 'מוצר בדיקה',
      allergens: [
        ProductAllergen(
          allergenId: '1',
          allergenNameHe: 'גלוטן',
          severity: 'contains',
        ),
      ],
    );

    final glutenMayContain = Product(
      id: 'prod-token-2',
      nameHe: 'מוצר בדיקה',
      allergens: [
        ProductAllergen(
          allergenId: '1',
          allergenNameHe: 'גלוטן',
          severity: 'may_contain',
        ),
      ],
    );

    test('avoid status resolves to AppColors.avoid', () {
      final card = ProductCard(
        product: glutenContains,
        userProfile: const UserProfile(selectedAllergenIds: {'1'}),
      );
      expect(card.statusColor, AppColors.avoid);
    });

    test('caution status resolves to AppColors.warning', () {
      final card = ProductCard(
        product: glutenMayContain,
        userProfile: const UserProfile(selectedAllergenIds: {'1'}),
      );
      expect(card.statusColor, AppColors.warning);
    });

    test('safe status resolves to AppColors.success', () {
      final card = ProductCard(
        product: glutenContains,
        userProfile: const UserProfile(selectedAllergenIds: {}),
      );
      expect(card.statusColor, AppColors.success);
    });
  });
```

> If the `Product` / `ProductAllergen` constructor argument names differ from the snippet above when you open the file, mirror the exact shape already used by `safeProduct`/`avoidProduct` at the top of the existing group (copy their constructor calls) rather than inventing fields.

- [ ] **Step 2: Run the new tests to verify they fail**

Run from `/workspace/app`:

```bash
flutter test test/widgets/widgets/product_card_test.dart --plain-name "statusColor tokens"
```

Expected: FAIL — the `avoid` and `caution` (and possibly `safe`) assertions fail because `statusColor` still returns `Colors.red`/`Colors.orange`/`Colors.green`, which are not equal to `AppColors.avoid` (`0xFFDC2626`), `AppColors.warning` (`0xFFFF9800`), `AppColors.success` (`0xFF0D9488`). (`Colors.orange == 0xFFFF9800`, so the caution case may coincidentally pass — that is fine; the avoid and safe cases will fail, proving the test bites.)

- [ ] **Step 3: Commit the failing test**

```bash
git add app/test/widgets/widgets/product_card_test.dart
git commit -m "test(product-card): pin statusColor to AppColors tokens (#284)"
```

---

## Task 2: Substitute the status-colour getter

**Files:**
- Modify: `app/lib/widgets/product_card.dart` (import + `statusColor` getter, around lines 1 and 22–31)

- [ ] **Step 1: Add the AppColors import**

The file currently starts:

```dart
import 'package:flutter/material.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
```

Add the theme import after the `material.dart` import:

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/allergen.dart';
import '../models/product.dart';
import '../models/user_profile.dart';
```

- [ ] **Step 2: Replace the three literals in `statusColor`**

Current:

```dart
  Color get statusColor {
    switch (status) {
      case AllergenStatus.avoid:
        return Colors.red;
      case AllergenStatus.caution:
        return Colors.orange;
      case AllergenStatus.safe:
        return Colors.green;
    }
  }
```

Replace with:

```dart
  Color get statusColor {
    switch (status) {
      case AllergenStatus.avoid:
        return AppColors.avoid;
      case AllergenStatus.caution:
        return AppColors.warning;
      case AllergenStatus.safe:
        return AppColors.success;
    }
  }
```

- [ ] **Step 3: Run the Task 1 tests to verify they now pass**

Run from `/workspace/app`:

```bash
flutter test test/widgets/widgets/product_card_test.dart --plain-name "statusColor tokens"
```

Expected: PASS — all three assertions green.

- [ ] **Step 4: Commit**

```bash
git add app/lib/widgets/product_card.dart
git commit -m "feat(product-card): source status colours from AppColors tokens (#284)"
```

---

## Task 3: Substitute the kosher badge and image-placeholder literals

**Files:**
- Modify: `app/lib/widgets/product_card.dart` (kosher badge ~lines 100–113; `_buildImage` ~lines 164–184)

- [ ] **Step 1: Replace the kosher badge literals**

Current (inside the `if (product.isKosher)` block):

```dart
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.green[200]!),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.abc, size: 11, color: Colors.green[700]),
                                            const SizedBox(width: 2),
                                            Text(
                                              'כשר',
                                              style: TextStyle(fontSize: 11, color: Colors.green[700]),
                                            ),
```

Replace with:

```dart
                                        decoration: BoxDecoration(
                                          color: AppColors.safeBackground,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.safeText),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.abc, size: 11, color: AppColors.safeText),
                                            SizedBox(width: 2),
                                            Text(
                                              'כשר',
                                              style: TextStyle(fontSize: 11, color: AppColors.safeText),
                                            ),
```

Note: with both children now fully `const` (`AppColors.safeText` is a `static const Color`), the inner `Row` becomes `const Row(...)` and the `const` on `SizedBox(width: 2)` is dropped (redundant inside a `const` parent — keeping it is a `prefer_const` lint nit the analyzer flags). The closing of this `Row` (`],\n                                        ),`) and the rest of the badge structure are unchanged.

- [ ] **Step 2: Replace the `_buildImage` literals**

Current:

```dart
  Widget _buildImage() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: product.imageUrl != null
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.shopping_basket,
                color: Colors.grey[400],
              ),
            )
          : Icon(Icons.shopping_basket, color: Colors.grey[400], size: 28),
    );
  }
```

Replace with:

```dart
  Widget _buildImage() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: product.imageUrl != null
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.shopping_basket,
                color: AppColors.iconMuted,
              ),
            )
          : const Icon(Icons.shopping_basket, color: AppColors.iconMuted, size: 28),
    );
  }
```

Note both `Icon`s become `const` now that `AppColors.iconMuted` is a compile-time constant.

- [ ] **Step 3: Run the full file's tests to verify nothing broke**

Run from `/workspace/app`:

```bash
flutter test test/widgets/widgets/product_card_test.dart
```

Expected: PASS — all tests in the file green.

- [ ] **Step 4: Commit**

```bash
git add app/lib/widgets/product_card.dart
git commit -m "feat(product-card): token-swap kosher badge + image placeholder (#284)"
```

---

## Task 4: Substitute the brand row, contains row, and may-contain row literals

**Files:**
- Modify: `app/lib/widgets/product_card.dart` (`_buildBrandRow` ~lines 186–208; `_buildContainsRow` ~lines 236–260; `_buildMayContainRow` ~lines 262–286)

- [ ] **Step 1: Replace `_buildBrandRow` literals**

Current (relevant fragments):

```dart
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
```

Replace with:

```dart
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
```

And the verified icon:

```dart
            Icon(
              Icons.verified,
              size: 14,
              color: Colors.blue,
            ),
```

Replace with:

```dart
            const Icon(
              Icons.verified,
              size: 14,
              color: AppColors.primary,
            ),
```

(The `Icon` becomes `const` — all its args are now constant.)

- [ ] **Step 2: Replace `_buildContainsRow` literals**

Current:

```dart
        Text(
          'מכיל:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
```

Replace with:

```dart
        const Text(
          'מכיל:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.avoidText,
          ),
        ),
```

And the chip-colour argument:

```dart
                .map((a) => _buildAllergenChip(a.allergenNameHe, Colors.red))
```

Replace with:

```dart
                .map((a) => _buildAllergenChip(a.allergenNameHe, AppColors.avoid))
```

- [ ] **Step 3: Replace `_buildMayContainRow` literals**

Current:

```dart
        Text(
          'עשוי להכיל:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
```

Replace with:

```dart
        const Text(
          'עשוי להכיל:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.cautionText,
          ),
        ),
```

And the chip-colour argument:

```dart
                .map((a) => _buildAllergenChip(a.allergenNameHe, Colors.orange))
```

Replace with:

```dart
                .map((a) => _buildAllergenChip(a.allergenNameHe, AppColors.warning))
```

- [ ] **Step 4: Verify no colour literals remain**

Run from `/workspace/app`:

```bash
grep -nE 'Colors\.|Color\(0x' lib/widgets/product_card.dart
```

Expected: **no output** (exit code 1). Every `Colors.*` and `Color(0xFF...)` literal is gone. If anything prints, replace it per the substitution table before continuing.

- [ ] **Step 5: Run the file's tests**

Run from `/workspace/app`:

```bash
flutter test test/widgets/widgets/product_card_test.dart
```

Expected: PASS — all tests green.

- [ ] **Step 6: Commit**

```bash
git add app/lib/widgets/product_card.dart
git commit -m "feat(product-card): token-swap brand/contains/may-contain colours (#284)"
```

---

## Task 5: Full verification gate

Run each command one at a time (no `&&` chaining), from `/workspace/app`. All three must be clean before proceeding.

- [ ] **Step 1: Dependencies resolved**

```bash
flutter pub get
```

Expected: completes without error (`Got dependencies!` / `Resolving dependencies...` then success).

- [ ] **Step 2: Static analysis — zero issues**

```bash
flutter analyze lib test
```

Expected: `No issues found!`. In particular there must be **no** `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` warnings on the `Icon`/`Text`/`Row` widgets you touched — if any appear, add the `const` keyword the lint asks for (those widgets are now const-eligible because `AppColors` tokens are compile-time constants). Do not use `2>&1` redirection (see `CLAUDE.md` operational note).

- [ ] **Step 3: Full test suite — all green**

```bash
flutter test
```

Expected: all tests pass (e.g. `All tests passed!`). Pay attention to `test/search_test.dart` and `test/integration/user_flows_test.dart`, which also render `ProductCard` — they must stay green.

- [ ] **Step 4: If anything failed**

Use the superpowers:systematic-debugging skill. Do not weaken assertions or delete tests to make the gate pass. The change is colour-only; a failure almost certainly means a missed/incorrect substitution or a dropped `const` — re-check against the substitution table and Task 3/4 notes.

---

## Task 6 (A6): Update the spec tracker

`ProductCard` is the shared product-row widget used by Home, Active Search, and Search results. This is a token-hygiene change, not a spec/art behaviour change, so leave the **V-Spec** and **V-Art** verdicts as they are — only append a note recording the #284 token substitution to the affected primary screens' V-Spec cells, matching the house style of the file (a parenthesised `#NNN ...` clause).

**Files:**
- Modify: `docs/superpowers/plans/../specs/2026-05-19-stitch-screens/index.md` → `/workspace/docs/superpowers/specs/2026-05-19-stitch-screens/index.md`

- [ ] **Step 1: Append #284 notes to the V-Spec cells of the screens that render `ProductCard`**

The `Code` column for these screens already shows `✓` (shipped) and stays `✓`. In the **V-Spec** cell of rows **#1 (home-dashboard)**, **#3 (active-search-results)**, append a clause noting the change. Add — inside the existing parenthesised V-Spec note for each, before its closing `)` — the sentence:

```
; #284 replaced the last raw Colors.* literals in the shared ProductCard widget with semantic AppColors tokens (statusColor avoid/caution/safe → avoid/warning/success, kosher badge → safeBackground/safeText, image placeholder → surfaceContainerLow/iconMuted, brand row → onSurfaceVariant/primary, contains/may-contain → avoidText/avoid + cautionText/warning) — colour-only, no behaviour change; AppColors is light-only by design so this is token hygiene, not dark-mode wiring (dark theme is served by AppDarkColors/buildDarkAppTheme)
```

Do not alter the `Stitch`, `Spec`, `Code`, **V-Art**, or `Screen ID` columns. If editing the inline cell text is impractical to match uniquely, add the same clause to whichever of these two rows' V-Spec notes you can edit unambiguously; the substantive record is the point.

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-05-19-stitch-screens/index.md
git commit -m "docs(spec): note #284 ProductCard AppColors token substitution"
```

---

## Task 7 (A7): Drift check

Confirm no foreign commits landed on `master` under us before opening the PR.

- [ ] **Step 1: Fetch and diff against origin/master**

```bash
git fetch origin
```

```bash
git log origin/master..HEAD --oneline
```

Expected: only **your** commits from this plan appear (the `test(product-card)`, three `feat(product-card)`, and the `docs(spec)` commits) — all authored for #284. If you see any commit you did not author in this session, **STOP**: the branch has drifted / a foreign commit is present. Do not push. Report `STOPPED foreign commits on branch` and surface the offending lines.

---

## Task 8 (A8): Commit hygiene + open the PR

All code commits were made per-task above. Confirm the tree is clean, then push and open the PR.

- [ ] **Step 1: Confirm a clean working tree**

```bash
git status --short
```

Expected: empty (everything committed). If files are unstaged, review and commit them with an appropriate `#284` message before pushing.

- [ ] **Step 2: Amend the final commit footer if needed (Co-Author)**

Ensure at least the head commit carries the required footer. If your last commit lacks it, amend:

```bash
git commit --amend --no-edit --trailer "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

(Equivalent acceptable approach: include the footer when writing each commit message. The requirement is that the commit footer reads exactly `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.)

- [ ] **Step 3: Push the branch**

```bash
git push -u origin agent/issue-284-product-card-dark-mode
```

- [ ] **Step 4: Open the PR**

```bash
gh pr create --repo Maortz/allergy-detector \
  --base master \
  --head agent/issue-284-product-card-dark-mode \
  --title "feat(product-card): replace hardcoded colours with AppColors tokens (#284)" \
  --body "$(cat <<'EOF'
Closes #284

## Summary
Replaces every raw `Colors.*` literal in `app/lib/widgets/product_card.dart` with the matching semantic `AppColors` token. Colour-only change, no behaviour or layout difference.

| Was | Now |
|---|---|
| `statusColor` `Colors.red/orange/green` | `AppColors.avoid/warning/success` |
| kosher badge `Colors.green[50]/[200]/[700]` | `AppColors.safeBackground` / `AppColors.safeText` |
| image placeholder `Colors.grey[100]/[400]` | `AppColors.surfaceContainerLow` / `AppColors.iconMuted` |
| brand row `Colors.grey[600]` / `Colors.blue` | `AppColors.onSurfaceVariant` / `AppColors.primary` |
| contains row `Colors.red[700]` / `Colors.red` | `AppColors.avoidText` / `AppColors.avoid` |
| may-contain row `Colors.orange[700]` / `Colors.orange` | `AppColors.cautionText` / `AppColors.warning` |

Widgets that became compile-time constant after the swap were promoted to `const`.

## Scope note
`AppColors` is light-mode only by design; the dark palette lives in `AppDarkColors`/`buildDarkAppTheme()`. This PR is the token-hygiene slice of parent #258 — it removes hardcoded literals so the card routes colour through the design-system layer. It does not (and per the issue's acceptance criteria need not) make the card theme-aware.

## Verification
- `flutter analyze lib test` → No issues found!
- `flutter test` → all tests passing (added a `statusColor` token-pinning test group to `product_card_test.dart`)
- `grep -nE 'Colors\.|Color\(0x' lib/widgets/product_card.dart` → no matches

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

> Replace the analyze/test result lines in the body with the **actual** output you observed in Task 5 before creating the PR (per superpowers:verification-before-completion — report real results, not assumed ones).

---

## Task 9 (A9): Comment on the issue + release the claim

- [ ] **Step 1: Comment on #284 linking the PR**

Capture the PR URL printed by `gh pr create` (or fetch it):

```bash
gh pr view --repo Maortz/allergy-detector --json url --jq .url
```

Then comment:

```bash
gh issue comment 284 --repo Maortz/allergy-detector \
  --body "PR opened: <PR_URL> — replaces all hardcoded Colors.* in product_card.dart with AppColors tokens; analyze + tests green."
```

(Substitute `<PR_URL>` with the real URL.)

- [ ] **Step 2: Release the agent claim**

```bash
gh issue edit 284 --repo Maortz/allergy-detector --remove-label agent-in-progress
```

Expected: succeeds. (If the label is absent, the command's failure is benign — the claim is already released.)

---

## Self-Review (performed during planning)

- **Spec coverage:** All 16 rows of the issue's substitution table are assigned to a task — `statusColor` trio (Task 2), kosher badge ×4 + image ×3 (Task 3), brand ×2 + contains ×2 + may-contain ×2 (Task 4). Acceptance criteria: "no `Colors.*`/`Color(0xFF...)` remain" → enforced by the `grep` gate in Task 4 Step 4 and Task 5; "status colours use semantic tokens" → Task 2 + pinned by Task 1 test; "`flutter analyze lib test` passes" → Task 5 Step 2.
- **Placeholder scan:** No TBD/TODO/"handle edge cases"/"similar to" — every code step shows the exact before/after.
- **Type/name consistency:** `statusColor` getter name used in Task 1 test and Task 2 impl match the existing source. Token names match the verified `AppColors` members. Package import `package:app/theme/app_colors.dart` (test) and relative `../theme/app_colors.dart` (lib) match the file's existing import style.
- **Scope guard:** Plan explicitly forbids the out-of-scope theme-aware rewrite and keeps the change to the prescribed file + its test + the spec tracker.
