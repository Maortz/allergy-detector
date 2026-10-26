# Community Review Two-Column Bento (CR4, #392) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On viewports ≥ 600 dp, `CommunityReviewScreen` lays out its review body as the spec's two-column bento; below 600 dp the current single-column layout is unchanged.

**Architecture:** `_buildReviewBody` is wrapped in a `LayoutBuilder` placed *outside* the scroll padding, so `constraints.maxWidth` is the Scaffold body width (= viewport width) and the `≥ 600` test matches the issue's "viewport" wording exactly. The wide branch renders a start-aligned `Row` whose first child (RTL → right side) is the allergen-info card stacked above the decision panel (`flex: 7`), and whose second child (left side) is the product card (`flex: 5`). Pure layout change; no state, callbacks, or models touched.

**Tech Stack:** Flutter / Dart, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-05-19-stitch-screens/community-review.md` §2 "Main bento grid" (lines 37–68) and §7.6 row CR4. Issue: https://github.com/Maortz/allergy-detector/issues/392

**Branch:** `agent/issue-392-community-review-bento` is **already created** off up-to-date `master` and checked out. This plan file is committed on that branch. Execution starts at Task 1, Step 1.

## Global Constraints

- All `flutter`/`dart` commands run with cwd `/home/maortz/code/allergy-detector/app` — never prefix `cd app`. Git uses `git -C /home/maortz/code/allergy-detector`.
- ONE shell command per Bash call. No `&&`, `;`, or pipes chaining commands.
- Breakpoint: two-column iff body width `>= 600` (issue AC: "< 600 dp unchanged", "≥ 600 dp two-column"). Note: `CommunityScreen` (#324) uses `> 600`; do NOT change that file.
- Column split per spec §2: product card `col-span-5`, right column `col-span-7` → `Expanded(flex: 7)` / `Expanded(flex: 5)`. Gap between columns and between the two stacked right-column cards: 16 pt = `AppSpacing.md`.
- RTL column order (issue AC + spec "Right column"): allergen tiles on the **right** → allergen card is the **first** `Row` child (the Row inherits `TextDirection.rtl` from the screen's `Directionality`).
- Contributor note stays *inside* the allergen card (spec §2 Card A, CR6). The issue text loosely says "contributor info on the left"; the spec is prescriptive (repo convention: specs win) and the issue explicitly says "matching the spec's two-column bento". Mention this resolution in the PR body.
- Theme tokens only: `AppSpacing.*`, `colorScheme.*`, `AppTypography.*`. No hardcoded colors or new font sizes. All copy stays the existing hard-coded Hebrew — no new strings.
- Staff-level: no business logic in widgets (this is layout only); `const` on every constant widget (`SizedBox`, `EdgeInsets`); no new controllers (nothing new to dispose); breakpoint as a named `static const double`, not a magic number.
- Do NOT use `IntrinsicHeight` here (deviation from #324's pattern, deliberate): the subtree contains a `TextField` and `Image.network`; intrinsic passes are O(n²) and the right column is always taller than the 1:1 product card at the 7/5 split, so `CrossAxisAlignment.start` gives the same visual result cheaply. State this in the PR body.
- Widget tests that depend on viewport set `tester.view.physicalSize` + `tester.view.devicePixelRatio = 1.0`, with `addTearDown(tester.view.resetPhysicalSize)` and `addTearDown(tester.view.resetDevicePixelRatio)` (mirror `test/widgets/screens/community_screen_test.dart:664-699`).
- Default `flutter test` surface is 800×600 logical → the 12 pre-existing tests in `community_review_screen_test.dart` will now render the WIDE layout. They must stay green unmodified; the new narrow-layout test is what pins the mobile layout.
- Commit footer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Exact boundary 600 / 599** — 600 must be two-column, 599 single-column (off-by-one vs #324's `>`). Pinned by `boundary: 600 is two-column, 599 is stacked` in Task 1.
2. **Viewport resize while typing a rejection reason** (tablet rotation / browser resize) — the reason text must survive the narrow→wide switch because `_reasonController` lives on the State. Pinned by `rejection reason survives a narrow→wide resize` in Task 1.
3. **Very wide web window (1920×1080)** — no `RenderFlex` overflow / exceptions; layout still two-column. Pinned by `very wide web viewport renders without exception` in Task 1.
4. **Dark theme at wide width** — #291 regression guard must hold in the new branch. Pinned by `wide layout renders under the dark theme without exception` in Task 1.
5. **Decision buttons still reachable/tappable in wide layout** — covered implicitly: the 12 existing approve/reject/in-flight tests run at the default 800-wide surface, i.e. the wide branch. No extra test needed; Task 1 Step 4 verifies the whole file is green.

---

### Task 1: Adaptive two-column bento in `CommunityReviewScreen`

**Files:**
- Modify: `app/lib/screens/community_review_screen.dart:187-207` (`_buildReviewBody`), plus a new private `static const` and a new private builder method placed directly after `_buildReviewBody`.
- Test: `app/test/widgets/screens/community_review_screen_test.dart` (append a `group` at the end of `main()`, after the dark-theme test at line 342).

**Interfaces:**
- Consumes (existing, unchanged): `_buildCounterRow()`, `_buildProductCard(PendingReview)`, `_buildAllergenCard(PendingReview)`, `_buildDecisionPanel()`, `_buildHistoryStrip()`, `widget.pastContributions`.
- Produces (private, in `_CommunityReviewScreenState`):
  - `static const double _twoColumnBreakpoint = 600;`
  - `Widget _buildBento(PendingReview review, {required bool wide})` — returns the wide `Row` or the narrow children wrapped in a `Column` (crossAxisAlignment `stretch`).

- [ ] **Step 1: Write the failing tests**

Append to `app/test/widgets/screens/community_review_screen_test.dart`, inside `main()` after the last test. Reuses the file's existing `review(...)`, `host(...)` helpers and the `buildDarkAppTheme` import.

```dart
  group('responsive bento layout (CR4, #392)', () {
    void setSurface(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    const productName = 'משקה שיבולת שועל';
    const allergenHeader = 'מידע על אלרגנים שהוזן:';
    const decisionHeader = 'החלטה למוצר זה:';

    testWidgets('wide viewport: allergen + decision column on the right, '
        'product card on the left', (tester) async {
      setSurface(tester, const Size(1024, 1366));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));

      final mid = tester.view.physicalSize.width / 2;
      final product = tester.getCenter(find.text(productName));
      final allergen = tester.getCenter(find.text(allergenHeader));
      final decision = tester.getCenter(find.text(decisionHeader));

      // RTL: allergen card + decision panel occupy the right column,
      // product card the left column.
      expect(product.dx, lessThan(mid));
      expect(allergen.dx, greaterThan(mid));
      expect(decision.dx, greaterThan(mid));
      // Side-by-side: the allergen header sits in the same vertical band as
      // the product card, above the product name (which is under the 1:1
      // image), not stacked below it.
      expect(allergen.dy, lessThan(product.dy));
      // Right column stacks: decision panel below the allergen card.
      expect(decision.dy, greaterThan(allergen.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow viewport keeps the single-column order',
        (tester) async {
      setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));

      final product = tester.getTopLeft(find.text(productName));
      final allergen = tester.getTopLeft(find.text(allergenHeader));
      final decision = tester.getTopLeft(find.text(decisionHeader));

      // Stacked in source order: product → allergen card → decision panel.
      expect(allergen.dy, greaterThan(product.dy));
      expect(decision.dy, greaterThan(allergen.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('boundary: 600 is two-column, 599 is stacked', (tester) async {
      setSurface(tester, const Size(600, 1200));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));
      expect(
        tester.getCenter(find.text(allergenHeader)).dy,
        lessThan(tester.getCenter(find.text(productName)).dy),
        reason: '600 dp is the two-column threshold (≥ 600)',
      );

      setSurface(tester, const Size(599, 1200));
      await tester.pump();
      expect(
        tester.getCenter(find.text(allergenHeader)).dy,
        greaterThan(tester.getCenter(find.text(productName)).dy),
        reason: '599 dp stays single-column (< 600)',
      );
    });

    testWidgets('rejection reason survives a narrow→wide resize',
        (tester) async {
      setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));
      await tester.enterText(find.byType(TextField), 'מידע שגוי');

      setSurface(tester, const Size(1024, 1366));
      await tester.pump();

      expect(find.text('מידע שגוי'), findsOneWidget);
      expect(
        tester.getCenter(find.text(allergenHeader)).dy,
        lessThan(tester.getCenter(find.text(productName)).dy),
      );
    });

    testWidgets('very wide web viewport renders without exception',
        (tester) async {
      setSurface(tester, const Size(1920, 1080));
      await tester.pumpWidget(host(CommunityReviewScreen(
        queue: [review('a', productName)],
      )));
      expect(tester.takeException(), isNull);
      expect(find.text(decisionHeader), findsOneWidget);
    });

    testWidgets('wide layout renders under the dark theme without exception',
        (tester) async {
      setSurface(tester, const Size(1024, 1366));
      await tester.pumpWidget(host(
        CommunityReviewScreen(queue: [review('a', productName)]),
        theme: buildDarkAppTheme(),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('מכיל בוודאות'), findsOneWidget);
    });
  });
```

Note on the wide assertion `allergen.dy < product.dy`: the product name sits below a 1:1 image (≈ 390 px tall at 1024 width), while the allergen header is the first row of the right column, so it is far above the product name only when the columns are side-by-side. In the narrow layout the allergen card comes after the whole product card, so the inequality flips.

Calling `setSurface` twice in one test registers duplicate tearDowns; that is harmless (reset is idempotent).

- [ ] **Step 2: Run the new group to verify it fails**

Run (cwd `app/`): `flutter test test/widgets/screens/community_review_screen_test.dart --plain-name "responsive bento layout"`
Expected: FAIL — `wide viewport…`, `boundary…` (600 half) and `rejection reason survives…` fail on the `dy`/`dx` expectations (current layout is always stacked). `narrow viewport…`, `very wide…`, `dark theme…` may already pass; that is fine.

- [ ] **Step 3: Implement the bento in `app/lib/screens/community_review_screen.dart`**

Replace `_buildReviewBody` (lines 187–207) so that:
- It returns `LayoutBuilder(builder: (context, constraints) { ... })` wrapping the existing `SingleChildScrollView` (padding `const EdgeInsets.all(AppSpacing.md)`, `Column` with `CrossAxisAlignment.stretch`) — the LayoutBuilder is OUTSIDE the padding so `maxWidth` is the viewport width.
- `final wide = constraints.maxWidth >= _twoColumnBreakpoint;`
- Column children: `_buildCounterRow()`, `const SizedBox(height: AppSpacing.lg)`, `_buildBento(review, wide: wide)`, then the unchanged history-strip block (`if (widget.pastContributions.isNotEmpty) ...[const SizedBox(height: AppSpacing.xl), _buildHistoryStrip()]`).

Add above `_buildReviewBody` (doc comment + constant):

```dart
  /// Spec §2 / CR4: at ≥ 600 dp (tablet / web) the review body switches to the
  /// two-column bento; below it the mobile single-column stack is kept.
  static const double _twoColumnBreakpoint = 600;
```

Add `Widget _buildBento(PendingReview review, {required bool wide})` directly after `_buildReviewBody`:
- `wide == false` → `Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ _buildProductCard(review), const SizedBox(height: AppSpacing.md), _buildAllergenCard(review), const SizedBox(height: AppSpacing.md), _buildDecisionPanel() ])` — identical order/spacing to today.
- `wide == true` → `Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ Expanded(flex: 7, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [ _buildAllergenCard(review), const SizedBox(height: AppSpacing.md), _buildDecisionPanel() ])), const SizedBox(width: AppSpacing.md), Expanded(flex: 5, child: _buildProductCard(review)) ])`.
- Doc comment on `_buildBento` must state: RTL → first Row child renders on the right, so the allergen/decision column (spec "Right column", col-span-7) is first and the product card (col-span-5) lands on the left; `CrossAxisAlignment.start` instead of `IntrinsicHeight` because the subtree holds a `TextField` + network image and the right column is always the taller one.

No other method changes. `_card` already uses `width: double.infinity`, which is correct inside `Expanded`.

- [ ] **Step 4: Run the whole screen test file**

Run (cwd `app/`): `flutter test test/widgets/screens/community_review_screen_test.dart`
Expected: PASS — all 12 pre-existing tests + 6 new tests green (`All tests passed!`).

If a pre-existing test fails because a target is off-screen at 800×600, the fix is in the test helper only if `ensureVisible` is missing for that call — do not change layout values to make it pass. (Analysis says none should fail: every tap already uses `ensureVisible`.)

- [ ] **Step 5: Commit**

```bash
git -C /home/maortz/code/allergy-detector add app/lib/screens/community_review_screen.dart app/test/widgets/screens/community_review_screen_test.dart
```
```bash
git -C /home/maortz/code/allergy-detector commit -m "feat(community-review): two-column bento layout at >=600dp (CR4, #392)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Full verification

