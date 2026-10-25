# Issue #411 — Fix stale Gradle cache key in android-build.yml Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended for this single-task CI fix) or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the manual "Android Build" workflow's Gradle cache key actually hash the real Gradle build files, so toolchain/build-script bumps invalidate the cache.

**Architecture:** CI-YAML-only change. Replace the two `hashFiles(...)` argument lists in `.github/workflows/android-build.yml` (restore step line 47, save step line 86) with the pattern already used in `.github/workflows/ci.yml:96`. No Dart code, no tests added, no screens affected.

**Tech Stack:** GitHub Actions (`actions/cache@v4`, `actions/cache/save@v4`), Flutter 3 / Gradle Kotlin DSL.

**Spec:** GitHub issue #411 (`gh issue view 411 --repo Maortz/allergy-detector`).

**Branch:** `agent/issue-411-android-build-gradle-cache-key` — already created from up-to-date `origin/master` (5449ed4). Execution starts at Task 1. Do NOT re-create or rebase the branch.

**Plan file commit policy:** This plan file is left **uncommitted** by the planner. The execution agent commits it together with the workflow change in Task 1 Step 6 (single commit).

## Global Constraints

- ONE shell command per Bash tool call — no `&&`, `;`, or `|` chaining. Use absolute paths or `git -C /home/maortz/code/allergy-detector`.
- `flutter`/`dart` commands run with CWD `/home/maortz/code/allergy-detector/app` (do not prefix `cd app` if already there).
- Only file changed besides this plan: `.github/workflows/android-build.yml`. Do not touch `ci.yml`, `ios-build.yml`, Dart code, or Gradle files.
- Exact replacement argument list (verbatim from issue and `ci.yml:96`):
  `hashFiles('app/android/**/*.gradle*', 'app/android/gradle/wrapper/gradle-wrapper.properties')`
- Keep key prefix `gradle-${{ runner.os }}-` and `restore-keys` unchanged.
- Commit footer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

## Verified facts (planner checked against the repo)

- `android-build.yml:47` and `:86` both read:
  `key: gradle-${{ runner.os }}-${{ hashFiles('android/build.gradle', 'android/app/build.gradle', 'android/settings.gradle.kts') }}`
  None of those paths exist at the repo root (hashFiles resolves from `GITHUB_WORKSPACE`, ignoring `defaults.run.working-directory: app`), so the key collapses to `gradle-Linux-`.
- `ci.yml:96` already uses the correct pattern.
- Tracked files the new pattern matches: `app/android/build.gradle.kts`, `app/android/settings.gradle.kts`, `app/android/app/build.gradle.kts` (glob `**/*.gradle*`), plus `app/android/gradle/wrapper/gradle-wrapper.properties`. `app/android/gradle.properties` is NOT matched by `*.gradle*` (no `.gradle` substring after a dot) — same as ci.yml, acceptable.

## Review Focus

1. **Restore/save key mismatch** — the save step recomputes `hashFiles` after `flutter build apk`. If the build created a new file matching `app/android/**/*.gradle*`, the saved key would differ from the restored one. Expected: no build output matches (Flutter writes to `app/build/`; `app/android/.gradle/` contains no `*.gradle*`-named files). Task 1 Step 4 verifies the pattern against the working tree, including the local `.gradle` dir.
2. **Both occurrences changed** — a reviewer must see exactly two replaced lines, identical to each other. Task 1 Step 3 greps for this.
3. **YAML still parses** — `${{ }}` with single quotes inside a plain scalar must remain valid. Task 1 Step 2.
4. **No stray edits** to `restore-keys`, path list, or other workflows. Task 1 Step 5 checks `git diff --stat`.
5. **Regression sanity** — app analyze/test unaffected (Task 2).

---

### Task 1: Fix both hashFiles calls in android-build.yml

**Files:**
- Modify: `/home/maortz/code/allergy-detector/.github/workflows/android-build.yml:47` and `:86`
- Commit also: `/home/maortz/code/allergy-detector/docs/superpowers/plans/2026-10-25-issue-411-android-build-gradle-cache-key.md`

**Interfaces:** none (CI config only).

- [ ] **Step 1: Edit both key lines**

Use the Edit tool with `replace_all: true` on `.github/workflows/android-build.yml`:
- old: `hashFiles('android/build.gradle', 'android/app/build.gradle', 'android/settings.gradle.kts')`
- new: `hashFiles('app/android/**/*.gradle*', 'app/android/gradle/wrapper/gradle-wrapper.properties')`

Expected: 2 replacements. Resulting line (both places, same indentation as before):
```yaml
          key: gradle-${{ runner.os }}-${{ hashFiles('app/android/**/*.gradle*', 'app/android/gradle/wrapper/gradle-wrapper.properties') }}
```

- [ ] **Step 2: YAML validity**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1])); print('OK')" /home/maortz/code/allergy-detector/.github/workflows/android-build.yml`
Expected: `OK`

- [ ] **Step 3: Confirm both occurrences, no old pattern left**

Run: `grep -n "hashFiles" /home/maortz/code/allergy-detector/.github/workflows/android-build.yml`
Expected: exactly two lines (47, 86), both containing `hashFiles('app/android/**/*.gradle*', 'app/android/gradle/wrapper/gradle-wrapper.properties')`.

