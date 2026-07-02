# Pipeline Efficiency & Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the empty-commit → re-review churn loop, stop cancelling master CI runs, fix the broken in-container cron, and add merge-ready labeling, persistent logs, adaptive backoff, cost telemetry, and a backlog scanner to the autonomous agent pipeline.

**Architecture:** The pipeline is GitHub-as-state-machine: skills in `.claude/skills/` drive issue→PR→review→merge flow, cron (supercronic) in the Docker container is a watchdog, and GitHub rulesets enforce the gates. All changes here are to workflow YAML, skill markdown (which IS the executable spec for agents), and Docker plumbing — no Flutter app code.

**Tech Stack:** GitHub Actions, `gh` CLI, GraphQL API, git patch-id, tmux + supercronic + flock, Docker Compose, Claude Code skills.

## Verification findings (2026-07-02) — read before executing

Points from the original analysis that are **already fixed — do NOT re-implement**:

| Claimed gap | Actual state (verified) |
|---|---|
| "No branch protection on master" | **Wrong.** Rulesets `master` (id 17539841) + `master deletion` (id 17659326) are active: deletion + force-push blocked, linear history, PR required, review-thread resolution required, required checks `Analyze, Test & Build (web)` + `Build debug APK`, Copilot code review on push. (Classic protection API returns 404 because rulesets are used — that misled the original analysis.) |
| "No APK build in PR CI / add nightly APK" | **Wrong.** `ci.yml` has a blocking `apk` job and an advisory `ios` job on every PR. No nightly needed. |
| "No CODEOWNERS" | **Wrong.** `.github/CODEOWNERS` exists (`* @Maortz`). |
| "Second reviewer identity needed" | **Reinstated as Task 11** (maintainer decision 2026-07-02). The ruleset's `copilot_code_review` rule is active but **inert** — verified zero Copilot-authored reviews on PRs #386–#395; every review is by `Maortz` and GitHub caps same-account reviews at COMMENTED. A machine reviewer account unlocks real APPROVE/REQUEST_CHANGES states, a GitHub-enforced required-review gate, and safe auto-merge (Task 10). |

Points **verified still open** (these are the tasks below):

| Gap | Evidence |
|---|---|
| Empty-commit CI re-trigger invalidates review markers → full re-review of identical diffs | `merge-verdict/SKILL.md:59` + Phase C (lines 145–161); `review-orchestrator/SKILL.md:199` acknowledges the churn; PRs #394/#395 accumulated 4 reviews each |
| Master push CI runs cancelled by concurrency | `ci.yml:12` `cancel-in-progress: true` unconditional; 19 of last 100 runs cancelled |
| In-container cron is broken | `orchestrators.crontab` does `cd ~/allergy-detector` — that path does not exist in the container (repo is at `/workspace`); crontab also predates the agent-pipeline watchdog design and its log paths don't match `entrypoint.sh:109` |
| Pipeline logs ephemeral | Logs go to `/tmp` inside the container; no volume; `make pipeline-log` tails `/tmp/agent-pipeline.log` |
| Backoff fixed + internally inconsistent | `agent-pipeline/SKILL.md` says "default: 30 min" in the loop pseudocode and "sleep 60 minutes" in the backoff section |
| No merge-ready signal for the human | merge-verdict posts comments only; no label to filter on (`gh label list` confirms no `merge-ready`) |
| Auto-merge disabled | repo `allow_auto_merge: false` (policy-gated opt-in, Task 10) |
| No cost telemetry | nothing in docker/ or skills references usage tracking |
| No backlog generation | 2 open issues, 1 blocked — pipeline starves; no scanner skill exists |

## Global Constraints

- Repo: `Maortz/allergy-detector`. Default branch: `master`. Container repo path: `/workspace` (never `~/allergy-detector`).
- **Never force-push. Never rebase PR branches — use `git merge`** (maintainer rule; force-push triggers re-review and disrupts collaborators).
- Review/merge invariants must survive every skill edit: review-orchestrator is comment-only (never approve/request-changes/merge/push/edit code); merge-verdict never merges or approves (Task 10 relaxes this only behind explicit maintainer opt-in).
- Skill files keep valid YAML frontmatter (`name`, `description`) — a broken frontmatter silently disables the skill.
- Ruleset `master` requires status checks `Analyze, Test & Build (web)` and `Build debug APK` on the PR head SHA, requires linear history, and has `dismiss_stale_reviews_on_push: true`. `required_approving_review_count` is 0.
- Crontab is parsed by **supercronic** (runs as user `dev`, started by `entrypoint.sh` when `ENABLE_CRON=1`). Avoid complex quoting in crontab lines — put logic in shell scripts copied to `/opt/claude/`.
- Docker container runs as `dev` (UID 1001). Named volumes inherit ownership from the image directory at first mount — `chown` new mount points in the Dockerfile.
- Commit messages: conventional commits, ending with `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`.
- Verification for YAML: `yq eval . <file> > /dev/null` (yq is installed). For shell scripts: `bash -n <file>`.

---

## Tier S — small (~1 file, <1h each)

### Task 1: ci.yml — keep master runs, enable manual dispatch

**Files:**
- Modify: `.github/workflows/ci.yml:3-12`

**Interfaces:**
- Produces: `workflow_dispatch` trigger on the `CI` workflow — Task 4's `gh workflow run ci.yml --ref <branch>` fallback depends on this.
- Produces: master `push` runs are no longer cancelled by later pushes (only `pull_request` runs cancel).

- [ ] **Step 1: Edit the trigger and concurrency blocks**

In `.github/workflows/ci.yml`, replace:

```yaml
on:
  pull_request:
    branches: [master]
  push:
    branches: [master]

# Cancel superseded runs on the same ref to save runner minutes.
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

with:

```yaml
on:
  pull_request:
    branches: [master]
  push:
    branches: [master]
  # Manual/API re-trigger without pushing a commit (used by merge-verdict).
  workflow_dispatch:

# Cancel superseded PR runs to save runner minutes — but never cancel master
# push runs: every master commit must finish CI so mid-burst breakage is caught.
concurrency:
  group: ci-${{ github.ref }}-${{ github.event_name }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

(Note `github.event_name` added to the group: without it, a `workflow_dispatch` run and a `pull_request` run on the same ref would share a group and could cancel each other.)

- [ ] **Step 2: Verify YAML parses**

Run: `yq eval . .github/workflows/ci.yml > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add workflow_dispatch trigger; stop cancelling master push runs

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

- [ ] **Step 4: After this lands on master, verify dispatch works**

Run: `gh workflow run ci.yml --repo Maortz/allergy-detector --ref master && sleep 10 && gh run list --repo Maortz/allergy-detector --workflow ci.yml --limit 1 --json event --jq '.[0].event'`
Expected: `workflow_dispatch`
(If executing on a PR branch, defer this step until after merge — note it in the PR body.)

### Task 2: agent-pipeline — fix backoff inconsistency, add idle backoff

**Files:**
- Modify: `.claude/skills/agent-pipeline/SKILL.md` (two locations)

**Interfaces:**
- Produces: pipeline sleeps 4h after a fully idle cycle instead of 60 min — cuts idle-period token burn ~4×.

- [ ] **Step 1: Fix the pseudocode backoff value**

In `.claude/skills/agent-pipeline/SKILL.md`, in the `## Pipeline Loop` code block, replace the line:

```
  backoff (default: 30 min)
```

with:

```
  backoff (60 min; 4 h after a fully idle cycle)
```

- [ ] **Step 2: Add the adaptive rule to the backoff section**

Replace:

```
After all four stages complete (or are skipped): **sleep 60 minutes**.
```

with:

```
After all four stages complete (or are skipped): **sleep 60 minutes** — unless
the cycle was **fully idle**: stage 1 claimed zero issues AND there were zero
open non-draft PRs at cycle start (check with
`gh pr list --repo Maortz/allergy-detector --state open --draft=false --json number --jq length`).
After a fully idle cycle, **sleep 4 hours** instead. Any new issue or PR resets
to the 60-minute cadence on the next non-idle cycle.
```

- [ ] **Step 3: Verify no other conflicting backoff values remain**

Run: `grep -n '30 min\|sleep 60\|60 minutes\|4 hours' .claude/skills/agent-pipeline/SKILL.md`
Expected: only the two edited locations; no remaining `30 min`.

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/agent-pipeline/SKILL.md
git commit -m "docs(agent-pipeline): reconcile backoff to 60min, add 4h idle backoff

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### Task 3: merge-ready label — one-glance merge queue for the human

**Files:**
- Modify: `.claude/skills/merge-verdict/SKILL.md` (Step 5 section + Constraints)
- Repo state: create label via `gh`

**Interfaces:**
- Produces: `merge-ready` label, applied/removed by merge-verdict. Human filters with `gh pr list --label merge-ready`. Task 10 (if ever approved) keys auto-merge off this label.

- [ ] **Step 1: Create the label**

```bash
gh label create merge-ready --repo Maortz/allergy-detector \
  --color 0E8A16 \
  --description "Passed review + conflict gates with green CI; awaiting maintainer merge"
```

Expected: label created (or "already exists" — fine, idempotent).

- [ ] **Step 2: Add label-sync to merge-verdict Step 5**

In `.claude/skills/merge-verdict/SKILL.md`, after the paragraph:

```
Anti-spam: before posting, check the PR's most recent comment — if it already
carries an identical verdict, skip the post.
```

insert:

```
**Label sync (always, even when the verdict post was skipped as duplicate):**

- Verdict is `✅ READY TO MERGE` →
  `gh pr edit <n> --repo Maortz/allergy-detector --add-label merge-ready`
- Any other verdict →
  `gh pr edit <n> --repo Maortz/allergy-detector --remove-label merge-ready`
  (removing an absent label is a no-op — always safe to run).

This makes `gh pr list --label merge-ready` the maintainer's one-glance merge queue.
```

- [ ] **Step 3: Allow the write in Constraints**

In the `## Constraints` section of the same file, append at the **end of the
section** (after the last existing bullet — do NOT insert between existing
bullets; Task 4 later replaces those as one contiguous block):

```
- Adding/removing the `merge-ready` label on PRs is also an allowed write
  (verdict labeling only — never any other label).
```

- [ ] **Step 4: Verify frontmatter still valid**

Run: `yq eval --front-matter=extract .name .claude/skills/merge-verdict/SKILL.md`
Expected: `merge-verdict`

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/merge-verdict/SKILL.md
git commit -m "feat(merge-verdict): sync merge-ready label with verdicts

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Tier M — medium (few files, half-day each)

### Task 4: merge-verdict — re-run CI instead of pushing empty commits

**Depends on:** Task 1 (workflow_dispatch on ci.yml) merged to master.

The core churn fix. Empty commits advance `headRefOid`, which (a) stales the `staff-review:<HEAD_SHA>` marker → full re-review of an identical tree, and (b) trips `dismiss_stale_reviews_on_push`. `gh run rerun` / `gh workflow run` re-run CI on the **same** SHA — markers stay valid, no re-review.

**Files:**
- Modify: `.claude/skills/merge-verdict/SKILL.md` (frontmatter description, Overview, Gates, "The CI workflow", Phase B, Phase C, Constraints)
- Modify: `.claude/skills/agent-pipeline/SKILL.md` (Stage 4 dispatch brief)

**Interfaces:**
- Consumes: `workflow_dispatch` trigger from Task 1.
- Produces: merge-verdict never pushes commits. Task 5's patch-id fast path becomes mostly a safety net for master-merge SHA bumps.

- [ ] **Step 1: Update frontmatter description**

In `.claude/skills/merge-verdict/SKILL.md` frontmatter, replace:

```
  for every PR; then, for review-passing PRs lacking a green CI run, pushes an
  empty commit to re-trigger CI. Never merges or approves.
```

with:

```
  for every PR; then, for review-passing PRs lacking a green CI run, re-runs
  the existing CI run (or dispatches a fresh one) — never by pushing commits.
  Never merges or approves.
```

- [ ] **Step 2: Update Overview**

Replace:

```
2. **Re-trigger CI** for PRs that pass review but have no current green CI run.
   This pushes an empty commit to each affected PR branch to fire a new run.

Never merge, approve, or request-changes. The only writes this skill performs
are: verdict comments on PRs and empty commits on PR branches.
```

with:

```
2. **Re-trigger CI** for PRs that pass review but have no current green CI run —
   by re-running the run already attached to the head SHA (`gh run rerun`), or
   dispatching the workflow on the branch (`gh workflow run`). Never by pushing
   a commit: pushes advance `headRefOid`, stale the `staff-review` marker, and
   force a pointless re-review of an identical diff.

Never merge, approve, or request-changes. The only writes this skill performs
are: verdict comments, `merge-ready` labeling, and CI re-runs/dispatches.
```

- [ ] **Step 3: Update "The CI workflow" section**

Replace:

```
- Triggers on `pull_request`/`push` to `master` — no `workflow_dispatch`. The only way to fire it for a PR is a new commit on the PR branch (`synchronize` event), which is why Phase C pushes an empty commit.
```

with:

```
- Triggers on `pull_request`/`push` to `master`, plus `workflow_dispatch` for
  manual/API re-triggering. Check runs attach to the commit SHA, so a dispatch
  run on the PR branch's current head satisfies the ruleset's required status
  checks for that PR — no commit needed.
```

- [ ] **Step 4: Stop treating pending runs as candidates**

In the Gates section, replace:

```
run, or a pending run is **not green** and (if it also passes review + conflict
gates) is a candidate for re-trigger.
```

with:

```
run is **not green** and (if it also passes review + conflict gates) is a
candidate for re-trigger. A **pending/in-progress** run is not green either,
but it is NOT a re-trigger candidate — a run is already underway; post `⏳`
and let the next cycle read its result. (You cannot `gh run rerun` an
in-progress run anyway.)
```

- [ ] **Step 5: Fix the Phase B empty-commit mention**

Replace:

```
  is never a CI re-trigger candidate (CI can't help a conflicted branch; it needs
  master merged in first). Re-triggering would also waste an empty commit.
```

with:

```
  is never a CI re-trigger candidate (CI can't help a conflicted branch; it needs
  master merged in first — the review-response loop does that).
```

- [ ] **Step 6: Replace Phase C entirely**

Replace the whole `### 4 — Phase C: re-trigger CI` section body (the paragraph `Only run this when Phase B found ≥1 candidate.`, the ```bash code block pushing an empty commit via the refs API, and the `Do **not** wait...` line) with:

````
Only run this when Phase B found ≥1 candidate.

```bash
SHA=$(gh pr view <n> --repo Maortz/allergy-detector --json headRefOid -q .headRefOid)
BRANCH=$(gh pr view <n> --repo Maortz/allergy-detector --json headRefName -q .headRefName)

# Prefer re-running the run already attached to this exact SHA (keeps the
# pull_request event context). Fall back to a workflow_dispatch on the branch —
# its check runs attach to the same SHA and satisfy the required checks.
RUN_ID=$(gh run list --repo Maortz/allergy-detector --workflow ci.yml \
  --branch "$BRANCH" --limit 10 --json databaseId,headSha \
  --jq "[.[] | select(.headSha == \"$SHA\")][0].databaseId // empty")

if [ -n "$RUN_ID" ]; then
  gh run rerun "$RUN_ID" --repo Maortz/allergy-detector \
    || gh workflow run ci.yml --repo Maortz/allergy-detector --ref "$BRANCH"
else
  gh workflow run ci.yml --repo Maortz/allergy-detector --ref "$BRANCH"
fi
```

Never push a commit (empty or otherwise) to any branch — that is the old
mechanism this replaced; it invalidated review markers and forced re-reviews.

Do **not** wait for runs to finish. Their green/red result is picked up by a later merge-verdict run.
````

- [ ] **Step 7: Rewrite Constraints**

Replace:

```
- The only writes allowed: verdict comments on PRs and empty commits on candidate
  PR branches. Nothing else.
- Pushing an empty commit advances `headRefOid`; if branch protection has
  "dismiss stale reviews" enabled this re-opens the review gate next run. That
  is acceptable — the PR simply isn't READY until re-reviewed.
```

with:

```
- The only writes allowed: verdict comments on PRs, `merge-ready` label
  add/remove, and CI re-runs/dispatches (`gh run rerun` / `gh workflow run`).
  Nothing else — in particular, NEVER push a commit to any branch.
```

(If Task 3 already appended its label bullet after this block, leave that bullet in place — it is now redundant with the rewritten text; delete it.)

- [ ] **Step 8: Update the agent-pipeline Stage 4 brief**

In `.claude/skills/agent-pipeline/SKILL.md`, in the Stage 4 dispatch brief, replace:

```
audit the review gate, then for review-passing PRs lacking a green CI run on their current head, enable the `CI` workflow, push an empty commit to re-trigger it, wait until each run is queued, then disable the workflow again. Post verdict comments.
```

with:

```
audit the review gate, then for review-passing PRs lacking a green CI run on their current head, re-trigger CI via `gh run rerun` (or `gh workflow run ci.yml --ref <branch>` when no run exists for the head SHA) — never by pushing commits, never by enabling/disabling the workflow. Post verdict comments and sync the `merge-ready` label.
```

- [ ] **Step 9: Verify no empty-commit references remain**

Run: `grep -rn 'empty commit' .claude/skills/merge-verdict/SKILL.md .claude/skills/agent-pipeline/SKILL.md`
Expected: at most the historical "that is the old mechanism" note in Phase C; nothing prescriptive.

- [ ] **Step 10: Verify frontmatter + commit**

Run: `yq eval --front-matter=extract .name .claude/skills/merge-verdict/SKILL.md`
Expected: `merge-verdict`

```bash
git add .claude/skills/merge-verdict/SKILL.md .claude/skills/agent-pipeline/SKILL.md
git commit -m "feat(merge-verdict): re-trigger CI via rerun/dispatch, never empty commits

Empty commits advanced headRefOid, invalidating staff-review markers and
forcing full re-reviews of identical diffs (see PRs #394/#395: 4 reviews each).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### Task 5: review-orchestrator — skip re-review when the diff is unchanged (patch-id)

Even with Task 4, PR head SHAs still move when the review-response loop merges master into a branch. Comparing `git patch-id` of the PR diff detects "same change, new SHA" and skips the redundant review.

**Files:**
- Modify: `.claude/skills/review-orchestrator/SKILL.md` (O1, O2, marker format in R4/R5/R6, R7)

**Interfaces:**
- Produces: marker format `<!-- staff-review:<HEAD_SHA>:<PATCH_ID> -->`. Backward compatible: old SHA-only markers still match on SHA; they lack a patch-id so the fast path just doesn't fire until the next real review writes the new format. merge-verdict's review gate reads reviews/threads, not markers — unaffected.

- [ ] **Step 1: Extend O1 with the patch-id fast path**

In `.claude/skills/review-orchestrator/SKILL.md`, replace:

````
**A PR needs review** unless your marker for its current head SHA is already present:

```
<!-- staff-review:<HEAD_SHA> -->
```

No cap on PR count.
````

with:

````
**A PR needs review** unless one of these holds:

1. **SHA match** — a marker for its current head SHA is already present:

```
<!-- staff-review:<HEAD_SHA>:<PATCH_ID> -->
```

(legacy markers without the `:<PATCH_ID>` suffix also count as a SHA match)

2. **Unchanged-diff match** — the head SHA moved but the diff did not (empty
   retrigger commit or a clean master merge). Compare patch-ids:

```bash
git fetch origin master --quiet
git fetch origin "pull/<n>/head:refs/remotes/pr/<n>" --quiet
BASE=$(git merge-base origin/master "refs/remotes/pr/<n>")
PATCH_ID=$(git diff "$BASE" "refs/remotes/pr/<n>" | git patch-id --stable | cut -d' ' -f1)
```

If `PATCH_ID` is non-empty AND equals the `<PATCH_ID>` of the newest existing
marker on the PR → **skip**, log `PR #<n>: SHA moved, diff unchanged
(patch-id <PATCH_ID>) — review carried forward`. If it is empty (empty diff)
or differs, the PR needs review.

Always compute `PATCH_ID` for PRs you dispatch — the reviewer agent embeds it
in every marker it writes.

No cap on PR count.
````

- [ ] **Step 2: Pass PATCH_ID in O2**

Replace:

```
Spawn a **general-purpose (sonnet)** agent with the Agent Task below, passing:
- PR number N
- Current head SHA
- Flutter availability flag
```

with:

```
Spawn a **general-purpose (sonnet)** agent with the Agent Task below, passing:
- PR number N
- Current head SHA
- Current PATCH_ID (computed in O1)
- Flutter availability flag
```

- [ ] **Step 3: Update the marker format everywhere in the skill**

Replace **all** occurrences of the literal string `<!-- staff-review:<HEAD_SHA> -->` in `.claude/skills/review-orchestrator/SKILL.md` with `<!-- staff-review:<HEAD_SHA>:<PATCH_ID> -->` (occurrences in R4 comment-body format, R5 ported note, R5 under-scoped note, R6 clean-review body and its bash example — 5 total; use replace-all).

- [ ] **Step 4: Update R7's empty-commit mention**

Replace:

```
Pushing a new commit (including merge-verdict's empty CI-retrigger commit) bumps
the head SHA and triggers a fresh review. To keep the loop **idempotent** and
avoid thread pile-up:
```

with:

```
Pushing a new commit (e.g. the review-response loop merging master into the
branch) bumps the head SHA; when the diff also changed, that triggers a fresh
review (unchanged diffs are skipped in O1 via patch-id). To keep the loop
**idempotent** and avoid thread pile-up:
```

- [ ] **Step 5: Verify**

Run: `grep -c 'staff-review:<HEAD_SHA>:<PATCH_ID>' .claude/skills/review-orchestrator/SKILL.md`
Expected: `6` (5 replaced + 1 in the new O1 block).
Run: `grep -c 'staff-review:<HEAD_SHA> ' .claude/skills/review-orchestrator/SKILL.md`
Expected: `0`
Run: `yq eval --front-matter=extract .name .claude/skills/review-orchestrator/SKILL.md`
Expected: `review-orchestrator`

- [ ] **Step 6: Sanity-check patch-id mechanics against a real merged PR**

```bash
git fetch origin master --quiet
git fetch origin "pull/394/head:refs/remotes/pr/394" --quiet 2>/dev/null \
  && BASE=$(git merge-base origin/master refs/remotes/pr/394) \
  && git diff "$BASE" refs/remotes/pr/394 | git patch-id --stable | cut -d' ' -f1
```

Expected: a 40-char hex id (or a clean fetch failure if GitHub pruned the ref — then repeat with any currently-open PR number).

- [ ] **Step 7: Commit**

```bash
git add .claude/skills/review-orchestrator/SKILL.md
git commit -m "feat(review-orchestrator): patch-id fast path — skip re-review of unchanged diffs

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### Task 6: Persistent pipeline logs (docker volume)

**Files:**
- Modify: `docker/Dockerfile:43` (add `/var/log/agents` to the mkdir + chown)
- Modify: `docker/docker-compose.yml` (volume mount + declaration)
- Modify: `docker/Makefile` (pipeline-log path)
- Modify: `docker/entrypoint.sh:109` (log-path message)
- Modify: `CLAUDE.md` (pipeline-log comment)

**Interfaces:**
- Produces: `/var/log/agents/` — writable by `dev`, survives container restarts. Tasks 7 and 9 write `agent-pipeline.log` and `cost-digest.log` there.

- [ ] **Step 1: Dockerfile — create the mount point owned by dev**

In `docker/Dockerfile`, replace:

```
    && mkdir -p /workspace /home/dev/.pub-cache /home/dev/.claude /home/dev/.gradle /home/dev/.local/bin \
    && chown -R dev:dev /workspace /home/dev \
```

with:

```
    && mkdir -p /workspace /home/dev/.pub-cache /home/dev/.claude /home/dev/.gradle /home/dev/.local/bin /var/log/agents \
    && chown -R dev:dev /workspace /home/dev /var/log/agents \
```

- [ ] **Step 2: docker-compose.yml — mount a named volume**

In `docker/docker-compose.yml`, after the line `      - gradle-cache:/home/dev/.gradle`, add:

```yaml
      # persist orchestrator/pipeline logs across container restarts
      - agent-logs:/var/log/agents
```

and in the top-level `volumes:` block, after `  gradle-cache:`, add:

```yaml
  agent-logs:
```

- [ ] **Step 3: Makefile — tail the new path**

In `docker/Makefile`, replace:

```
pipeline-log:
	docker compose exec claude tail -f /tmp/agent-pipeline.log
```

with:

```
pipeline-log:
	docker compose exec claude tail -f /var/log/agents/agent-pipeline.log
```

- [ ] **Step 4: entrypoint.sh — fix the announced log paths**

In `docker/entrypoint.sh`, replace:

```
  echo "Orchestrator cron started (PID $!). Logs: /tmp/issue-impl.log, /tmp/review-orch.log, /tmp/review-resp.log"
```

with:

```
  echo "Orchestrator cron started (PID $!). Logs: /var/log/agents/"
```

- [ ] **Step 5: CLAUDE.md — update the reference**

In `CLAUDE.md`, replace:

```
make pipeline-log      # tail /tmp/agent-pipeline.log
```

with:

```
make pipeline-log      # tail /var/log/agents/agent-pipeline.log
```

- [ ] **Step 6: Verify**

Run: `bash -n docker/entrypoint.sh && yq eval . docker/docker-compose.yml > /dev/null && echo OK`
Expected: `OK`
Run: `grep -rn '/tmp/agent-pipeline.log\|/tmp/issue-impl' docker/ CLAUDE.md`
Expected: no matches.
(Note: `/tmp/cron-paused` stays in `/tmp` on purpose — a pause should NOT survive a container restart.)

- [ ] **Step 7: Commit**

```bash
git add docker/Dockerfile docker/docker-compose.yml docker/Makefile docker/entrypoint.sh CLAUDE.md
git commit -m "feat(docker): persist agent logs in /var/log/agents volume

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### Task 7: Fix the broken cron — watchdog script matching the agent-pipeline design

**Depends on:** Task 6 (`/var/log/agents` exists).

The current `orchestrators.crontab` (a) `cd`s into `~/allergy-detector`, which does not exist in the container, so both entries silently fail, and (b) implements the pre-pipeline design (alternating review/merge windows) instead of the watchdog the agent-pipeline skill documents.

**Files:**
- Create: `docker/pipeline-watchdog.sh`
- Rewrite: `docker/orchestrators.crontab`
- Modify: `docker/Dockerfile:53` (copy the script)

**Interfaces:**
- Consumes: `/var/log/agents` (Task 6); `/agent-pipeline` skill; tmux session `claude`.
- Produces: hourly watchdog that (re)creates the `pipeline` tmux window running `/agent-pipeline`. The old per-orchestrator cron entries are removed — stages 2 and 4 of the pipeline cover them.

- [ ] **Step 1: Write the watchdog script**

Create `docker/pipeline-watchdog.sh`:

```bash
#!/usr/bin/env bash
# Watchdog for the endless agent-pipeline loop (see .claude/skills/agent-pipeline/SKILL.md).
# The pipeline runs forever inside a tmux window; cron only recreates the
# window if it died. flock guards against concurrent watchdog firings.
set -euo pipefail

LOG=/var/log/agents/agent-pipeline.log
SESSION=claude
WINDOW=pipeline

exec 9>/tmp/agent-pipeline-watchdog.lock
flock -n 9 || exit 0

tmux has-session -t "$SESSION" 2>/dev/null || tmux new-session -d -s "$SESSION"

if ! tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -qx "$WINDOW"; then
  echo "[watchdog $(date -u +%FT%TZ)] pipeline window missing — starting" >> "$LOG"
  tmux new-window -d -t "$SESSION" -n "$WINDOW" \
    "cd /workspace && git checkout master && git pull origin master && claude --dangerously-skip-permissions -p '/agent-pipeline' 2>&1 | tee -a $LOG"
fi
```

- [ ] **Step 2: Make it executable and syntax-check**

Run: `chmod +x docker/pipeline-watchdog.sh && bash -n docker/pipeline-watchdog.sh && echo OK`
Expected: `OK`

- [ ] **Step 3: Rewrite the crontab**

Replace the entire content of `docker/orchestrators.crontab` with:

```
# Watchdog for the endless agent-pipeline loop — recreates the tmux window if it
# died. The pipeline itself (implement → review → address → merge-verdict) loops
# forever with its own backoff; cron does NOT drive the stages.
# NOTE: repo lives at /workspace inside the container (bind mount), never ~/allergy-detector.
0 * * * * /opt/claude/pipeline-watchdog.sh
```

- [ ] **Step 4: Copy the script in the Dockerfile**

In `docker/Dockerfile`, after the line:

```
COPY --chown=dev:dev orchestrators.crontab /opt/claude/orchestrators.crontab
```

add:

```
COPY --chown=dev:dev --chmod=755 pipeline-watchdog.sh /opt/claude/pipeline-watchdog.sh
```

- [ ] **Step 5: Verify supercronic accepts the crontab**

Run: `supercronic -test docker/orchestrators.crontab && echo CRONTAB_OK`
Expected: `CRONTAB_OK` (supercronic is installed in this container).

- [ ] **Step 6: Commit**

```bash
git add docker/pipeline-watchdog.sh docker/orchestrators.crontab docker/Dockerfile
git commit -m "fix(docker): replace broken orchestrator cron with pipeline watchdog

Old crontab cd'd into ~/allergy-detector (nonexistent in-container) and
predated the agent-pipeline design. New hourly watchdog recreates the
pipeline tmux window per the skill's watchdog contract.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Tier L — large (multi-file or policy decisions)

### Task 8: backlog-scanner skill — keep the pipeline fed

**Depends on:** Task 6 (stamp file lives in `/var/log/agents`).

**Files:**
- Create: `.claude/skills/backlog-scanner/SKILL.md`
- Modify: `.claude/skills/agent-pipeline/SKILL.md` (Stage 1 addition)

**Interfaces:**
- Produces: draft GitHub issues carrying `<!-- backlog-scanner:<slug> -->` markers and area/effort labels but **never** `agent-ready` — the maintainer's triage act is adding that label. Runs at most once per 24h, only when the backlog is empty.

- [ ] **Step 1: Create the skill**

Create `.claude/skills/backlog-scanner/SKILL.md`:

````markdown
---
name: backlog-scanner
description: >
  Use when the allergy-detector agent pipeline finds zero open agent-ready
  issues and needs to propose new backlog items. Scans spec-audit gaps,
  outdated dependencies, TODO/FIXME markers, and unblocked blocked-issues, then
  files DRAFT issues (never labeled agent-ready — the maintainer triages).
  Triggers on /backlog-scanner or from agent-pipeline stage 1 when the
  agent-ready backlog is empty. Idempotent via issue markers; max 5 issues/run.
---

# Backlog Scanner

## Hard rules

- **Never apply the `agent-ready` label.** Only the maintainer promotes drafts.
- Max **5** new issues per run. Prefer the highest-signal candidates.
- Idempotent: every issue body ends with `<!-- backlog-scanner:<slug> -->`
  where `<slug>` is a stable kebab-case id of the finding (e.g.
  `pub-outdated-share-plus-12`, `todo-product-service-l88`). Before creating,
  search: `gh issue list --repo Maortz/allergy-detector --state all --search "backlog-scanner:<slug>"` — skip on any hit (open OR closed: closed means rejected, don't re-file).
- Run at most once per 24h: check stamp `/var/log/agents/backlog-scanner.stamp`;
  if it exists and is younger than 24h (`find /var/log/agents/backlog-scanner.stamp -mmin -1440`), STOP with `SKIPPED stamp-fresh`. Touch it after a completed scan.

## Sources (scan all four)

1. **Spec-audit gaps** — grep the spec tree for unresolved audit flags:
   `grep -rn '⚠\|✗' docs/superpowers/specs/2026-05-19-stitch-screens/ | head -40`
   Each distinct flagged screen/section is a candidate (`area:verify` or `area:screen`).
2. **Outdated dependencies** — from `app/`: `flutter pub outdated --json | jq '.packages[] | select(.isDiscontinued or (.current.version != .resolvable.version)) | {package: .package, current: .current.version, resolvable: .resolvable.version}'`.
   Bundle ALL safe minor/patch bumps into ONE candidate issue (`area:infra`, `effort:S`); each major bump gets its own (`effort:M`).
3. **Code markers** — `grep -rn 'TODO\|FIXME\|HACK' app/lib --include='*.dart' | head -20`.
   Only file an issue for markers describing real user-facing gaps or bugs, not style notes.
4. **Unblocked blocked issues** — for each `gh issue list --repo Maortz/allergy-detector --state open --label blocked --json number,title,body`, extract the blocking reference (`#N` after "blocked on"/"depends on"); if that issue/PR is closed/merged, comment on the blocked issue: "Blocker #N has landed — candidate for unblocking" and include it in the report (do NOT file a new issue for these).

## Filing format

Use the issue-writer skill's structure: Problem, Proposed solution, Acceptance
criteria (checkboxed), Out of scope. Apply labels: one `area:*` + one
`effort:*` (never `agent-ready`, never `phase:*` — the maintainer assigns phase
at triage). Title prefixed by area, e.g. `[infra] bump outdated pub dependencies (minor/patch)`.

## Return contract

Last line exactly one of:
```
DONE filed=<#new-issues> unblock-candidates=<#>
SKIPPED <reason>
FAILED <reason>
```
````

- [ ] **Step 2: Wire into agent-pipeline Stage 1**

In `.claude/skills/agent-pipeline/SKILL.md`, at the end of the Stage 1 section (after the line `On \`FAILED\`: log, proceed to stage 2.`), add:

```
**Backlog refill:** if stage 1 found zero `agent-ready` issues to claim
(`gh issue list --repo Maortz/allergy-detector --state open --label agent-ready --json number --jq length` returns `0`),
dispatch a **fresh general-purpose (sonnet) agent** with this brief:

> You are running the `backlog-scanner` skill in Maortz/allergy-detector. Read `.claude/skills/backlog-scanner/SKILL.md` and execute it once. Return its return contract as your last line.

Then proceed to stage 2 regardless of its result. The scanner is self-limiting
(24h stamp, 5-issue cap) and never labels anything `agent-ready` — new drafts
only enter the pipeline after the maintainer triages them.
```

- [ ] **Step 3: Verify**

Run: `yq eval --front-matter=extract .name .claude/skills/backlog-scanner/SKILL.md`
Expected: `backlog-scanner`
Run: `grep -rn '⚠\|✗' docs/superpowers/specs/2026-05-19-stitch-screens/ | head -3`
Expected: zero or more lines — confirms the grep pattern is valid against the real spec tree (adjust the path in the skill if the directory has moved).

- [ ] **Step 4: Commit**

```bash
git add .claude/skills/backlog-scanner/SKILL.md .claude/skills/agent-pipeline/SKILL.md
git commit -m "feat(skills): backlog-scanner — refill empty backlog with draft issues

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### Task 9: Daily cost digest

**Depends on:** Task 6 (log volume), Task 7 (crontab shape).

**Files:**
- Create: `docker/cost-digest.sh`
- Modify: `docker/orchestrators.crontab` (add one line)
- Modify: `docker/Dockerfile` (copy the script)
- Modify: `docker/Makefile` (add `pipeline-cost` target)

**Interfaces:**
- Produces: `/var/log/agents/cost-digest.log`, one dated block per day; `make pipeline-cost` shows the latest block.

- [ ] **Step 1: Write the digest script**

Create `docker/cost-digest.sh`:

```bash
#!/usr/bin/env bash
# Append a daily Claude token/cost digest to the persistent agent-log volume.
# ccusage parses the local ~/.claude session JSONL — no API key needed.
set -uo pipefail

LOG=/var/log/agents/cost-digest.log
{
  echo "=== cost digest $(date -u +%F) ==="
  npx --yes ccusage@latest daily --since "$(date -u -d '7 days ago' +%Y%m%d)" 2>/dev/null \
    || echo "ccusage failed (offline or no session data)"
  echo
} >> "$LOG"
```

- [ ] **Step 2: Syntax-check and dry-run**

Run: `bash -n docker/cost-digest.sh && echo OK`
Expected: `OK`
Run: `npx --yes ccusage@latest daily --since $(date -u -d '7 days ago' +%Y%m%d) | head -15`
Expected: a per-day token/cost table (this container has live `~/.claude` data). If npx fails offline, note it and continue — the cron entry degrades gracefully.

- [ ] **Step 3: Add the cron entry**

In `docker/orchestrators.crontab`, append:

```
# Daily cost digest (06:30 UTC) → /var/log/agents/cost-digest.log
30 6 * * * /opt/claude/cost-digest.sh
```

- [ ] **Step 4: Copy in Dockerfile**

In `docker/Dockerfile`, after the `COPY ... pipeline-watchdog.sh` line added in Task 7, add:

```
COPY --chown=dev:dev --chmod=755 cost-digest.sh /opt/claude/cost-digest.sh
```

- [ ] **Step 5: Makefile target**

In `docker/Makefile`, append (and add `pipeline-cost` to the `.PHONY` line):

```
pipeline-cost:
	docker compose exec claude sh -c 'tail -40 /var/log/agents/cost-digest.log'
```

- [ ] **Step 6: Verify crontab still parses**

Run: `supercronic -test docker/orchestrators.crontab && echo CRONTAB_OK`
Expected: `CRONTAB_OK`

- [ ] **Step 7: Commit**

```bash
git add docker/cost-digest.sh docker/orchestrators.crontab docker/Dockerfile docker/Makefile
git commit -m "feat(docker): daily ccusage cost digest to agent-log volume

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### Task 10: Auto-merge for effort:S PRs — ⛔ DECISION-GATED

**This task changes merge authority** (today: merge-verdict never merges; the human clicks merge). The maintainer signaled intent on 2026-07-02 (in the context of adding the reviewer account) but confirm explicitly at execution time. With Task 11 live, the risk profile drops sharply: GitHub itself enforces bot approval + required checks + thread resolution before `--auto` fires — merge-verdict only arms the trigger.

**Depends on:** Task 11 live (required-review gate active), plus Tasks 3 and 4 merged and observed working for ≥1 week (merge-ready labels accurate, no marker churn).

**Files:**
- Repo setting: `allow_auto_merge`
- Modify: `.claude/skills/merge-verdict/SKILL.md` (Step 5 + Constraints)

- [ ] **Step 1: Enable auto-merge at the repo level**

```bash
gh api -X PATCH repos/Maortz/allergy-detector -F allow_auto_merge=true
```

Expected: JSON response with `"allow_auto_merge": true`.

- [ ] **Step 2: Extend merge-verdict Step 5**

In `.claude/skills/merge-verdict/SKILL.md`, after the Label-sync block added in Task 3, add:

```
**Auto-merge arming (effort:S only):** when the verdict is `✅ READY TO MERGE`
AND the PR's linked issue carries the `effort:S` label AND the PR has no
`needs-human-decision` label and no maintainer hold:

    gh pr merge <n> --repo Maortz/allergy-detector --auto --squash

`--auto` does not merge now — GitHub merges only once all ruleset gates
(required checks, thread resolution) pass on the final head. Never use
`--auto` for effort:M/L, `area:infra`, or anything touching `supabase/`,
`.github/`, or `docker/` (check the PR's changed files with
`gh pr view <n> --json files --jq '.files[].path'`).
```

- [ ] **Step 3: Amend Constraints**

In the same file's `## Constraints`, replace:

```
- Never merge, approve, request-changes, or edit application code.
```

with:

```
- Never merge directly, approve, request-changes, or edit application code.
  The ONLY merge-adjacent write allowed is arming GitHub auto-merge
  (`gh pr merge --auto --squash`) for `effort:S` PRs per Step 5 — GitHub
  itself performs the merge when gates pass.
```

- [ ] **Step 4: Verify + commit**

Run: `yq eval --front-matter=extract .name .claude/skills/merge-verdict/SKILL.md`
Expected: `merge-verdict`

```bash
git add .claude/skills/merge-verdict/SKILL.md
git commit -m "feat(merge-verdict): arm auto-merge for effort:S PRs (maintainer-approved)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

### Task 11: Second reviewer account — real approvals + required-review gate

**Maintainer decision 2026-07-02:** approved. Copilot code review is configured in the ruleset but produces zero reviews; a machine account gives real APPROVE/REQUEST_CHANGES semantics, makes `reviewDecision` meaningful, and is the prerequisite for safe auto-merge (Task 10).

**Files:**
- Modify: `docker/docker-compose.yml` (env), `docker/.env.example`
- Modify: `.claude/skills/review-orchestrator/SKILL.md` (O0, O1, Agent Task, R6)
- Modify: `.claude/skills/merge-verdict/SKILL.md` (review-gate definition)
- Repo state: collaborator invite, ruleset update (LAST step — see ordering warning)

**Interfaces:**
- Consumes: Task 5's patch-id fast path (amends it to re-approve instead of silently skip).
- Produces: env var `GH_TOKEN_REVIEWER`; reviews authored by the machine account; ruleset `required_approving_review_count: 1`. merge-verdict's review gate becomes `reviewDecision == APPROVED`.

**Security note (be honest about the trust model):** both tokens live in the same container and the same UNIX user runs implementer and reviewer agents. The separation is **procedural** — skills instruct which token to use — not a security boundary. A misbehaving implementer agent could read `GH_TOKEN_REVIEWER` and self-approve. This still improves on today (where no approval gate exists at all) and gives a clean audit trail of which identity did what.

- [ ] **Step 1: MAINTAINER-MANUAL — create the machine account and PAT**

Cannot be automated; the maintainer does this in a browser:
1. Create a GitHub account, suggested name `maortz-reviewer` (GitHub ToS permits one machine account per user).
2. On that account, create a **classic PAT with `repo` scope** (Settings → Developer settings → Personal access tokens → Tokens (classic)). Classic, not fine-grained: the reviewer flow needs GraphQL mutations (`resolveReviewThread`), and fine-grained-PAT GraphQL support must be assumed absent until Step 4 proves otherwise.
3. Append to `docker/.env` (never commit this file): `GH_TOKEN_REVIEWER=ghp_...`

- [ ] **Step 2: Invite the bot as collaborator with write access**

Approvals only count toward required reviews from users with write access:

```bash
gh api -X PUT repos/Maortz/allergy-detector/collaborators/maortz-reviewer -f permission=push
```

Expected: `201` with invitation JSON (or `204` if already a collaborator).

- [ ] **Step 3: Accept the invite as the bot**

```bash
INV_ID=$(GH_TOKEN="$GH_TOKEN_REVIEWER" gh api /user/repository_invitations \
  --jq '.[] | select(.repository.full_name=="Maortz/allergy-detector") | .id')
GH_TOKEN="$GH_TOKEN_REVIEWER" gh api -X PATCH "/user/repository_invitations/$INV_ID"
```

Expected: `204 No Content`.

- [ ] **Step 4: Verify bot identity, GraphQL, and review ability**

```bash
GH_TOKEN="$GH_TOKEN_REVIEWER" gh api user --jq .login
GH_TOKEN="$GH_TOKEN_REVIEWER" gh api graphql -f query='query { viewer { login } }' --jq .data.viewer.login
```

Expected: `maortz-reviewer` from BOTH commands. If the GraphQL call fails, the PAT is fine-grained without GraphQL support — regenerate as classic (Step 1.2).

Smoke-test a real approval: open a trivial PR (e.g. a one-line comment change on a new branch), then:

```bash
GH_TOKEN="$GH_TOKEN_REVIEWER" gh pr review <test-pr> --approve --body "reviewer-account smoke test"
gh pr view <test-pr> --json reviewDecision --jq .reviewDecision
```

Expected: `APPROVED`. Close the test PR and delete its branch.

- [ ] **Step 5: Wire the env through compose**

In `docker/docker-compose.yml`, after the line `      - GITHUB_TOKEN=${GH_TOKEN:-}`, add:

```yaml
      # reviewer machine-account PAT — used ONLY by review-orchestrator agents
      # (procedural separation; see plan Task 11 security note)
      - GH_TOKEN_REVIEWER=${GH_TOKEN_REVIEWER:-}
```

In `docker/.env.example`, append:

```
# classic PAT (repo scope) of the reviewer machine account (e.g. maortz-reviewer)
GH_TOKEN_REVIEWER=
```

- [ ] **Step 6: review-orchestrator — authenticate reviews as the bot**

In `.claude/skills/review-orchestrator/SKILL.md`:

**(pre)** Two blanket "never approve" statements must be updated or they
contradict everything below. In the frontmatter, replace:

```
  continuous code review. REVIEW ONLY — never modifies code, approves, merges, or pushes.
```

with:

```
  continuous code review. Reviews as the reviewer machine account
  (GH_TOKEN_REVIEWER) and may approve/request-changes — never modifies code,
  merges, or pushes.
```

And in the Overview, replace:

```
**Hard constraint:** Neither you nor your agents ever modify code, approve, request-changes, merge, or push.
```

with:

```
**Hard constraint:** Neither you nor your agents ever modify code, merge, or
push. Reviews (approve/request-changes/comment) are submitted ONLY as the
reviewer machine account via `GH_TOKEN="$GH_TOKEN_REVIEWER"`.
```

**(a)** In O0, replace:

```
- `gh` not authenticated → **STOP**
```

with:

```
- `gh` not authenticated → **STOP**
- `GH_TOKEN="$GH_TOKEN_REVIEWER" gh api user --jq .login` must return the
  reviewer machine account (NOT `Maortz`). Empty/missing/same-as-maintainer →
  **STOP** with `FAILED reviewer token missing` — never fall back to the
  maintainer token for review writes.
```

**(b)** In the Agent Task intro (R0 area), after the sentence ending `**Comment-only: NEVER approve/request-changes/merge/push/edit code.**` — replace that sentence with:

```
**Review writes (inline comments, reviews, thread resolution) MUST run with
`GH_TOKEN="$GH_TOKEN_REVIEWER"` — you review as the machine account, never as
the maintainer. NEVER merge/push/edit code.**
```

**(c)** Replace the R6 section body (the paragraph, bash block, and the two rationale paragraphs) with:

````
If no findings at all, submit a formal **approval** as the reviewer account:

```bash
GH_TOKEN="$GH_TOKEN_REVIEWER" gh pr review N --approve --body "✅ Clean — no findings.
<!-- staff-review:<HEAD_SHA>:<PATCH_ID> -->"
```

If findings exist: post the inline comments (R4) as the reviewer account, then
submit one formal review summarizing the round — state `REQUEST_CHANGES` when
any 🔴/🟠 finding was posted, otherwise `COMMENTED`:

```bash
GH_TOKEN="$GH_TOKEN_REVIEWER" gh pr review N --request-changes --body "<count> finding(s) posted inline — see threads.
<!-- staff-review:<HEAD_SHA>:<PATCH_ID> -->"
```

Never use `gh pr comment` for this: merge-verdict's gate reads `reviewDecision`,
which only formal reviews affect. **Never post the clean-confirmation as an
inline review comment** (`pulls/N/comments`) — that opens an unresolved thread
this loop never resolves, permanently failing the merge gate's thread half.
````

**(d)** If Task 5 is applied, in O1's unchanged-diff branch, replace:

```
marker on the PR → **skip**, log `PR #<n>: SHA moved, diff unchanged
(patch-id <PATCH_ID>) — review carried forward`. If it is empty (empty diff)
or differs, the PR needs review.
```

with:

```
marker on the PR → do NOT dispatch a full review. If `reviewDecision` is
already `APPROVED`, just skip. If the push dismissed a prior approval
(`reviewDecision` ≠ `APPROVED`), re-approve cheaply as the reviewer account:

    GH_TOKEN="$GH_TOKEN_REVIEWER" gh pr review <n> --approve \
      --body "Re-approving: diff unchanged since last review (patch-id match).
    <!-- staff-review:<NEW_HEAD_SHA>:<PATCH_ID> -->"

If `PATCH_ID` is empty (empty diff) or differs from the marker, the PR needs
a full review.
```

- [ ] **Step 7: merge-verdict — gate on real approval**

In `.claude/skills/merge-verdict/SKILL.md`, replace:

```
**Passes review gate** when:
- `reviewDecision` is `APPROVED`, or at least one review with state `APPROVED`
  or `COMMENTED` exists (i.e. not zero reviews), AND
```

with:

```
**Passes review gate** when:
- `reviewDecision` is `APPROVED` (a real approval from the reviewer machine
  account — COMMENTED reviews no longer suffice now that the ruleset requires
  1 approving review), AND
```

- [ ] **Step 8: LAST — raise the ruleset to require 1 approving review**

⚠️ **Ordering warning:** the moment this lands, every open PR needs a bot
approval to merge. Run it only after Steps 1–7 are done AND the updated
review-orchestrator has completed one pass (so open PRs have approvals).

```bash
gh api -X PUT repos/Maortz/allergy-detector/rulesets/17539841 --input - <<'JSON'
{
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "copilot_code_review",
      "parameters": { "review_draft_pull_requests": false, "review_on_push": true } },
    { "type": "required_linear_history" },
    { "type": "pull_request",
      "parameters": {
        "allowed_merge_methods": ["merge", "squash", "rebase"],
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_approving_review_count": 1,
        "required_review_thread_resolution": true,
        "required_reviewers": [] } },
    { "type": "required_status_checks",
      "parameters": {
        "do_not_enforce_on_create": false,
        "strict_required_status_checks_policy": false,
        "required_status_checks": [
          { "context": "Analyze, Test & Build (web)", "integration_id": 15368 },
          { "context": "Build debug APK", "integration_id": 15368 } ] } }
  ]
}
JSON
```

Two deliberate parameter changes from the captured current state:
- `required_approving_review_count`: 0 → **1** (the point of this task).
- `require_code_owner_review`: true → **false**. CODEOWNERS is `* @Maortz`;
  with a required review, keeping it `true` would demand an approval from
  *Maortz* on every PR — the exact self-approval deadlock this task removes
  (PR author = Maortz can't approve own PRs). The bot's approval satisfies
  the count; code-owner review must come off.

Verify: `gh api repos/Maortz/allergy-detector/rulesets/17539841 --jq '.rules[] | select(.type=="pull_request").parameters | {required_approving_review_count, require_code_owner_review}'`
Expected: `{"required_approving_review_count":1,"require_code_owner_review":false}`

- [ ] **Step 9: Verify + commit**

Run: `yq eval --front-matter=extract .name .claude/skills/review-orchestrator/SKILL.md && yq eval --front-matter=extract .name .claude/skills/merge-verdict/SKILL.md && yq eval . docker/docker-compose.yml > /dev/null && echo OK`
Expected: `review-orchestrator`, `merge-verdict`, `OK`

```bash
git add .claude/skills/review-orchestrator/SKILL.md .claude/skills/merge-verdict/SKILL.md docker/docker-compose.yml docker/.env.example
git commit -m "feat(review): reviewer machine account — real approvals + required-review gate

Copilot code review rule was inert (zero reviews on #386-#395); same-account
reviews are capped at COMMENTED. Reviews now authored by the reviewer bot,
ruleset requires 1 approving review, merge gate reads reviewDecision.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Execution notes

- **Order:** S tier first (Tasks 1–3, independent), then M (Task 4 needs Task 1 on master; Task 7 needs Task 6), then L (Tasks 8–9 need Task 6/7; Task 11 starts with a maintainer-manual account-creation step and its ruleset bump goes absolutely last; Task 10 only after Task 11 is live — confirm with maintainer at execution).
- **Branching:** work on a feature branch off `master`; one PR for the whole plan or one per tier — the repo's own review pipeline will review it. Never force-push.
- **Docker changes (Tasks 6, 7, 9) take effect only after** `docker compose build && docker compose up -d` on the host — note this in the PR body; it cannot be done from inside the container.
- **Skill edits take effect on the next fresh agent session** that loads them — running pipeline windows keep the old text until restarted.