- [ ] **Step 1:** Run (cwd `app/`): `flutter pub get` — Expected: `Got dependencies!` (or "Resolving dependencies… Got dependencies"), no errors.
- [ ] **Step 2:** Run (cwd `app/`): `flutter analyze lib test` — Expected: `No issues found!` (0 issues, warnings included — CI fails on warnings).
- [ ] **Step 3:** Run (cwd `app/`): `flutter test` — Expected: `All tests passed!`. Record the pass count for the PR body.

If anything fails: fix, re-run the failing command, then re-run Steps 2–3. Use superpowers:systematic-debugging for non-obvious failures. Do not proceed with red results.

---

### Task 3 (A6): Update the spec index and CR4 delta

**Files:**
- Modify: `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` line 36 (row 12) and the "Status summary" bullet at line 143.
- Modify: `docs/superpowers/specs/2026-05-19-stitch-screens/community-review.md` lines 293 and 302 (§7.6).

- [ ] **Step 1: Row 12 of `index.md`.** Columns are `| # | Stitch title | Slug | Dart file | Stitch | Spec | Code | V-Spec | V-Art | Screen ID |`.
  - Code: stays `✓`.
  - V-Spec: replace `⚠ CR4 only (V-Spec 2026-07-01: CR1–CR3, CR5–CR11 all resolved — #39, #46, #54, #175, #255, #291; CR4 open: adaptive two-column bento layout for tablet/web viewports, tracked in #392; V-Art ✓ 2026-06-14 mobile single-column confirmed)` with
    `✓ (V-Spec 2026-10-25: CR1–CR11 resolved — #39, #46, #54, #175, #255, #291, #392. CR4 (#392): ≥ 600 dp renders the two-column bento — allergen-info card + decision panel in the right column (flex 7), product card left (flex 5); < 600 dp keeps the mobile single-column stack; guarded by viewport widget tests at 390/599/600/1024/1920)`
  - V-Art: keep the existing text; append before the closing `)`: `; 2026-10-25 (#392): mobile art unchanged below 600 dp — the wide bento has no dedicated Stitch art and follows spec §2 grid-cols-12 (5/7)`.
