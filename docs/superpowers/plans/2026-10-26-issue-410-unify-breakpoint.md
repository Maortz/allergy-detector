# Unify Community Two-Column Breakpoint (#410) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `CommunityScreen` and `CommunityReviewScreen` switch to their two-column layouts at the exact same viewport width (600 logical px, inclusive), driven by one shared theme token.

**Architecture:** Add `AppBreakpoints` (`app/lib/theme/app_breakpoints.dart`) holding `twoColumn = 600` and a pure `isTwoColumn(double width)` predicate (`width >= twoColumn`, Material 3 convention: the breakpoint value belongs to the wider bucket). Both screens call the predicate. `CommunityScreen` additionally hoists its `LayoutBuilder` above its `SingleChildScrollView` padding, so it measures the **same box** `CommunityReviewScreen` measures (full body width) — today it measures body width minus 2×`AppSpacing.md` (32), so even with matching operators it would flip at a 632 px viewport, not 600.

**Tech Stack:** Flutter / Dart, `flutter_test`.

**Spec:** GitHub issue #410 (Maortz/allergy-detector); related spec rows `community-hub` (#11) and `community-review` (#12) in `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

**Branch:** `agent/issue-410-unify-breakpoint` is already created off up-to-date `master`. Execution starts at Task 1. All `flutter` commands run from `/home/maortz/code/allergy-detector/app` — ONE command per tool call, no `&&`/`;`/pipe chaining.

## Global Constraints