Run: `grep -c "android/build.gradle'" /home/maortz/code/allergy-detector/.github/workflows/android-build.yml`
Expected: `0`

- [ ] **Step 4: Confirm the new patterns match real files**

Run: `git -C /home/maortz/code/allergy-detector ls-files "app/android/*.gradle*" "app/android/**/*.gradle*" app/android/gradle/wrapper/gradle-wrapper.properties`
Expected (order may vary), non-empty:
```
app/android/app/build.gradle.kts
app/android/build.gradle.kts
app/android/settings.gradle.kts
app/android/gradle/wrapper/gradle-wrapper.properties
```

Run: `find /home/maortz/code/allergy-detector/app/android -type f -name "*.gradle*"`
Expected: only the three `*.gradle.kts` files above (no files from `app/android/.gradle/` or build output) — this confirms the save-step key equals the restore-step key (Review Focus 1).

- [ ] **Step 5: Diff scope check**

Run: `git -C /home/maortz/code/allergy-detector diff --stat`
Expected: only `.github/workflows/android-build.yml | 4 ++--` (plan file is untracked, shown by `git status`, not `diff`).

- [ ] **Step 6: Commit**

Run (each a separate call):
- `git -C /home/maortz/code/allergy-detector add .github/workflows/android-build.yml docs/superpowers/plans/2026-10-25-issue-411-android-build-gradle-cache-key.md`
- `git -C /home/maortz/code/allergy-detector commit -m "fix(ci): hash real Gradle files in android-build.yml cache key (#411)" -m "hashFiles() resolves from the repo root, so the old 'android/...' Groovy paths matched nothing and the key collapsed to the constant 'gradle-Linux-'. Use the same 'app/android/**/*.gradle*' + wrapper-properties pattern as ci.yml in both the restore and save steps." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

Expected: 1 commit, 2 files changed.

---

### Task 2: Regression sanity (app unaffected)

**Files:** none modified.

- [ ] **Step 1:** Run `flutter analyze lib test` with CWD `/home/maortz/code/allergy-detector/app`. Expected: `No issues found!`
- [ ] **Step 2:** Run `flutter test` with CWD `/home/maortz/code/allergy-detector/app`. Expected: `All tests passed!` (record the pass count for the PR body). If a test fails, check whether it also fails on `master` — a CI-YAML change cannot cause Dart test failures; note pre-existing failures in the PR body rather than fixing them.

---

### Task 3 (A6): Spec tracker

No screen is affected by this CI-only change — **skip**; do not edit `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

---

### Task 4 (A7): Drift check

- [ ] **Step 1:** `git -C /home/maortz/code/allergy-detector fetch origin`
- [ ] **Step 2:** `git -C /home/maortz/code/allergy-detector log origin/master..HEAD --oneline`
Expected: exactly ONE commit — the Task 1 commit. If any foreign commit appears (concurrent agents share the working copy), STOP: comment on #411, release the claim (Task 6 Step 2), and return `STOPPED foreign commits on branch`.

---

### Task 5 (A8): Push and open PR

- [ ] **Step 1:** `git -C /home/maortz/code/allergy-detector push -u origin agent/issue-411-android-build-gradle-cache-key`
- [ ] **Step 2:** `gh pr create --repo Maortz/allergy-detector --base master --head agent/issue-411-android-build-gradle-cache-key --title "fix(ci): hash real Gradle files in android-build.yml cache key (#411)" --body "<BODY>"` where `<BODY>` is:

```markdown
Closes #411

## Summary
- `.github/workflows/android-build.yml` (manual `workflow_dispatch` Android Build): both Gradle cache `key:` lines (restore + save) now use `hashFiles('app/android/**/*.gradle*', 'app/android/gradle/wrapper/gradle-wrapper.properties')`, matching `ci.yml`.
- Previously `hashFiles('android/build.gradle', 'android/app/build.gradle', 'android/settings.gradle.kts')` resolved from the repo root, matched nothing, and the key was the constant `gradle-Linux-`, so Gradle/AGP/KGP bumps never invalidated the cache.
- No Dart code changes; no screens affected.

## Verification
- YAML parses (`yaml.safe_load`): OK
- `grep hashFiles` → 2 occurrences, both the new pattern; old pattern count 0
- New pattern matches: `app/android/build.gradle.kts`, `app/android/settings.gradle.kts`, `app/android/app/build.gradle.kts`, `app/android/gradle/wrapper/gradle-wrapper.properties`
- `flutter analyze lib test`: <result>
- `flutter test`: <result, N passed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
Fill `<result>` placeholders with the actual Task 2 output before running. Pass the body via `--body-file` with a temp file in the scratchpad if quoting is awkward.

---

### Task 6 (A9): Link and release claim

- [ ] **Step 1:** `gh issue comment 411 --repo Maortz/allergy-detector --body "Fix opened in <PR URL> — both cache key hashFiles() calls in android-build.yml now use the ci.yml pattern."`
- [ ] **Step 2:** `gh issue edit 411 --repo Maortz/allergy-detector --remove-label agent-in-progress`
