---
name: agent-pipeline
description: >
  Use when running the full autonomous development pipeline on the allergy-detector
  repo in an endless loop: implement issues, review PRs, address review comments —
  in that order, each drained to completion before moving to the next. Triggers on
  /agent-pipeline, "run full pipeline", "run all orchestrators", or when invoked
  from the cron watchdog. Loops forever with backoff between full cycles.
---

# Agent Pipeline

## Overview

Endless pipeline loop. Each stage runs until it has nothing left to do, then the next stage starts. After all three stages are drained, wait (backoff) and restart from stage 1.

**Stage order:** implement → review → address comments

Runs as a persistent window in the tmux `claude` session. Cron is a watchdog only — if the window dies, cron recreates it within the hour. `flock` prevents duplicate instances.

---

## Pipeline Loop

```
loop forever:
  stage 1: drain issue-implementer
  stage 2: drain review-orchestrator
  stage 3: drain review-response-orchestrator
  backoff (default: 30 min)
```

### Stage 1 — Implement issues

Dispatch a **fresh general-purpose (opus) agent** with this brief:
> You are running the `issue-implementer` skill in Maortz/allergy-detector. Read `.claude/skills/issue-implementer/SKILL.md`. Execute it in **single-pass mode**: run the orchestrator loop (O1→O4) picking and implementing issues one at a time until O2 finds nothing qualifying. Then STOP — do NOT loop back. The outer pipeline handles cycling. Return exactly: `DONE` (nothing left), `STOPPED <reason>`, or `FAILED <reason>` as your last line.

On `FAILED`: log, proceed to stage 2.

### Stage 2 — Review PRs

Dispatch a **fresh general-purpose (sonnet) agent** with this brief:
> You are running the `review-orchestrator` skill in Maortz/allergy-detector. Read `.claude/skills/review-orchestrator/SKILL.md`. Execute it in **single-pass mode**: dispatch reviewer agents for every currently-open PR that lacks an up-to-date `<!-- staff-review:<HEAD_SHA> -->` marker. Once all open PRs are covered, STOP — do NOT loop back to check for new PRs. The outer pipeline handles cycling. Return `DONE`, `STOPPED <reason>`, or `FAILED <reason>` as your last line.

On `FAILED` twice in a row: log, proceed to stage 3.

### Stage 3 — Address review comments

Dispatch a **fresh general-purpose (opus) agent** with this brief:
> You are running the `review-response-orchestrator` skill in Maortz/allergy-detector. Read `.claude/skills/review-response-orchestrator/SKILL.md`. Execute it in **single-pass mode**: run the orchestrator loop (O1→O4) picking and addressing PRs one at a time until O2 finds nothing qualifying. Then STOP — do NOT loop back. The outer pipeline handles cycling. Return exactly: `DONE` (nothing left), `STOPPED <reason>`, or `FAILED <reason>` as your last line.

On `FAILED`: log, continue to backoff.

### Backoff + pause check

After all three stages complete (or are skipped): **sleep 30 minutes**.

Then, before starting the next cycle, check the pause gate:
- If `/tmp/cron-paused` exists → keep sleeping in 5-minute increments, printing "paused — waiting..." each time, until the file is removed.
- Once clear → proceed to stage 1.

Rationale: gives CI time to run on newly-pushed branches, GitHub to process new review comments, and avoids hammering the API in a tight loop when there genuinely is no work. Pause gate allows interrupting between cycles without killing the tmux window.

---

## Failure handling

| Situation | Action |
|-----------|--------|
| Stage 1 FAILED | Log, continue to stage 2 |
| Stage 2 FAILED ×2 consecutive | Log, continue to stage 3 |
| Stage 3 FAILED | Log, continue to backoff |
| Any stage STOPPED | Normal — move to next stage |
| 5+ consecutive full-cycle failures | STOP and report — something systemic is broken |
