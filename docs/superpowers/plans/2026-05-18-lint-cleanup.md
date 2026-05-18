# Lint Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drive `flutter analyze` to zero issues (26 → 0) and add a CI gate so warnings can never regress.

**Architecture:** Pure mechanical cleanup — delete dead code/imports, rename deprecated APIs, de-duplicate casts. No behavior changes. Each task: edit → re-run `flutter analyze` (issue count drops) → run affected tests → commit. The existing 184-test suite is the safety net for the code-touching deletions. Final task flips the CI analyze step to fail on warnings.

**Tech Stack:** Flutter 3.41.7 / Dart, `flutter analyze`, `flutter test`, GitHub Actions (`.github/workflows/ci.yml`).

**Branch:** Create `chore/lint-cleanup` off `master` before Task 1 (`git fetch origin && git switch -c chore/lint-cleanup origin/master`).

**Roadmap context:** This is ranked item #2 in `docs/ROADMAP.md`. The roadmap said "32 warnings"; actual count is **26** (`flutter analyze --no-fatal-infos --no-fatal-warnings`, run 2026-05-18). Scope decisions already made with the user: (a) dead "show only safe products" toggle → **delete the stub**, do not wire it; (b) **add the CI 0-warning gate** as the final task.

All `flutter`/`git` commands run **from the `app/` directory** unless noted. Do not redirect native-exe stderr with `2>&1` on Windows PowerShell (it falsely sets exit 1). Use `flutter analyze | Select-Object -Last 5`.

---

## Baseline (the 26 issues, for reference)

| Category | Count | Locations |
|---|---|---|
| Unused import | 11 | `lib/services/allergen_service.dart:1`, `lib/services/image_service.dart:1`, `test/add_product_test.dart:5`, `test/helpers/mock_supabase.dart:1`, `test/native_features_test.dart:4`, `test/unit/services/allergen_service_test.dart:3`, `test/unit/services/allergen_service_test.dart:4`, `test/unit/services/product_service_test.dart:3`, `test/widgets/screens/community_screen_test.dart:4`, `test/widgets/screens/search_scan_screen_test.dart:7`, `test/widgets/screens/settings_screen_test.dart:7` |
| Unused field | 3 | `lib/screens/search_scan_screen.dart:37` (`_searchResults`), `:38` (`_isSearching`), `lib/screens/settings_screen.dart:33` (`_showOnlySafeProducts`) |
| prefer_final_fields | 1 | `lib/screens/settings_screen.dart:33` (same field — removed by deleting it) |
| Unused element | 1 | `test/integration/user_flows_test.dart:425` (`_createAllergen`) |
| deprecated_member_use (`withOpacity`) | 3 | `lib/screens/drawer_user_screen.dart:108`, `:115`, `:122` |
| deprecated_member_use (`value:`→`initialValue:`) | 3 | `lib/screens/add_product_screen.dart:201`, `lib/screens/feedback_screen.dart:84`, `test/integration/user_flows_test.dart:496` |
| unnecessary_cast | 2 | `lib/services/search_cache.dart:80`, `:81` |
| unnecessary_underscores | 2 | `lib/screens/home_screen.dart:330` |

Cascade: deleting `_searchResults` removes the only use of `Product` in `search_scan_screen.dart`, so its `import '../models/product.dart';` (line 5) also becomes unused — handled in Task 2.

After every task, run from `app/`:
```
flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3
```
The trailing "N issues found" must strictly decrease toward 0.

---

## Task 1: Remove the 11 unused imports