- Breakpoint value: `600` logical px; operator `>=` (600 is two-column, 599 is single-column) — issue #410 / #392 wording.
- Only one definition of the breakpoint in `app/lib/`; both private `_twoColumnBreakpoint` constants are deleted.
- No hardcoded colors/font sizes/spacing — `AppColors`/`AppTypography`/`AppSpacing` only; `AppBreakpoints` lives beside them in `app/lib/theme/`.
- RTL-first: do not change child order of either `Row` (help card first / allergen+decision column first).
- `flutter analyze lib test` must report 0 issues (CI fails on warnings); `flutter test` all green.
- Never `pumpAndSettle` in `search_scan_screen_test.dart` (not touched by this plan, but don't add it anywhere new either — use `pump`).
- Grep result (done at planning time): the only `LayoutBuilder` width-breakpoint literals in `app/lib` are the two `_twoColumnBreakpoint = 600` constants (`community_screen.dart:451`, `community_review_screen.dart:189`). `allergenGridColumns` (`lib/utils/grid_layout.dart`) is a column-count formula, not a breakpoint — leave it alone. Other `maxWidth:` hits are `BoxConstraints` caps, not breakpoints.

## Review Focus

1. **Exactly 600 px viewport on CommunityScreen** — must be two-column (pinned by Task 2 boundary test). This was the bug.
2. **Overflow at the narrowest two-column width** — at a 600 px viewport each CommunityScreen card is (600 − 32 − 24)/2 = 272 px wide (previously the narrowest two-column card was ~288 px). Expect no `RenderFlex` overflow; the boundary test asserts `tester.takeException()` is null. If it fails with an overflow, see the contingency in Task 2 Step 4.
3. **Resize across the boundary** (599 → 600 → 599) without exceptions — both screens rebuild via `LayoutBuilder`; Task 2 boundary test resizes in-place.
4. **Default test surface (800×600)** — existing CommunityScreen tests run at 800 px; before and after the change that is two-column (768 > 600 before, 800 ≥ 600 after), so no existing assertion changes. Full `flutter test` run in Task 3 confirms.
5. **CommunityReviewScreen behavior unchanged** — its existing `boundary: 600 is two-column, 599 is stacked` test must still pass untouched.

---

### Task 1: `AppBreakpoints` token + wire `CommunityReviewScreen`

**Files:**
- Create: `app/lib/theme/app_breakpoints.dart`
- Create: `app/test/unit/theme/app_breakpoints_test.dart`
- Modify: `app/lib/screens/community_review_screen.dart:187-194` (+ doc comment at ~216)

**Interfaces:**
- Produces:
  ```dart
  class AppBreakpoints {
    AppBreakpoints._();
    static const double twoColumn = 600;
    static bool isTwoColumn(double width) => width >= twoColumn;
  }
  ```

- [ ] **Step 1: Write the failing unit test** `app/test/unit/theme/app_breakpoints_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:app/theme/app_breakpoints.dart';

void main() {
  group('AppBreakpoints.isTwoColumn (#410)', () {
    test('threshold value is 600', () {
      expect(AppBreakpoints.twoColumn, 600);
    });
    test('600 belongs to the wide bucket (inclusive)', () {
      expect(AppBreakpoints.isTwoColumn(600), isTrue);
    });
    test('599.9 and 599 stay single-column', () {
      expect(AppBreakpoints.isTwoColumn(599.9), isFalse);
      expect(AppBreakpoints.isTwoColumn(599), isFalse);
    });
    test('phone and desktop widths', () {
      expect(AppBreakpoints.isTwoColumn(390), isFalse);
      expect(AppBreakpoints.isTwoColumn(1920), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (compile error: `app_breakpoints.dart` not found)

Run (from `app/`): `flutter test test/unit/theme/app_breakpoints_test.dart`

- [ ] **Step 3: Create `app/lib/theme/app_breakpoints.dart`** with the class from Interfaces, mirroring `AppSpacing` style (private ctor, `static const`). Doc comment: shared responsive breakpoint for the Community flow (#324, #392, #410); the breakpoint value belongs to the wider bucket (Material 3 convention); callers must pass the full body width (not padded content width) so all screens flip at the same viewport width.

- [ ] **Step 4: Run it — expect PASS**

Run: `flutter test test/unit/theme/app_breakpoints_test.dart`

- [ ] **Step 5: Wire `CommunityReviewScreen`**
  - Add `import '../theme/app_breakpoints.dart';` (match the file's existing relative/package import style).
  - Delete `static const double _twoColumnBreakpoint = 600;` (line 189); keep the doc comment above `_buildReviewBody`, rewording to "at ≥ [AppBreakpoints.twoColumn] dp".
  - Line 194 becomes `final wide = AppBreakpoints.isTwoColumn(constraints.maxWidth);`
  - In the `_buildBento` doc comment, replace `[_twoColumnBreakpoint]` with `[AppBreakpoints.twoColumn]`.

- [ ] **Step 6: Run the review-screen tests — expect PASS (unchanged behavior)**

Run: `flutter test test/widgets/screens/community_review_screen_test.dart`
Expected: all pass, including `boundary: 600 is two-column, 599 is stacked`.

- [ ] **Step 7: Commit**

```bash
git -C /home/maortz/code/allergy-detector add app/lib/theme/app_breakpoints.dart app/test/unit/theme/app_breakpoints_test.dart app/lib/screens/community_review_screen.dart
```
```bash
git -C /home/maortz/code/allergy-detector commit -m "refactor(theme): add AppBreakpoints.twoColumn shared breakpoint (#410)" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

### Task 2: `CommunityScreen` uses the shared breakpoint on full body width

**Files:**
- Modify: `app/lib/screens/community_screen.dart:422-478`
- Test: `app/test/widgets/screens/community_screen_test.dart` (group `responsive layout (#324)`, ~line 664-699)

**Interfaces:**
- Consumes: `AppBreakpoints.isTwoColumn(double width) -> bool` (Task 1).
- Produces: `Widget _buildCommunitySections({required bool wide})` (private; signature change from `_buildCommunitySections()`).

- [ ] **Step 1: Write the failing boundary test** — add inside `group('responsive layout (#324)', ...)` after the narrow test, mirroring the CommunityReviewScreen boundary test:

```dart
testWidgets('boundary (#410): 600 is two-column, 599 is stacked',
    (tester) async {
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(createWidgetUnderTest());
  var helpCenter = tester.getCenter(find.text('עזרו לקהילה'));
  var peerCenter = tester.getCenter(find.text('בקרת עמיתים'));
  expect(
    peerCenter.dx,
    lessThan(helpCenter.dx - 100),
    reason: '600 dp viewport is the two-column threshold (≥ 600), '
        'same as CommunityReviewScreen',
  );
  expect(tester.takeException(), isNull);

  tester.view.physicalSize = const Size(599, 1200);
  await tester.pump();
  helpCenter = tester.getCenter(find.text('עזרו לקהילה'));
  peerCenter = tester.getCenter(find.text('בקרת עמיתים'));
  expect(
    peerCenter.dy,
    greaterThan(helpCenter.dy + 100),
    reason: '599 dp viewport stays single-column (< 600)',
  );
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run it — expect FAIL** on the first `expect` (today the `LayoutBuilder` sees 568 px, `568 > 600` is false → stacked).

Run: `flutter test test/widgets/screens/community_screen_test.dart --plain-name "boundary (#410)"`

- [ ] **Step 3: Implement**
  - Add `import '../theme/app_breakpoints.dart';` (match existing import style).
  - In `build`, wrap the existing `SingleChildScrollView` in a `LayoutBuilder` inside the `Directionality`: `LayoutBuilder(builder: (context, constraints) { final wide = AppBreakpoints.isTwoColumn(constraints.maxWidth); return SingleChildScrollView(...same as today..., _buildCommunitySections(wide: wide), ...); })`.
  - Delete `static const double _twoColumnBreakpoint = 600;`.
  - `_buildCommunitySections({required bool wide})`: remove its inner `LayoutBuilder`; `if (wide) { return IntrinsicHeight(Row(...)) }` else the existing `Column` — children, spacing, and order unchanged.
  - Update the doc comment: wide (≥ `AppBreakpoints.twoColumn`, measured on the full body width — the same box `CommunityReviewScreen` measures — not the padded content width) renders side-by-side; keep the RTL note.

- [ ] **Step 4: Run the CommunityScreen tests — expect PASS**

Run: `flutter test test/widgets/screens/community_screen_test.dart`
Expected: all pass (new boundary + existing wide 1200 / narrow 420 / dark-theme cases).
Contingency: if the 600 case fails with a `RenderFlex overflowed` exception inside a card (272 px wide), do NOT move the breakpoint; report the overflowing widget and fix it at its source (e.g. `Flexible`/`maxLines`+`TextOverflow.ellipsis` on the offending text) using theme tokens, then re-run.

- [ ] **Step 5: Confirm a single breakpoint definition**

Run: `grep -rn "_twoColumnBreakpoint\|>= 600\|> 600" /home/maortz/code/allergy-detector/app/lib`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git -C /home/maortz/code/allergy-detector add app/lib/screens/community_screen.dart app/test/widgets/screens/community_screen_test.dart
```
```bash
git -C /home/maortz/code/allergy-detector commit -m "fix(community): switch to two-column at >= 600 viewport like review screen (#410)" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

### Task 3: Full verification (from `app/`, one command per call)

- [ ] `flutter pub get` — exits 0.
- [ ] `flutter analyze lib test` — `No issues found!`
- [ ] `flutter test` — `All tests passed!` (record the final `+N` count for the PR body).
- If anything fails, use superpowers:systematic-debugging; do not proceed to A6+ until green.

### A6: Spec index update

File: `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`. No ✓/⚠/✗ symbol changes are warranted (both rows already Code ✓ / V-Spec ✓ / V-Art ✓; this is an internal consistency fix with no visual change against the art). Append notes only:

- Row 11 `community-hub` (line 35), V-Spec cell: before the cell's closing `)`, after `…guarded by two new \`community_screen_test\` cases`, append `; #410 unified the two-column breakpoint with Community Review — both screens now use the shared \`AppBreakpoints.isTwoColumn\` (≥ 600 dp, measured on full body width; previously \`> 600\` on padded content width, i.e. a ~632 dp viewport), guarded by a 600/599 boundary test`.
- Row 12 `community-review` (line 36), V-Spec cell: after `…at 390/599/600/1024/1920`, append `; #410 moved the threshold to the shared \`AppBreakpoints.twoColumn\` token (no behavior change)`.
- Commit:
```bash
git -C /home/maortz/code/allergy-detector add docs/superpowers/specs/2026-05-19-stitch-screens/index.md docs/superpowers/plans/2026-10-26-issue-410-unify-breakpoint.md
```
```bash
git -C /home/maortz/code/allergy-detector commit -m "docs(spec-index): note shared community breakpoint (#410)" -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

### A7: Drift check

- [ ] `git -C /home/maortz/code/allergy-detector fetch origin`
- [ ] `git -C /home/maortz/code/allergy-detector log origin/master..HEAD --oneline` — expect exactly the 3 commits from Task 1, Task 2, A6. If any foreign commit appears → STOP, report `STOPPED foreign commits on branch`, do not push.

### A8: Push + PR

- [ ] `git -C /home/maortz/code/allergy-detector push -u origin agent/issue-410-unify-breakpoint`
- [ ] `gh pr create --repo Maortz/allergy-detector --base master --head agent/issue-410-unify-breakpoint --title "fix(community): unify two-column breakpoint at >= 600 (#410)" --body "<body>"` with body:

```
Closes #410

## Summary
- New `AppBreakpoints` theme token (`app/lib/theme/app_breakpoints.dart`): `twoColumn = 600`, `isTwoColumn(width) => width >= 600`.
- `CommunityReviewScreen._buildReviewBody` uses the shared predicate (no behavior change).
- `CommunityScreen` now evaluates the breakpoint on the full body width (LayoutBuilder hoisted above the padded scroll view) with `>=`; previously `> 600` on padded content width meant it went two-column only at a ~632 dp viewport. Both screens now flip at exactly 600 dp.
- New 600/599 boundary widget test for CommunityScreen; unit tests for `AppBreakpoints`.
- Spec index notes for community-hub / community-review.
- Grep: no other ad hoc LayoutBuilder breakpoint literals in `app/lib`.

## Verification
- `flutter analyze lib test`: No issues found!
- `flutter test`: All tests passed! (+N)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### A9: Close the loop

- [ ] `gh issue comment 410 --repo Maortz/allergy-detector --body "Implemented in <PR URL>: shared AppBreakpoints.twoColumn (>= 600, full body width) used by CommunityScreen and CommunityReviewScreen, with a 600/599 boundary test."`
- [ ] `gh issue edit 410 --repo Maortz/allergy-detector --remove-label agent-in-progress`
