# Claude Code Workflow Tooling Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce per-session token cost and prevent repeat mistakes by adding two project-specialized subagents, three CLAUDE.md operational notes, two memory entries, project-scoped MCP trimming, and two verify helper scripts.

**Architecture:** Pure tooling/config layer — no application code changes. Each task produces an independently useful artifact under `.claude/`, `docs/`, `tools/`, or the memory dir. The two subagents replace expensive (~25-30k token) general-purpose dispatches for the two roles that recurred most this cycle (test fixing, build verification). The CLAUDE.md/memory notes are pure leverage: they stop the same three mistakes (pumpAndSettle hang, PowerShell `2>&1` quirk, wrong CWD) from recurring across all future sessions.

**Tech Stack:** Claude Code subagents (`.claude/agents/*.md` with YAML frontmatter), Claude Code memory (`MEMORY.md` + per-entry markdown), PowerShell 5.1 scripts, project `.claude/settings.json`. Target project: Flutter 3.41.7 / Dart 3.11.5 app in `app/`.

---

## File Structure

| File | Responsibility | Action |
|---|---|---|
| `CLAUDE.md` | Project instructions for Claude | Modify (append 3 operational notes) |
| `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\feedback_powershell_stderr.md` | Memory: PowerShell `2>&1` quirk | Create |
| `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\project_searchscan_laser_animation.md` | Memory: laser-animation pumpAndSettle pitfall | Create |
| `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\MEMORY.md` | Memory index | Modify (add 2 pointers) |
| `.claude/agents/flutter-build-verifier.md` | Subagent: run + parse the 4 verify commands | Create |
| `.claude/agents/flutter-widget-test-fixer.md` | Subagent: fix stale Hebrew/RTL widget-test assertions | Create |
| `.claude/settings.json` | Project permissions + MCP scoping | Modify (add MCP disable keys) |
| `tools/verify.ps1` | Full verify sequence, summary-only output | Create |
| `tools/test-quick.ps1` | Fast targeted test runner | Create |

