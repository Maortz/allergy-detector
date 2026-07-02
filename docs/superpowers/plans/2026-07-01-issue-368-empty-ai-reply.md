# Plan — Issue #368: guard against empty AI reply creating a blank chat bubble

Branch `agent/issue-368-empty-ai-reply` already created off master.

## Problem

In `AiFeedbackScreen._send()`, when `IssueAiService.send()` returns an empty
non-final reply (model returned `''`), a blank assistant bubble is appended —
no text, no action. Drop empty chat turns silently.

## Files

- `app/lib/screens/ai_feedback_screen.dart` — add guard in `_send()`.
- `app/test/widgets/screens/ai_feedback_screen_test.dart` — widget test: empty
  reply produces no new assistant bubble.
- `app/test/unit/services/issue_ai_service_test.dart` — document `AiReply.parse('')`.

## Tasks (TDD)

### Task 1 — Unit test documenting `AiReply.parse('')`

Add to the `AiReply.parse` group in `issue_ai_service_test.dart`:

```dart
test('empty input is a non-final, empty chat reply', () {
  final reply = AiReply.parse('');
  expect(reply.isFinal, isFalse);
  expect(reply.text, isEmpty);
});
```

Run `flutter test test/unit/services/issue_ai_service_test.dart` — passes
(behaviour already correct; this pins it).

### Task 2 — Failing widget test for the blank bubble

Add to `ai_feedback_screen_test.dart` a test that injects an AI session
returning `''`, sends a message, and asserts only the user's bubble is added
(assistant message count unchanged from the seed greeting). This fails before
the guard because a blank bubble is appended.

### Task 3 — Implement the guard

In `_send()`, after `if (!mounted) return;`:

```dart
if (!reply.isFinal && reply.text.isEmpty) {
  // Model returned an empty chat turn — drop it silently rather than
  // rendering a blank assistant bubble.
  return;
}
```

The `_sending` flag is still cleared by the existing `finally` block.

Re-run the widget test — passes.

## Verify

- `flutter pub get`
- `flutter analyze lib test` → 0 issues
- `flutter test` → all green

## A6 — Spec index

No shipped-screen spec row is affected (defensive service/screen fix, no visual
change). Skip index.md edits.

## A7 — Drift check

`git fetch origin && git log origin/master..HEAD --oneline` — foreign commits → STOP.

## A8 — Commit + PR

Body `Closes #368`, summary, analyze/test results. Commit footer
`Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

## A9 — Comment on #368 with PR link; release `agent-in-progress`.