- [ ] **Step 2: Status summary bullet (line 143).** Replace `  - **community-review CR4**: adaptive two-column bento for tablet/web → **#392**` with `  - ~~**community-review CR4**: adaptive two-column bento for tablet/web~~ → resolved in **#392**`.
- [ ] **Step 3: `community-review.md` §7.6.** Line 293 current-code cell → `✅ **FIXED 2026-10-25 (#392)** — `_buildBento` switches to a 7/5 two-column Row at ≥ 600 dp (allergen + decision right, product left in RTL); single column below`. Line 302 → `**Remaining:** CR11 (Supabase wiring pending `pending_reviews` table).`
- [ ] **Step 4: Commit**

```bash
git -C /home/maortz/code/allergy-detector add docs/superpowers/specs/2026-05-19-stitch-screens/index.md docs/superpowers/specs/2026-05-19-stitch-screens/community-review.md
```
```bash
git -C /home/maortz/code/allergy-detector commit -m "docs(v-spec): mark community-review CR4 resolved (#392)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4 (A7): Drift check

- [ ] **Step 1:** `git -C /home/maortz/code/allergy-detector fetch origin`
- [ ] **Step 2:** `git -C /home/maortz/code/allergy-detector log origin/master..HEAD --oneline`
  Expected: exactly the commits from this plan — the plan commit (`docs(plan): ... #392`), the Task 1 `feat(community-review)` commit, the Task 3 `docs(v-spec)` commit (plus any fix-up commits you made for #392).
  If ANY commit not belonging to issue #392 appears (concurrent agents share the working copy) → do NOT push; report `STOPPED foreign commits on branch: <hashes>`.