**Files (delete the single flagged import line in each):**
- Modify: `app/lib/services/allergen_service.dart:1` — `import 'package:flutter/material.dart';`
- Modify: `app/lib/services/image_service.dart:1` — `import 'package:flutter/foundation.dart';`
- Modify: `app/test/add_product_test.dart:5` — `import 'package:app/widgets/progress_stepper.dart';`
- Modify: `app/test/helpers/mock_supabase.dart:1` — `import 'package:supabase_flutter/supabase_flutter.dart';`
- Modify: `app/test/native_features_test.dart:4` — `import 'package:app/services/storage_service.dart';`
- Modify: `app/test/unit/services/allergen_service_test.dart:3` — `import 'package:supabase_flutter/supabase_flutter.dart';`
- Modify: `app/test/unit/services/allergen_service_test.dart:4` — `import 'package:app/services/allergen_service.dart';`
- Modify: `app/test/unit/services/product_service_test.dart:3` — `import 'package:app/services/product_service.dart';`
- Modify: `app/test/widgets/screens/community_screen_test.dart:4` — `import 'package:app/widgets/bottom_nav_bar.dart';`
- Modify: `app/test/widgets/screens/search_scan_screen_test.dart:7` — `import 'package:app/widgets/bottom_nav_bar.dart';`
- Modify: `app/test/widgets/screens/settings_screen_test.dart:7` — `import 'package:app/widgets/bottom_nav_bar.dart';`

- [ ] **Step 1: Delete each flagged import line.** Open each file at the listed line, confirm the import text matches the list above (line numbers may have shifted only if the file changed — match on the import string, not the number), and delete that single line. Do not touch any other import.

- [ ] **Step 2: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `15 issues found.` (26 − 11). No `unused_import` lines remain.

- [ ] **Step 3: Run the full test suite** (these are mostly test files; confirm nothing relied on the imports transitively)

Run (from `app/`): `flutter test`
Expected: `All tests passed!` (184 tests).

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "chore(lint): remove 11 unused imports"
```

---

## Task 2: Remove dead `_onSearch` + write-only fields in `search_scan_screen.dart`

`_searchResults` and `_isSearching` are write-only (assigned in `setState`, never read — the screen never renders results). Their only writer is `_onSearch`, wired to `SearchInput.onChanged` (line 152) and a barcode `TextField.onSubmitted` (line 264). `SearchInput.onChanged` and `TextField.onSubmitted` are both optional (`ValueChanged<String>?`), and there is no `ActiveSearchScreen` in the codebase (the CLAUDE.md reference is stale). So `_onSearch` performs a discarded network call on every keystroke and is genuinely dead. Per the agreed "delete the stub" principle, remove it entirely. A partial fix (keeping `_onSearch`) would spawn new `empty_catches`/`unused_local_variable` lints — delete the whole thing.

**Files:**
- Modify: `app/lib/screens/search_scan_screen.dart` (delete: line 5 `import '../models/product.dart';`; lines 37–38 field decls; the entire `_onSearch` method lines 91–122; line 152 `onChanged: _onSearch,`; line 264 `onSubmitted: _onSearch,`)
- Test: `app/test/widgets/screens/search_scan_screen_test.dart` (must still pass — **never `pumpAndSettle`** here; the laser `AnimationController` repeats forever and will time out)

- [ ] **Step 1: Delete the unused `Product` import**

Remove this line (line 5):
```dart
import '../models/product.dart';
```

- [ ] **Step 2: Delete the two dead field declarations**

Remove these lines (37–38):
```dart
  List<Product> _searchResults = [];
  bool _isSearching = false;
