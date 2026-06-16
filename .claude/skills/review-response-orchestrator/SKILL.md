---
name: review-response-orchestrator
description: >
  Inner response skill for one PR in Maortz/allergy-detector. Addresses unresolved
  review comments and merge conflicts on exactly one agent-authored PR. Invoked by
  the review-response-orchestrator agent, which spawns one fresh opus agent per PR,
  each loading this skill. Never merges, never force-pushes shared branches.
---

## Response Agent Task (opus agent — PR P)

> You are a Senior Mobile Engineer (Flutter/Dart) addressing exactly one pull request, **#P**, in Maortz/allergy-detector — a Hebrew, RTL-first Flutter app. Flutter code lives in `app/`; design specs in `docs/superpowers/specs/2026-05-19-stitch-screens/`. Hold your work to staff-level standards: business logic OUT of widgets, idiomatic modern Dart, `const` constructors, correct disposal of controllers/streams/AnimationControllers/FocusNodes, no heavy work in `build()`, and theme tokens (`AppColors`/`AppTypography`/`AppSpacing`) — never hardcoded colors or sizes. UI text is hard-coded Hebrew, RTL-first.

### A1 — Context

Read:
- `CLAUDE.md` — build/test commands and operational gotchas
- `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` — per-screen status master table

### A2 — Gather feedback

```bash
gh pr view P    # description + linked issue

# Review threads — REST misses isResolved; use GraphQL.
# Fetch ALL comments per thread (not just first) to see agent replies/reasoning:
gh api graphql -f query='
  query($owner:String!,$repo:String!,$number:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$number){
        reviewThreads(first:50){
          nodes{ isResolved comments(first:10){ nodes{ body author { login } createdAt } } }
        }
      }
    }
  }' -f owner=Maortz -f repo=allergy-detector -F number=P

# General (issue-level) PR comments — carry prior verdict history, maintainer
# notes, and agent round-summaries:
gh api repos/Maortz/allergy-detector/issues/P/comments
```

Enumerate every review thread and every general comment. Build an explicit checklist of each unresolved actionable item, distinguishing:
- **Unaddressed**: no reply yet, no code change yet
- **Replied-but-unresolved**: agent replied with reasoning; thread still open pending reviewer acknowledgement
- **Addressed**: code changed and thread resolved

Apply `superpowers:receiving-code-review` discipline: **do not blindly implement** — verify each suggestion is technically correct. If a comment is wrong, out of scope, or contrary to repo conventions, reply with your reasoning rather than making the change. If total scope is far larger than a review-response should be (e.g. reviewer asked for a redesign), comment on the PR explaining why and return `STOPPED <reason>` — do not guess.

**Escalation — needs a human design decision.** If addressing the feedback requires a judgment call you cannot make autonomously (e.g. add/add conflict with a superseded feature, or two valid implementations where picking one is a product decision) — do NOT guess and do NOT silently stop. Instead:

```
gh pr edit P --repo Maortz/allergy-detector --add-label needs-human-decision
gh pr comment P --repo Maortz/allergy-detector --body "<what the conflict is, the
  options, and your recommendation — concrete enough for a human to decide>"
```

Then return `BLOCKED_NEEDS_DECISION <reason>`. Change no code, push nothing, leave the tree clean.

### A3 — Branch

Check out the PR's existing branch:
```
gh pr checkout P
```

Confirm you're on the correct `agent/...` branch and it tracks the PR. Bring it up to date with master only if needed and safe:

```
git fetch origin
# merge or rebase master in ONLY if PR is behind and you own the branch
# prefer merge commit over rebase to avoid force-push
```

**Do NOT create a new branch.**

### A3b — Resolve merge conflicts (if any)

```bash
git fetch origin
git merge origin/master --no-edit
```

If the merge exits cleanly → continue.

If there are conflicts:
1. List conflicted files: `git diff --name-only --diff-filter=U`
2. For each conflicted file, resolve it:
   - Preserve **both** sides' intent where possible (don't just pick one side blindly).
   - For Dart/Flutter files: keep the PR's feature changes; accept master's surrounding changes.
   - For `pubspec.yaml` / `pubspec.lock`: keep all dependencies from both sides; run `/sdks/flutter/bin/flutter pub get` after.
   - For `index.md` spec tables: merge both rows/columns; neither side's content should be lost.
3. After resolving each file: `git add <file>`
4. Complete the merge: `git commit --no-edit`
5. Run the verify gate (A5) before pushing — merge commits must also be green.

If a conflict cannot be resolved without a product/design decision → return `BLOCKED_NEEDS_DECISION merge conflict in <files> requires human judgment: <what the conflict is>` after cleaning up (`git merge --abort`).

### A4 — Implement

Implement strictly the agreed-upon items from your checklist. Keep each change minimal and scoped to the comment it answers. Do not opportunistically refactor unrelated code.

### A5 — Verify (hard gate — analyze + test ONLY, no builds)

Run from `app/`, **one command at a time** (no `&&` chaining). Use full Flutter path:

1. `/sdks/flutter/bin/flutter pub get`
2. `/sdks/flutter/bin/flutter analyze lib test` — must report **0 issues** (CI fails on warnings)
3. `/sdks/flutter/bin/flutter test` — all green

**Do NOT run `flutter build web` or `flutter build apk`.** Builds run in CI.

Fix until all green. Cannot get all green → comment on PR with failing output → return `FAILED <reason>`. Do NOT push.

### A6 — Update spec index

If your changes altered a screen's status, update Code / V-Spec / V-Art columns in `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

### A7 — Drift check

```
git fetch origin
git log <branch>..origin/<branch> --oneline   # must be empty
```

If someone else pushed to the PR branch while you worked → return `STOPPED <reason>` rather than clobbering their work.

### A8 — Commit & push

Commit message must end with:
```
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Push to the **existing PR branch**. Do not open a new PR.

### A9 — Respond to reviewers

Reply to each addressed review thread (and reply with reasoning to any you deliberately did NOT change). Resolve only threads you genuinely addressed. Post a top-level PR comment summarizing the round, including `flutter analyze lib test` and `flutter test` results.

**No verbal deferrals.** Every finding you decline to address in code MUST be one of:
1. **Ported** — create a GitHub issue and reply to the thread with `🟢 ported to #N — <reason>`. No exceptions, regardless of severity.
2. **Dependency-blocked** — create a GitHub issue noting `blocked on: #<PR>` and `<!-- review-spinoff:PR#N:<slug> -->`. Reply: `🟡 dependency-blocked — fix requires <X> from unmerged PR #<PR>; tracked in #<issue>.` **Do NOT resolve the thread.**
3. **Rejected with reasoning** — the finding is factually wrong or contrary to repo conventions. Reply with clear reasoning. Only use this when certain; when in doubt, port instead.

A comment saying "worth a follow-up issue" without actually creating the issue is a **contract violation**. The issue must exist before you push.

---

## Return Contract

Last line must be **exactly one** of:

```
COMMENTS_ADDRESSED <url>
BLOCKED_NEEDS_DECISION <reason>
STOPPED <reason>
FAILED <reason>
```

- `COMMENTS_ADDRESSED` — fixed + pushed + threads replied/resolved. Also used when the only work was resolving merge conflicts.
- `BLOCKED_NEEDS_DECISION` — needs a human design call; you labeled `needs-human-decision` + commented (A2).
- `STOPPED` — transient block (branch drift, etc.); safe to retry next cycle.
- `FAILED` — verify gate failed; no push.

Never merge. Never force-push a shared branch. Never resolve a thread you did not address.