The memory files live **outside** the repo (in the user's `.claude` projects dir) — they are not committed. Everything else is committed.

**Out of scope (deliberately deferred):**
- Command-rewriting `PreToolUse` hooks (e.g. auto-fixing `cd app`). A buggy hook intercepts *every* shell call; the risk outweighs the gain. The CLAUDE.md CWD note (Task 1) is the low-risk mitigation for the same problem.
- `Stop`-hook auto-`flutter analyze` — adds ~58s latency to every turn. CI (ROADMAP #1) is the right place for this.
- Project-local `fix-widget-test` skill — the `flutter-widget-test-fixer` agent (Task 5) covers the same need; a skill would be redundant until the agent proves insufficient.
- Removing Gmail/Calendar MCP at **user** scope — that affects the user's other projects; Task 6 only scopes them out of *this* project and escalates if user-scope removal is the only option.

---

## Task 1: Append operational notes to CLAUDE.md

**Context:** Three mistakes recurred and each cost retries: (a) `pumpAndSettle` hangs on `SearchScanScreen` because `_laserController.repeat()` never settles; (b) PowerShell wraps native-exe stderr from `2>&1` as `NativeCommandError` and exits 1 even on success; (c) `flutter` commands must run from `app/`, and `cd app` fails when CWD is already `app/`. Putting these in CLAUDE.md makes them load every session at near-zero cost.

**Files:**
- Modify: `CLAUDE.md` (append a new section before end of file)

- [ ] **Step 1: Read the end of CLAUDE.md to find the insertion point**

Run: `Get-Content CLAUDE.md -Tail 15`
Expected: the file currently ends with the `## Key conventions` bullet list (last bullet about `scripts/` Dart CLI tools).

- [ ] **Step 2: Append the operational notes section**

Append exactly this to the end of `CLAUDE.md` (one trailing newline, no other changes):

```markdown

## Operational notes (learned the hard way)

- **Never `pumpAndSettle` in `search_scan_screen_test.dart`.** `SearchScanScreen` creates `_laserController = AnimationController(...)..repeat(reverse: true)` in `initState` (`app/lib/screens/search_scan_screen.dart`). `pumpAndSettle` waits for all animations to finish and will time out. Section headers render on the first frame, so `await tester.pumpWidget(...)` alone is sufficient — every passing test in that file follows this pattern.
- **Don't redirect native-exe stderr with `2>&1` in the PowerShell tool.** Windows PowerShell 5.1 wraps each stderr line in a `NativeCommandError` `ErrorRecord` and sets the call's exit code to 1 even when the exe returned 0 (e.g. `flutter analyze` printing its summary to stderr). stderr is already captured for you. Use `flutter analyze | Select-Object -Last 5`, not `flutter analyze 2>&1 | Select-Object -Last 5`.
- **`flutter`/`dart`/`gradlew` run from `app/`, not the repo root.** When a tool call's working directory is already `app/`, prefixing `cd app` makes it fail with `app\app does not exist`. Check CWD first, or use absolute paths. Database/schema work runs from `supabase/`; admin scripts run from `scripts/`.
```

- [ ] **Step 3: Verify the section is well-formed**

Run: `Get-Content CLAUDE.md -Tail 10`
Expected: output ends with the third bullet (`flutter/dart/gradlew run from app/...`). No duplicated headings; the new `## Operational notes` heading appears exactly once (`Select-String -Path CLAUDE.md -Pattern '## Operational notes' | Measure-Object` → Count 1).

- [ ] **Step 4: Commit**

```powershell
git add CLAUDE.md
git commit -m "docs(claude): add operational notes (pumpAndSettle, PS stderr, CWD)"
```

---

## Task 2: Save the two memory entries

**Context:** The PowerShell `2>&1` quirk and the laser-animation pitfall are the kind of non-obvious, recurring traps memory is for. CLAUDE.md (Task 1) covers them for *this* repo's sessions; memory entries make the reasoning (the *why*) recallable and link into the existing memory graph. The memory dir already exists and contains `MEMORY.md` plus two prior entries.

**Files:**
- Create: `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\feedback_powershell_stderr.md`
- Create: `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\project_searchscan_laser_animation.md`
- Modify: `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\MEMORY.md`

- [ ] **Step 1: Confirm current memory index contents**

Run: `Get-Content "C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\MEMORY.md"`
Expected: two existing lines — one for `feedback_accept_pragmatic_scope_expansion.md`, one for `project_android_gradle_heap_3g.md`.

- [ ] **Step 2: Create the PowerShell-stderr feedback memory**

Write `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\feedback_powershell_stderr.md` with exactly:

```markdown
---
name: feedback-powershell-stderr
description: On Windows PowerShell tool calls, never redirect native-exe stderr with 2>&1 — it wraps stderr as NativeCommandError and exits 1 even on success
metadata:
  type: feedback
---

Do not use `2>&1` when piping a native executable's output in the PowerShell tool on this project (`flutter`, `dart`, `gradlew`, etc.). Pipe directly: `flutter analyze | Select-Object -Last 5`.

**Why:** Windows PowerShell 5.1 wraps each native-command stderr line in a `NativeCommandError` `ErrorRecord` and sets `$?`/exit code to `$false`/1 even when the exe returned 0. During the 2026-05-13 build fix, `flutter analyze 2>&1 | Select-Object -Last 5` reported exit 1 and a "RemoteException" despite analyze succeeding (0 errors, 32 known warnings), and it cancelled a parallel build call. stderr is already captured by the tool, so the redirect adds nothing but breakage.

**How to apply:** When constructing PowerShell tool commands that run `flutter`/`dart`/`gradlew`/any native exe and trim output, omit `2>&1`. If you need only the tail, use `| Select-Object -Last N`. Treat a PowerShell exit-1 that coincides with apparently-successful native output as this artifact, not a real failure — re-run without the redirect to confirm. Related: [[project-searchscan-laser-animation]] (the other recurring test-time trap on this project).
```

- [ ] **Step 3: Create the laser-animation project memory**

Write `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\project_searchscan_laser_animation.md` with exactly:

```markdown
---
name: project-searchscan-laser-animation
description: SearchScanScreen runs a perpetual laser AnimationController — widget tests in search_scan_screen_test.dart must not use pumpAndSettle or they hang
metadata:
  type: project
---

`SearchScanScreen` (`app/lib/screens/search_scan_screen.dart`) creates `_laserController = AnimationController(...)..repeat(reverse: true)` in `initState`. The animation never completes.

**Why:** `WidgetTester.pumpAndSettle()` pumps frames until no animation is scheduled. A perpetually-repeating controller means it never returns — it times out instead. During the 2026-05-13 build fix, the Task 3 implementer followed a plan that prescribed `pumpAndSettle` and got a hard timeout at `search_scan_screen_test.dart`; the fix was to drop the line. Every other passing test in that file uses `pumpWidget` alone.

**How to apply:** When writing or fixing widget tests for `SearchScanScreen`, assert against the first frame after `await tester.pumpWidget(...)` — section headers ("נסרק לארכונה", etc.) render synchronously. Never add `pumpAndSettle`/`pump(Duration...)` loops there. If a future test genuinely needs post-animation state, pump a fixed number of frames explicitly instead. This is also documented in CLAUDE.md "Operational notes". Related: [[feedback-powershell-stderr]].
```

- [ ] **Step 4: Append both pointers to MEMORY.md**

Append these two lines to the end of `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\MEMORY.md` (keep the existing two lines unchanged):

```markdown
- [PowerShell stderr 2>&1 quirk](feedback_powershell_stderr.md) — never redirect native-exe stderr on Windows; exits 1 even on success
- [SearchScanScreen perpetual laser animation](project_searchscan_laser_animation.md) — no pumpAndSettle in search_scan_screen_test.dart, it hangs
```

- [ ] **Step 5: Verify the index resolves**

Run: `Get-Content "C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\MEMORY.md"`
Expected: 4 lines total. Then confirm both new files exist:
Run: `Test-Path "C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\feedback_powershell_stderr.md"; Test-Path "C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\project_searchscan_laser_animation.md"`
Expected: `True` then `True`.

- [ ] **Step 6: No commit**

These files live outside the git repo (user `.claude` dir). Do not run git. Confirm with `git status --short` that no repo files changed in this task (expected: unchanged from Task 1's post-commit state).

---

## Task 3: Create the flutter-build-verifier subagent

**Context:** "Is the project green?" is the post-merge/post-CI ritual: `flutter test`, `flutter analyze`, `flutter build web`, `flutter build apk --debug`, in that order, each producing verbose output. A general-purpose subagent re-derives this every time (~25k tokens). A dedicated read-mostly agent encapsulates the sequence and the known-good baselines (184 tests, 0 errors, 32 warnings) and returns ~5 lines.

**Files:**
- Create: `.claude/agents/flutter-build-verifier.md`

- [ ] **Step 1: Confirm the agents directory**

Run: `Test-Path .claude\agents`
If `False`, run: `New-Item -ItemType Directory -Path .claude\agents | Out-Null` then `Test-Path .claude\agents` (expected `True`). If `True`, list it: `Get-ChildItem .claude\agents`.

- [ ] **Step 2: Write the agent file**

Create `.claude/agents/flutter-build-verifier.md` with exactly:

```markdown
---
name: flutter-build-verifier
description: Use to verify the Flutter project is green — runs the full test/analyze/web/apk sequence and returns a concise pass/fail report. Use after merges, before declaring work complete, or when the user asks "is it building / are tests passing".
tools: Read, Glob, Grep, Bash
model: sonnet
---

You verify that the allergy-detector Flutter project builds and tests cleanly on all targets. You do NOT fix anything — you report status only.

## Environment

- Repo root contains `app/`. ALL flutter commands run from `app/`. The shell is PowerShell on Windows; the Bash tool is also available.
- Do not redirect native-exe stderr with `2>&1` (PowerShell wraps it as an error and exits 1 even on success). Pipe directly and tail with `| Select-Object -Last N`.

## Known-good baseline (as of 2026-05-17)

- `flutter test`: 184 passing, 0 failing.
- `flutter analyze`: 0 errors, 32 info/warnings (pre-existing: unused imports, withOpacity, prefer_final_fields).
- `flutter build web --no-tree-shake-icons`: `✓ Built build\web`.
- `flutter build apk --debug`: `✓ Built build\app\outputs\flutter-apk\app-debug.apk`.
- Android heap is intentionally 3G in `app/android/gradle.properties` — do NOT suggest raising it (4G OOMs this 7GB host).

## Procedure

Run these from `app/`, in order. Capture only the summary of each:

1. `flutter test` — record the final `+N -M: ...` line.
2. `flutter analyze` — record the `N issues found` line and whether any are `error` severity.
3. `flutter build web --no-tree-shake-icons` — record the final `✓ Built` / failure line.
4. `flutter build apk --debug` — record the final `✓ Built` / failure line.

If a step fails, still run the remaining steps (independent signals), then report.

## Report format (keep it under ~12 lines)

```
BUILD VERIFICATION — <date>
test:    <PASS 184/184 | FAIL: n failing — first failure: ...>
analyze: <OK 0 errors / 32 warnings | REGRESSION: n errors>
web:     <OK | FAIL: ...>
apk:     <OK | FAIL: ...>
verdict: <GREEN | RED — <one-line reason>>
```

If `analyze` warning count differs from 32, note the delta (new warnings are a soft regression worth flagging, not a failure). If `test` count differs from 184, that is a hard signal — state the new count and the first failing test name.
```

- [ ] **Step 3: Validate the frontmatter parses**

Run: `Get-Content .claude\agents\flutter-build-verifier.md -TotalCount 7`
Expected: lines 1 and 7 are `---`; `name:`, `description:`, `tools:`, `model:` present between them. No tab characters in the YAML.

- [ ] **Step 4: Commit**

```powershell
git add .claude/agents/flutter-build-verifier.md
git commit -m "feat(agents): add flutter-build-verifier subagent"
```

---

## Task 4: Smoke-test the flutter-build-verifier agent

**Context:** A subagent file existing isn't proof it works. Verify it is discoverable and produces the expected report shape against the current (known-green) tree.

**Files:** none (verification only)

- [ ] **Step 1: Confirm discoverability**

Run: `Get-ChildItem .claude\agents\*.md | Select-Object Name`
Expected: `flutter-build-verifier.md` listed. (Claude Code discovers project agents from `.claude/agents/`.)

- [ ] **Step 2: Dispatch the agent**

Using the Agent tool, dispatch `subagent_type: flutter-build-verifier` with prompt: "Verify the project is green. Report using your standard format." (This is a controller action, not a shell step.)

- [ ] **Step 3: Check the report**

Expected: a report in the documented format. Against today's tree the verdict should be `GREEN` with `test: PASS 184/184`, `analyze: OK 0 errors / 32 warnings`, `web: OK`, `apk: OK`.

If the verdict is RED or the count differs: STOP. Either the tree regressed (investigate separately — out of scope for this plan) or the agent prompt needs tightening (adjust `.claude/agents/flutter-build-verifier.md`, re-commit with `git commit --amend` is NOT allowed — make a new `fix(agents): ...` commit, then re-run this task).

- [ ] **Step 4: No commit**

Verification only. Confirm `git status --short` shows no changes from this task.

---

## Task 5: Create the flutter-widget-test-fixer subagent

**Context:** Tasks 2/3/4 of the 2026-05-13 plan were the same shape — a Hebrew/RTL widget-test assertion gone stale after a refactor — and each cost a separate general-purpose dispatch. This agent encodes the recurring patterns (empty-state from unmocked `ScanHistoryService`, exact-match `find.text` gotcha, the no-`pumpAndSettle` rule) so future test breakage is a cheap, focused fix.

**Files:**
- Create: `.claude/agents/flutter-widget-test-fixer.md`

- [ ] **Step 1: Write the agent file**

Create `.claude/agents/flutter-widget-test-fixer.md` with exactly:

```markdown
---
name: flutter-widget-test-fixer
description: Use to fix a failing/stale Flutter widget-test assertion in this Hebrew/RTL app — diagnoses what the screen actually renders vs. what the test asserts, then rewrites the assertion. Use when flutter test reports a widget-test failure that is an assertion mismatch (not a logic bug in app code).
tools: Read, Edit, Glob, Grep, Bash
model: sonnet
---

You fix stale widget-test assertions in the allergy-detector Flutter app. You change TEST code to match correct, intended UI behavior. You do NOT change app code to satisfy a test unless the controller explicitly says the app behavior is wrong.

## Environment & hard rules

- Flutter commands run from `app/` (PowerShell on Windows; Bash also available). Don't `cd app` if CWD is already `app/`.
- Don't redirect native-exe stderr with `2>&1` in PowerShell (it falsely exits 1). Pipe directly.
- NEVER use `pumpAndSettle` (or unbounded pump loops) in `search_scan_screen_test.dart`: `SearchScanScreen` runs a perpetual `_laserController.repeat()` and it will hang. Assert on the first frame after `pumpWidget`.
- All UI strings are hardcoded Hebrew; the tree is `Directionality(textDirection: TextDirection.rtl)`.

## Recurring failure patterns in this codebase

1. **Empty-state vs populated header.** Screens read recent data via `ScanHistoryService.getRecentScans`, which returns `[]` in widget tests (no SharedPreferences seed). A header that only renders when data is non-empty (e.g. `'פעילות אחרונה'`) will be absent; the screen shows an empty-state string instead (e.g. `'אין פעילות אחרונה מהסקר'`). Fix: assert the empty-state, not the populated header.
2. **`find.text` is exact-match.** Entering text into the search field flips `_showActiveSearch=true` and `build()` swaps in `ActiveSearchScreen`, which echoes the query inside a longer string (`'תוצאות חיפוש: <q>'`). `find.text('<q>')` finds 0 widgets. Fix: assert the full rendered string + a deterministic sibling (e.g. `'0 מוצרים נמצאו'` when no `productService` is injected).
3. **Removed fixture data.** Old tests asserted hardcoded sample products that a refactor deleted. Fix: drop those assertions; keep the still-valid structural ones (section headers, etc.).

## Procedure

1. Run the failing test in isolation: `flutter test <path> --plain-name "<name>"`. Capture the exact `Found N widgets with text "..."` message.
2. Read the screen widget to see what actually renders on the first frame for the unmocked path. Map the failure to one of the patterns above (or, if none fit, report `NEEDS_CONTEXT` — do not guess).
3. Rewrite ONLY the failing test block. Rename the test if its name now misdescribes what it checks. Add a one-line comment stating why the empty-state/transition is the path under test.
4. Re-run the single test → expect pass.
5. Run the whole file → expect no sibling regressions.
6. Commit with message `test(<area>): <what changed and why>` (one new commit; never --amend).

## Report

- Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
- The pattern matched (1/2/3/other) and the before→after assertion
- Single-test result and full-file result (final summary lines)
- Commit SHA
- Concerns, if any
```

- [ ] **Step 2: Validate the frontmatter parses**

Run: `Get-Content .claude\agents\flutter-widget-test-fixer.md -TotalCount 7`
Expected: lines 1 and 7 are `---`; `name`, `description`, `tools`, `model` keys present; no tabs in YAML.

- [ ] **Step 3: Commit**

```powershell
git add .claude/agents/flutter-widget-test-fixer.md
git commit -m "feat(agents): add flutter-widget-test-fixer subagent"
```

- [ ] **Step 4: Confirm discoverability**

Run: `Get-ChildItem .claude\agents\*.md | Select-Object Name`
Expected: both `flutter-build-verifier.md` and `flutter-widget-test-fixer.md` listed. (No behavioral smoke test here — there is no currently-failing test to fix, and intentionally breaking one to test the agent is out of scope. The agent earns its keep on the next real breakage.)

---

## Task 6: Scope unused MCP servers out of this project

**Context:** `/context` showed ~20k tokens consumed just to expose MCP tool schemas. Stitch is used for this project's UI work (per CLAUDE.md). Gmail and Google Calendar are never used here. Removing them from *this project's* surface reclaims tokens every session. CRITICAL: these may be user-scoped (shared with the user's other projects) — we must NOT remove them globally; only scope them out of this project, and if that's impossible without a user-scope change, escalate instead of acting.

**Files:**
- Modify: `.claude/settings.json` (conditionally — see Step 3)

- [ ] **Step 1: Discover how each MCP server is configured**

Run: `claude mcp list`
Then: `Test-Path .mcp.json` and, if `True`, `Get-Content .mcp.json`.
Record, for `Gmail`, `Google Calendar`, and `stitch`: is each defined in a project `.mcp.json`, or is it user/global scope? (claude.ai connectors typically show as user-scoped and have no `.mcp.json` entry.)

- [ ] **Step 2: Read current project settings**

Run: `Get-Content .claude\settings.json`
Expected: the JSON written previously with `permissions.allow` containing the flutter/dart/gradlew/Test-Path/stitch entries. Note the exact structure so the merge in Step 3 preserves it.

- [ ] **Step 3: Apply the correct scoping (branch on Step 1 findings)**

**Branch A — Gmail/Calendar are defined in a project `.mcp.json`:** add a `disabledMcpjsonServers` array to `.claude/settings.json`, preserving all existing keys. The file becomes (adjust server names to match `claude mcp list` output exactly):

```json
{
  "permissions": {
    "allow": [
      "Bash(flutter *)",
      "Bash(dart *)",
      "Bash(.\\gradlew.bat *)",
      "Bash(./gradlew *)",
      "PowerShell(flutter *)",
      "PowerShell(dart *)",
      "PowerShell(.\\gradlew.bat *)",
      "PowerShell(Test-Path *)",
      "mcp__stitch__list_projects",
      "mcp__stitch__list_screens",
      "mcp__stitch__get_screen",
      "mcp__stitch__get_project",
      "mcp__stitch__list_design_systems"
    ]
  },
  "disabledMcpjsonServers": ["Gmail", "Google Calendar"]
}
```

**Branch B — Gmail/Calendar are user/global scope (no project `.mcp.json` entry):** Do NOT modify global config. Leave `.claude/settings.json` unchanged. Write the finding into the report and into ROADMAP backlog instead (Step 5 handles the report). The escalation message to surface to the user: "Gmail/Calendar MCP are user-scoped — disabling them is a `claude mcp` user-level change that affects your other projects. I did not do this automatically. To reclaim the ~20k tokens here, run `claude mcp remove \"Gmail\" -s user` / `... \"Google Calendar\" -s user` if you don't use them anywhere, or toggle them per-session via `/mcp`."

- [ ] **Step 4: Validate JSON (only if Branch A modified the file)**

Run: `Get-Content .claude\settings.json -Raw | ConvertFrom-Json | Out-Null; if ($?) { "valid json" }`
Expected: `valid json`. If it errors, the edit malformed the JSON — fix before committing.

- [ ] **Step 5: Commit (Branch A) or record finding (Branch B)**

Branch A:
```powershell
git add .claude/settings.json
git commit -m "chore(mcp): scope Gmail/Calendar MCP out of this project"
```
Branch B: no commit. In your task report, state explicitly that Branch B was taken and include the escalation message verbatim so the controller can relay it to the user and add it to `docs/ROADMAP.md` backlog.

---

## Task 7: Create the verify helper scripts

**Context:** The "is it green" sequence and targeted test runs were retyped many times, each with manual output-tailing. Two committed scripts give humans and CI (ROADMAP #1) a single entry point and keep output token-light. PowerShell, since that's the project's shell.

**Files:**
- Create: `tools/verify.ps1`
- Create: `tools/test-quick.ps1`

- [ ] **Step 1: Confirm/create the tools directory**

Run: `Test-Path tools`
If `False`: `New-Item -ItemType Directory -Path tools | Out-Null`. Then `Get-ChildItem tools` (note existing contents so we don't clobber anything).

- [ ] **Step 2: Write `tools/verify.ps1`**

Create `tools/verify.ps1` with exactly:

```powershell
# Full green-check: test + analyze + web + apk. Summary output only.
# Usage (from repo root):  pwsh tools/verify.ps1   (or)   powershell -File tools\verify.ps1
$ErrorActionPreference = 'Continue'
Push-Location "$PSScriptRoot\..\app"
try {
    Write-Output "== flutter test =="
    flutter test | Select-Object -Last 3

    Write-Output "== flutter analyze =="
    flutter analyze | Select-Object -Last 3

    Write-Output "== flutter build web =="
    flutter build web --no-tree-shake-icons | Select-Object -Last 3

    Write-Output "== flutter build apk --debug =="
    flutter build apk --debug | Select-Object -Last 3
}
finally {
    Pop-Location
}
```

- [ ] **Step 3: Write `tools/test-quick.ps1`**

Create `tools/test-quick.ps1` with exactly:

```powershell
# Fast targeted test run. Pass a --plain-name filter, or a test file path, or nothing for the full suite.
# Usage:  powershell -File tools\test-quick.ps1 "displays recent activity"
#         powershell -File tools\test-quick.ps1 test/widgets/screens/home_screen_test.dart
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Filter)
Push-Location "$PSScriptRoot\..\app"
try {
    if (-not $Filter -or $Filter.Count -eq 0) {
        flutter test | Select-Object -Last 3
    }
    elseif ($Filter.Count -eq 1 -and (Test-Path (Join-Path (Get-Location) $Filter[0]))) {
        flutter test $Filter[0] | Select-Object -Last 3
    }
    else {
        flutter test --plain-name ($Filter -join ' ') | Select-Object -Last 3
    }
}
finally {
    Pop-Location
}
```

- [ ] **Step 4: Smoke-test test-quick.ps1 with a known test**

Run from repo root: `powershell -File tools\test-quick.ps1 "displays recent activity empty-state with Hebrew text"`
Expected: ends with `+1: All tests passed!` (this is the test fixed in the 2026-05-13 plan; it exists and passes).

- [ ] **Step 5: Smoke-test verify.ps1**

Run from repo root: `powershell -File tools\verify.ps1`
Expected: four `== ... ==` sections; test shows `+184`/`All tests passed!`, analyze shows `32 issues found`, web shows `✓ Built build\web`, apk shows `✓ Built ...app-debug.apk`. (~3-4 min wall time; this is the slow task.) If any section fails, the script itself is fine — it's a real tree problem; report it and stop.

- [ ] **Step 6: Commit**

```powershell
git add tools/verify.ps1 tools/test-quick.ps1
git commit -m "feat(tools): add verify.ps1 and test-quick.ps1 helper scripts"
```

---

## Done

After Task 7, the project has:
- **CLAUDE.md**: three operational notes loaded every session (pumpAndSettle, PS `2>&1`, CWD).
- **Memory**: two recallable entries with rationale, linked into the memory graph.
- **Agents**: `flutter-build-verifier` (smoke-tested green) and `flutter-widget-test-fixer` (discoverable, earns keep on next breakage).
- **MCP**: Gmail/Calendar scoped out of this project (Branch A) or escalated to the user (Branch B).
- **Tools**: `verify.ps1` / `test-quick.ps1` committed; reused by humans and by CI when ROADMAP #1 lands.

Update `docs/ROADMAP.md`: this work is a prerequisite-enabler for #1 (CI calls `tools/verify.ps1`) and #4 (lint cleanup can be driven by `flutter-build-verifier`'s warning-delta detection). Note completion there with the final commit SHA.

Follow-ups (NOT in this plan):
- Wire `tools/verify.ps1` into `.github/workflows/ci.yml` (ROADMAP #1).
- Reconsider deferred hooks only if the CWD/CLAUDE.md note proves insufficient in practice.
- Build `stitch-screen-implementer` / `rtl-hebrew-pr-reviewer` agents when ROADMAP #3 starts.
```