```

- [ ] **Step 3: Delete the entire `_onSearch` method**

Remove lines 91–122 (the whole method):
```dart
  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (widget.productService == null) {
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await widget.productService!.searchProducts(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }
```

- [ ] **Step 4: Remove the two `_onSearch` wirings**

In `_buildSearchSection` (was line 150–155), delete the `onChanged: _onSearch,` line so it reads:
```dart
  Widget _buildSearchSection() {
    return SearchInput(
      controller: _searchController,
      hintText: 'חפש מוצר או מרכיב...',
    );
  }
```

In the barcode `TextField` (was line 257–265), delete the `onSubmitted: _onSearch,` line so it reads:
```dart
                TextField(
                  decoration: InputDecoration(
                    labelText: 'הכנס ברקוד',
                    hintText: '72900...',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
```

- [ ] **Step 5: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `13 issues found.` (15 − 2 unused fields; the cascaded `product.dart` import was never separately counted). No `_searchResults`/`_isSearching` warnings.

- [ ] **Step 6: Run the affected widget test**

Run (from `app/`): `flutter test test/widgets/screens/search_scan_screen_test.dart`
Expected: all tests pass. If a test referenced `_onSearch` behavior or typed into the search field expecting results, it would have been asserting on nothing (results were never rendered); if it fails on a missing symbol, that test was testing dead code — delete that specific test case and note it in the commit message.

- [ ] **Step 7: Commit**

```
git add -A
git commit -m "chore(lint): remove dead _onSearch and write-only search fields"
```

---

## Task 3: Remove dead `_showOnlySafeProducts` field in `settings_screen.dart`

Write-once (`= true`), never read — a never-wired "show only safe products" filter stub. Agreed decision: delete it (wiring the filter is separate roadmap scope). Removing it clears both the `unused_field` warning and the `prefer_final_fields` info.

**Files:**
- Modify: `app/lib/screens/settings_screen.dart:33`
- Test: `app/test/widgets/screens/settings_screen_test.dart`

- [ ] **Step 1: Delete the field**

Remove line 33:
```dart
  bool _showOnlySafeProducts = true;
```
The class body becomes:
```dart
class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
```

- [ ] **Step 2: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `11 issues found.` (13 − unused_field − prefer_final_fields).

- [ ] **Step 3: Run the affected widget test**

Run (from `app/`): `flutter test test/widgets/screens/settings_screen_test.dart`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "chore(lint): delete unwired _showOnlySafeProducts stub"
```

---

## Task 4: Remove unused `_createAllergen` test helper

**Files:**
- Modify: `app/test/integration/user_flows_test.dart` (delete the unreferenced `_createAllergen` declaration starting at line 425)

- [ ] **Step 1: Read and delete the helper**

Open `app/test/integration/user_flows_test.dart` at line 425. The analyzer flags `_createAllergen` as `unused_element` (declaration not referenced anywhere in the file). Read the full function (from `... _createAllergen(` through its closing brace) and delete the entire declaration. Confirm with a search that `_createAllergen` has no remaining references in the file before deleting.

- [ ] **Step 2: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `10 issues found.` No `unused_element` line.

- [ ] **Step 3: Run the affected test file**

Run (from `app/`): `flutter test test/integration/user_flows_test.dart`
Expected: all tests pass (the helper was unused, so behavior is unchanged).

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "chore(lint): remove unused _createAllergen test helper"
```

---

## Task 5: `withOpacity` → `withValues(alpha:)` in `drawer_user_screen.dart`

`withOpacity` is deprecated (precision loss); replacement is `.withValues(alpha: <same value>)`.

**Files:**
- Modify: `app/lib/screens/drawer_user_screen.dart:108`, `:115`, `:122`

- [ ] **Step 1: Replace all three call sites**

Line 108: `AppColors.onSurfaceVariant.withOpacity(0.4)` → `AppColors.onSurfaceVariant.withValues(alpha: 0.4)`

Line 115: `AppColors.onSurface.withOpacity(0.4)` → `AppColors.onSurface.withValues(alpha: 0.4)`

Line 122: `AppColors.onSurfaceVariant.withOpacity(0.4)` → `AppColors.onSurfaceVariant.withValues(alpha: 0.4)`

(All three pass `0.4`. Match on the exact `.withOpacity(0.4)` text.)

- [ ] **Step 2: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `7 issues found.` No `withOpacity` deprecation lines.

- [ ] **Step 3: Run the affected widget test (if present), else full suite**

Run (from `app/`): `flutter test`
Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "chore(lint): migrate withOpacity to withValues in drawer_user_screen"
```

---

## Task 6: `value:` → `initialValue:` on three form fields

`DropdownButtonFormField`/`FormField` `value:` was deprecated after Flutter v3.33; the analyzer says "Use initialValue instead". This is a straight named-argument rename — same expression, same behavior.

**Files:**
- Modify: `app/lib/screens/add_product_screen.dart:201`
- Modify: `app/lib/screens/feedback_screen.dart:84`
- Modify: `app/test/integration/user_flows_test.dart:496`

- [ ] **Step 1: Rename the argument at each site**

`add_product_screen.dart:201` — inside `DropdownButtonFormField<String>(`:
```dart
          value: _selectedBrand,
```
→
```dart
          initialValue: _selectedBrand,
```

`feedback_screen.dart:84` — inside `DropdownButtonFormField<String>(`:
```dart
                value: _selectedType,
```
→
```dart
                initialValue: _selectedType,
```

`test/integration/user_flows_test.dart:496` — the flagged `value:` on a form field at line 496. Read the surrounding widget constructor, confirm it is the `value:` named arg on a `DropdownButtonFormField`/`FormField`, and rename `value:` → `initialValue:` (keep the same right-hand expression).

- [ ] **Step 2: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `4 issues found.` No `Use initialValue instead` lines.

- [ ] **Step 3: Run affected tests**

Run (from `app/`): `flutter test test/add_product_test.dart test/integration/user_flows_test.dart`
Expected: all pass. (`feedback_screen` has no dedicated file — covered by the full run in Task 9.)

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "chore(lint): rename deprecated form-field value: to initialValue:"
```

---

## Task 7: De-duplicate the `as Map` casts in `search_cache.dart`

Lines 80 and 81 re-cast `a as Map` after line 79 already did; analyzer flags 80/81 as `unnecessary_cast`. Fix by casting once into a local.

**Files:**
- Modify: `app/lib/services/search_cache.dart:77-83`

- [ ] **Step 1: Replace the `.map` body**

Current (lines 77–83):
```dart
        allergens: (json['allergens'] as List?)
                ?.map((a) => ProductAllergen(
                      allergenId: (a as Map)['allergen_id'] as String,
                      allergenNameHe: (a as Map)['allergen_name_he'] as String,
                      severity: (a as Map)['severity'] as String,
                    ))
                .toList() ??
```
Replace with:
```dart
        allergens: (json['allergens'] as List?)
                ?.map((a) {
                  final m = a as Map;
                  return ProductAllergen(
                    allergenId: m['allergen_id'] as String,
                    allergenNameHe: m['allergen_name_he'] as String,
                    severity: m['severity'] as String,
                  );
                })
                .toList() ??
```

- [ ] **Step 2: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `2 issues found.` No `unnecessary_cast` lines.

- [ ] **Step 3: Run the search_cache unit test**

Run (from `app/`): `flutter test test/unit/services/search_cache_test.dart`
Expected: all pass. (If the file does not exist, run `flutter test` — the full suite must stay green; cache deserialization is exercised by product/search tests.)

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "chore(lint): hoist as Map cast to remove redundant casts in search_cache"
```

---

## Task 8: Fix `unnecessary_underscores` in `home_screen.dart`

`errorBuilder: (_, __, ___)` uses multiple-underscore identifiers; Dart 3.7 wildcard params want a single `_` for each unused parameter.

**Files:**
- Modify: `app/lib/screens/home_screen.dart:330`

- [ ] **Step 1: Replace the lambda parameter list**

Line 330:
```dart
                    errorBuilder: (_, __, ___) => Icon(
```
→
```dart
                    errorBuilder: (_, _, _) => Icon(
```

- [ ] **Step 2: Re-run analyze**

Run (from `app/`): `flutter analyze --no-fatal-infos --no-fatal-warnings | Select-Object -Last 3`
Expected: `0 issues found.` ✅

- [ ] **Step 3: Run the home_screen widget test**

Run (from `app/`): `flutter test test/widgets/screens/home_screen_test.dart`
Expected: all pass. (If no such file, the full suite in Task 9 covers it.)

- [ ] **Step 4: Commit**

```
git add -A
git commit -m "chore(lint): use single-underscore wildcards in home_screen errorBuilder"
```

---

## Task 9: Full verification — zero issues, all tests, web build

- [ ] **Step 1: Strict analyze (no suppression flags)**

Run (from `app/`): `flutter analyze | Select-Object -Last 3`
Expected: `No issues found!` — strict mode (no `--no-fatal-*`) is clean because infos were cleared too.

- [ ] **Step 2: Full test suite**

Run (from `app/`): `flutter test`
Expected: `All tests passed!` (184 tests, or fewer only if a dead-code test case was removed in Task 2 — the count drop must be explainable by that and nothing else).

- [ ] **Step 3: Web build (the CI `build` job's third gate)**

Run (from `app/`): `flutter build web --no-tree-shake-icons`
Expected: build succeeds (`✓ Built build\web`).

- [ ] **Step 4: No commit** (verification only — nothing changed this task).

---

## Task 10: Add the CI 0-warning gate

The CI analyze step currently suppresses both infos and warnings. Now that warnings are zero, make warnings fatal so they can't regress. Keep `--no-fatal-infos`: future Flutter SDK bumps surface new deprecation **infos** on unrelated PRs, and the roadmap's stated goal is a "0-**warning** baseline" specifically — gating on infos would make CI brittle. (Strict local `flutter analyze` is clean today, but CI should fail only on warnings.)

**Files:**
- Modify: `.github/workflows/ci.yml:41-42` (repo root, not `app/`)

- [ ] **Step 1: Tighten the analyze step**

Current (lines 41–42):
```yaml
      - name: Analyze (errors only)
        run: flutter analyze --no-fatal-infos --no-fatal-warnings
```
Replace with:
```yaml
      - name: Analyze (errors + warnings fatal)
        run: flutter analyze --no-fatal-infos
```

- [ ] **Step 2: Sanity-check the command locally**

Run (from `app/`): `flutter analyze --no-fatal-infos | Select-Object -Last 3`
Expected: `No issues found!` and exit 0 — confirms the new CI command passes on the cleaned tree.

- [ ] **Step 3: Commit**

```
git add .github/workflows/ci.yml
git commit -m "ci: make flutter analyze fail on warnings (0-warning baseline)"
```

- [ ] **Step 4: Update the roadmap**

In `docs/ROADMAP.md`: move item #2 ("Clean up the 32 lint warnings") to the **Done** section with date `2026-05-18`, branch `chore/lint-cleanup`, note actual count was 26 not 32 and that the CI analyze gate was tightened. Bump the "Last reviewed" line. Commit:
```
git add docs/ROADMAP.md
git commit -m "docs: mark lint-cleanup roadmap item done"
```

- [ ] **Step 5: Open the PR**

```
git push -u origin chore/lint-cleanup
gh pr create --base master --title "chore: clear all 26 lint issues + add CI 0-warning gate" --body "Resolves ROADMAP item #2. Drives `flutter analyze` to zero, then makes warnings fatal in CI. Mechanical only — no behavior changes; dead code (vestigial `_onSearch`, unwired `_showOnlySafeProducts` stub) deleted per agreed scope."
```

---

## Self-Review

- **Spec coverage:** All 26 baseline issues are mapped: imports (T1), search_scan dead fields (T2), settings stub (T3), unused element (T4), withOpacity (T5), value→initialValue (T6), unnecessary_cast (T7), unnecessary_underscores (T8). Both agreed scope decisions implemented: delete-the-stub (T3), CI gate (T10). Cascade (orphaned `product.dart` import) handled in T2. Running issue-count math: 26→15→13→11→10→7→4→2→0 ✓.
- **Placeholders:** None — every code step shows exact before/after. T4 and the `user_flows_test.dart:496` site instruct a read-then-delete/rename because the exact span depends on lines not yet read; the matching criterion (symbol name / flagged arg) is explicit, which is the correct rigor for a deletion/rename of a flagged symbol.
- **Consistency:** `flutter analyze --no-fatal-infos --no-fatal-warnings` used as the per-task progress check throughout; T9 uses strict `flutter analyze`; T10 sets CI to `--no-fatal-infos`. Field/method names (`_onSearch`, `_searchResults`, `_isSearching`, `_showOnlySafeProducts`, `_createAllergen`) consistent with the analyzer output.
- **Scope:** Single focused plan, one PR. No unrelated refactoring.
