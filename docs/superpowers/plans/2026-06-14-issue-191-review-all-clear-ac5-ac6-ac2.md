# Plan — Issue #191: ReviewAllClear AC5 ghost-link, AC6 illustration + queue-exhaustion, AC2 glints

Branch: `agent/issue-191-review-all-clear-fixes`
Spec: `docs/superpowers/specs/2026-05-19-stitch-screens/review-all-clear.md` §4.2/§4.5/§4.6/§6.4/§7.5/§7.6

## Goal

Close the remaining pending acceptance criteria on `ReviewAllClearScreen` left after #22/#58:
AC5 (ghost-link affordance), AC6a (decorative illustration asset), AC6b (queue-exhaustion
routing), and AC2 (sparkle glints) — staying inside the `effort:S` scope (no new service
layer, no Supabase calls per spec §6.4).

## Tasks (TDD, one verify command at a time)

1. **AC6a asset** — Add a valid decodable `app/assets/images/review_all_clear.jpg`
   placeholder (real art to be swapped later) and register `assets/images/` under
   `flutter: assets:` in `pubspec.yaml`.
2. **AC5** — `_buildSecondaryLine()` returns a disabled `TextButton(onPressed: null)`
   (ghost-link affordance, non-navigating per §7.5) instead of a bare `Text`. Copy
   `"תוצאות הסקירה נשמרו בפרופיל שלך"`, Inter Regular 13 pt, `AppColors.outline` disabled
   foreground. Test: secondary line is a `TextButton` with null `onPressed`.
3. **AC6a render** — `_buildIllustration()` renders
   `Image.asset('assets/images/review_all_clear.jpg', fit: BoxFit.cover, excludeFromSemantics: true)`
   inside `ClipRRect(borderRadius: 12)`, 180 pt tall, full width, below the secondary line.
   Test: one `Image` with that asset name, `excludeFromSemantics: true`.
4. **AC2 glints** — Wrap the 96 pt hero circle in a `Stack(clipBehavior: Clip.none)` with
   four `_Glint` (`Icon(Icons.star, color: Color(0xFFBFDBFE))`) widgets at the diagonal
   corners. Test: `find.byIcon(Icons.star)` → 4.
5. **AC6b wiring** — Add `onQueueExhausted` callback to `CommunityReviewScreen`; fire it in
   `_advance()` when `_index >= queue.length` (queue drained by a *completed* review; the
   start-empty case keeps the inline empty state). Wire it in `community_screen.dart`:
   track session accumulators (`_sessionReviewed`, `_sessionPoints` at 10 pts/review,
   reset on `_onStartReview`) and `pushReplacement` `ReviewAllClearScreen` with those stats.
   Tests: exhaustion fires after last item; does NOT fire while items remain.
6. **Verify** — `flutter pub get`; `flutter analyze` (touched files: 0 issues); `flutter test`
   (all green).
7. **A6** — Update `index.md` row 14 V-Spec cell ⚠ → ✓ with the fix summary.
8. **A7** — `git fetch origin && git log origin/master..HEAD --oneline` (no foreign commits).
9. **A8/A9** — Commit (footer `Co-Authored-By: Claude Opus 4.8`), push, `gh pr create`
   (`Closes #191`), comment on the issue, release `agent-in-progress`.

## Notes

- AC2 implemented with pure Flutter widgets (no external asset) per the issue's stretch
  guidance.
- AC6a ships a small but valid placeholder JPEG (no AI image generation available in the
  agent environment); real art can replace it without code change.