- [ ] **Step 3:** If `origin/master` moved ahead, check `git -C /home/maortz/code/allergy-detector log HEAD..origin/master --oneline -- app/lib/screens/community_review_screen.dart app/test/widgets/screens/community_review_screen_test.dart docs/superpowers/specs/2026-05-19-stitch-screens/index.md`. Non-empty → rebase is needed: `git -C /home/maortz/code/allergy-detector rebase origin/master`, resolve, re-run Task 2. (Never force-push a shared branch; this branch is unpushed at this point so a rebase is safe.)

---

### Task 5 (A8): Push and open the PR

- [ ] **Step 1:** `git -C /home/maortz/code/allergy-detector push -u origin agent/issue-392-community-review-bento`
- [ ] **Step 2:** Create the PR (single command, body via `--body`):

```bash
gh pr create --repo Maortz/allergy-detector --base master --head agent/issue-392-community-review-bento --title "feat(community-review): adaptive two-column bento for tablet/web (CR4, #392)" --body "Closes #392

## Summary
- \`CommunityReviewScreen\` review body is now viewport-adaptive via a \`LayoutBuilder\` (outside the scroll padding, so it measures the real viewport width).
- **≥ 600 dp:** spec §2 bento — right column (flex 7): allergen-info card (tiles + contributor note) stacked over the decision panel; left column (flex 5): product image/info card. RTL Row order puts the allergen tiles on the right.
- **< 600 dp:** unchanged single-column stack (product → allergens → decision).
- Contributor note stays inside the allergen card per spec §2 Card A / CR6 (the issue text said \"contributor info on the left\" but defers to the spec bento).
- \`CrossAxisAlignment.start\` instead of #324's \`IntrinsicHeight\`: subtree holds a TextField + network image; the right column is always the taller one, so stretching buys nothing.
- Spec index row 12 V-Spec ⚠ CR4 → ✓; community-review.md §7.6 CR4 marked fixed.

## Tests
New group \`responsive bento layout (CR4, #392)\`: wide 1024 column placement, narrow 390 stacking, 600/599 boundary, narrow→wide resize keeps the rejection reason, 1920 web no-exception, wide dark theme. Existing 12 tests unchanged and green (they run at the default 800×600 surface, i.e. the wide branch).

## Verification
- \`flutter analyze lib test\`: <paste result, expected No issues found!>
- \`flutter test\`: <paste result, e.g. All tests passed! (N tests)>

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

Replace the two `<paste …>` markers with the actual output lines from Task 2 before running — they are the only fill-ins and must be real results.

Expected: prints the PR URL. Record it.

---

### Task 6 (A9): Link and release the claim

- [ ] **Step 1:** `gh issue comment 392 --repo Maortz/allergy-detector --body "Implemented in <PR URL> — two-column bento at ≥ 600 dp, single column below; analyze clean, tests green."` (substitute the real PR URL).
- [ ] **Step 2:** `gh issue edit 392 --repo Maortz/allergy-detector --remove-label agent-in-progress`
- [ ] **Step 3:** Never merge, never approve, never force-push.
