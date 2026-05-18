# CI/CD Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a GitHub Actions workflow that runs `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web`, and `flutter build apk --debug` on every PR to `master` (plus pushes to `master`), locking in the current green state so the next regression is caught in minutes.

**Architecture:** A single workflow file `.github/workflows/ci.yml` with one required `build` job on `ubuntu-latest` (analyze + test + web + apk) and one optional non-blocking `ios` job on `macos-latest` (`flutter build ios --no-codesign`) that closes the manual iOS verification gap. Flutter is pinned to `3.41.7` (the local toolchain version) so CI matches developer machines. No GitHub secrets are needed: none of the CI steps execute `main()`, and `String.fromEnvironment('SUPABASE_URL'/'SUPABASE_KEY')` with no `--dart-define` compiles to empty strings — builds and tests succeed without live Supabase credentials.

**Tech Stack:** GitHub Actions, `subosito/flutter-action@v2` (Flutter SDK install + SDK/pub caching), `actions/setup-java@v4` (Temurin 21, Gradle caching), Flutter 3.41.7 / Dart 3.11.5, Android AGP 8.9.1 / Gradle 8.11.1 (Gradle heap stays at template default on CI runners — the host 3G pin from `[[project-android-gradle-heap-3g]]` is a dev-host constraint and must NOT be hardcoded into the workflow).

---

## File Structure

| File | Responsibility |
|------|----------------|
| `.github/workflows/ci.yml` | The entire CI definition. Two jobs: `build` (required, ubuntu) and `ios` (optional, macos, `continue-on-error`). All Flutter commands run with `working-directory: app`. |
| `docs/ROADMAP.md` | Update item #1 status to in-progress, then move to "Done" with the merge SHA on completion. |

There is no application code to change. The only risk surface is the YAML itself, so every task verifies by running the **exact command CI will run** locally first, then by watching the real workflow run via `gh`.

---

## Pre-flight: capture the known-good baseline

These expected outputs are referenced by later verification steps. Run them once before authoring the workflow so the plan's "Expected" values are real, not assumed.

- [ ] **Step 1: Confirm analyze is clean of errors**

Run (from repo root):

```bash
cd app && flutter analyze --no-fatal-infos --no-fatal-warnings
```

Expected: exit code `0`. Output ends with a summary line; info/warning lines may appear (there are ~32 pre-existing) but none are `error •`. `--no-fatal-infos --no-fatal-warnings` makes only `error`-severity diagnostics fail the step, matching the roadmap requirement "fail on errors only, not warnings".

> PowerShell note: do **not** pipe this through `2>&1` — Windows PowerShell 5.1 turns `flutter analyze`'s stderr summary into a `NativeCommandError` and reports exit 1 even on success (see `[[feedback_powershell_stderr]]`). Run the bare command.

- [ ] **Step 2: Confirm the full test suite is green**

Run:

```bash
cd app && flutter test
```

Expected: exit code `0`, final line `All tests passed!`, 184 tests. (`flutter test` runs everything under `app/test/`, including `test/integration/user_flows_test.dart`, which is a widget test and needs no device.)

- [ ] **Step 3: Confirm the web build succeeds with no credentials**

Run:

```bash
cd app && flutter build web --no-tree-shake-icons
```

Expected: exit code `0`, `✓ Built build/web`. No `--dart-define` is passed — this proves the no-secrets decision.

- [ ] **Step 4: Confirm the debug APK builds**

Run:

```bash
cd app && flutter build apk --debug
```

Expected: exit code `0`, `✓ Built build/app/outputs/flutter-apk/app-debug.apk`. (First run is slow — Gradle download. This is the step CI caching targets.)

If any of Steps 1–4 fail locally, **stop** — CI cannot be greener than the working tree. Fix the working tree first (that is Roadmap item #2 territory) or escalate before continuing.

---

## Task 1: Create the required `build` job

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write the workflow with the required build job**

Create `.github/workflows/ci.yml` with exactly this content:

```yaml
name: CI

on:
  pull_request:
    branches: [master]
  push:
    branches: [master]

# Cancel superseded runs on the same ref to save runner minutes.
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Analyze, Test & Build (web + apk)
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: app
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java 21 (Temurin)
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'

      - name: Set up Flutter 3.41.7
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.41.7
          channel: stable
          cache: true

      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('app/android/**/*.gradle*', 'app/android/gradle/wrapper/gradle-wrapper.properties') }}
          restore-keys: |
            gradle-${{ runner.os }}-

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze (errors only)
        run: flutter analyze --no-fatal-infos --no-fatal-warnings

      - name: Test
        run: flutter test

      - name: Build web
        run: flutter build web --no-tree-shake-icons

      - name: Build debug APK
        run: flutter build apk --debug
```

Notes baked into the choices above (do not "improve" without re-verifying):
- `working-directory: app` — every Flutter command runs from `app/`, never the repo root (see `[[feedback]]` / CLAUDE.md operational notes). `actions/checkout` runs at repo root by design; the per-step default handles the rest.
- `hashFiles` paths are **repo-root-relative** (GitHub Actions evaluates `hashFiles` from the workspace root, ignoring `working-directory`) — hence `app/android/...`, not `android/...`.
- `subosito/flutter-action@v2` with `cache: true` caches the Flutter SDK and the pub cache; combined with the Gradle cache this keeps reruns under ~5 min.
- No `--dart-define` and no `secrets.*` — intentional; see plan header.

- [ ] **Step 2: Lint the YAML locally**

Run (repo root):

```bash
python -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml')); print('YAML OK')"
```

Expected: `YAML OK`. If `python`/`pyyaml` is unavailable, instead run `gh workflow view` after push (Task 3) and rely on GitHub's own parser — but prefer catching syntax errors before pushing.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions pipeline (analyze, test, web, apk)

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 2: Add the optional non-blocking iOS job

**Files:**
- Modify: `.github/workflows/ci.yml` (append a second job)

- [ ] **Step 1: Append the `ios` job**

Add this job under `jobs:` in `.github/workflows/ci.yml`, as a sibling of `build` (same indentation as `build:`):

```yaml
  ios:
    name: Build iOS (no codesign)
    runs-on: macos-latest
    # Non-blocking: closes the manual iOS verification gap without
    # gating PRs on a slow, occasionally flaky macOS runner.
    continue-on-error: true
    defaults:
      run:
        working-directory: app
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Flutter 3.41.7
        uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.41.7
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build iOS (no codesign)
        run: flutter build ios --no-codesign
```

`continue-on-error: true` means a red `ios` job does **not** fail the overall check — branch protection (Task 4) will require only `build`. This matches the roadmap's "Bonus" framing: visibility without a hard gate.

- [ ] **Step 2: Re-lint the YAML**

Run (repo root):

```bash
python -c "import yaml,sys; d=yaml.safe_load(open('.github/workflows/ci.yml')); print(sorted(d['jobs'].keys()))"
```

Expected: `['build', 'ios']`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add non-blocking iOS no-codesign job

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Task 3: Prove the workflow runs green on a real PR

This is the integration test for the whole plan: the workflow only counts as working when GitHub actually runs it green.

- [ ] **Step 1: Push the current branch**

```bash
git push -u origin chore/claude-workflow-tooling
```

Expected: push succeeds; the workflow file is now on a branch GitHub can see.

- [ ] **Step 2: Open a PR to master**

```bash
gh pr create --base master --head chore/claude-workflow-tooling \
  --title "ci: add GitHub Actions pipeline" \
  --body "Implements Roadmap item #1. Adds .github/workflows/ci.yml: analyze (errors only), test, build web, build apk on PRs to master; optional non-blocking iOS job. No secrets required — build/test steps never execute main(), so empty Supabase env vars are fine.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

Expected: prints the PR URL. The `pull_request` trigger fires a CI run.

- [ ] **Step 3: Watch the run to completion**

```bash
gh run watch --exit-status $(gh run list --branch chore/claude-workflow-tooling --workflow CI --limit 1 --json databaseId --jq '.[0].databaseId')
```

Expected: the `build` job ends ✓ (green). `gh run watch --exit-status` returns non-zero only if a required job fails; the `ios` job's status does not affect this because of `continue-on-error`. Total wall time should be roughly 6–9 min cold, faster on cache hits.

- [ ] **Step 4: If the run is red, diagnose before changing anything**

Run:

```bash
gh run view --log-failed $(gh run list --branch chore/claude-workflow-tooling --workflow CI --limit 1 --json databaseId --jq '.[0].databaseId')
```

Triage by failing step:
- **`flutter pub get`** — likely a `pubspec.lock`/SDK mismatch; confirm `flutter-version: 3.41.7` matches `pubspec.yaml`'s `sdk: '>=3.11.0 <4.0.0'`.
- **`Analyze`** — a real `error •` exists; CI is doing its job. Fix the code or, if it's pre-existing and unrelated, note it — do not weaken the analyze flags beyond `--no-fatal-infos --no-fatal-warnings`.
- **`Test`** — a genuine failure or an environment assumption (e.g. a test that calls `Supabase.instance` without init). Fix the test, not the workflow.
- **`Build apk`** — usually Gradle/Java; confirm `setup-java` Temurin 21 ran before the build step. Do **not** add an `org.gradle.jvmargs` heap override to the workflow — runner memory differs from the dev host and the 3G pin is host-specific.

Apply the fix, commit, push; the PR's CI re-runs automatically. Repeat Step 3.

- [ ] **Step 5: Commit any fixes made during triage**

If Step 4 required code/test/workflow changes:

```bash
git add -A
git commit -m "ci: fix <specific failing step> surfaced by first CI run

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
git push
```

Then re-watch (Step 3) until the `build` job is green. If no fixes were needed, skip this step.

---

## Task 4: Make `build` a required check (branch protection)

This is what turns CI from "informational" into "catches regressions before merge".

- [ ] **Step 1: Require the build job on master**

Run (repo root):

```bash
gh api -X PUT repos/Maortz/allergy-detector/branches/master/protection \
  -H "Accept: application/vnd.github+json" \
  -f 'required_status_checks[strict]=true' \
  -f 'required_status_checks[contexts][]=Analyze, Test & Build (web + apk)' \
  -f 'enforce_admins=false' \
  -f 'required_pull_request_reviews=' \
  -f 'restrictions='
```

The context string `Analyze, Test & Build (web + apk)` must exactly match the `name:` of the `build` job in `ci.yml`. The `ios` job is intentionally **not** listed, so its red status never blocks a merge.

Expected: HTTP 200 with a JSON body describing the protection rule.

> If this returns `403`/`404`, the token lacks admin rights on the repo. Do not silently skip — report it: the pipeline still runs and reports on PRs, but merges won't be *gated* until an admin adds the required check via Settings → Branches → Branch protection rules → require `Analyze, Test & Build (web + apk)`.

- [ ] **Step 2: Verify the rule took effect**

```bash
gh api repos/Maortz/allergy-detector/branches/master/protection/required_status_checks --jq '.contexts'
```

Expected: `["Analyze, Test & Build (web + apk)"]`.

---

## Task 5: Update the roadmap

**Files:**
- Modify: `docs/ROADMAP.md`

- [ ] **Step 1: Move item #1 to Done**

In `docs/ROADMAP.md`:
1. Delete the entire "### 1. CI/CD pipeline (recommended next) — **not started**" section (lines covering its body, open questions, effort).
2. Renumber the remaining ranked items (#2→#1, #3→#2, #4→#3, #5→#4) and re-rank if appropriate.
3. Under `## Done`, replace the `*(empty …)*` line with:

```markdown
- **CI/CD pipeline** — 2026-05-17, merged in `<MERGE_SHA>`. `.github/workflows/ci.yml`: analyze (errors only) + test + web + apk on PRs/pushes to `master`; optional non-blocking iOS job; `build` job required via branch protection. No Supabase secrets needed (build/test never run `main()`).
```

4. Bump `**Last reviewed:**` to `2026-05-17`.

Use `<MERGE_SHA>` as a literal placeholder until the PR is merged, then replace it with the squash/merge commit SHA.

- [ ] **Step 2: Commit**

```bash
git add docs/ROADMAP.md
git commit -m "docs(roadmap): mark CI/CD pipeline done, re-rank backlog

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
git push
```

- [ ] **Step 3: Merge the PR once `build` is green**

```bash
gh pr merge --squash --delete-branch
```

Expected: merge succeeds (allowed only because the required `build` check passed). Capture the resulting merge SHA and substitute it for `<MERGE_SHA>` in `docs/ROADMAP.md` (a follow-up one-line commit on `master` is fine, or amend before merge if doing it manually).

---

## Self-Review

**Spec coverage (roadmap item #1):**
- `flutter pub get` → Task 1 Step 1 (`Install dependencies`). ✓
- `flutter analyze`, fail on errors only → Task 1 (`--no-fatal-infos --no-fatal-warnings`), verified Pre-flight Step 1. ✓
- `flutter test` → Task 1, Pre-flight Step 2. ✓
- `flutter build web --no-tree-shake-icons` → Task 1, Pre-flight Step 3. ✓
- `flutter build apk --debug` → Task 1, Pre-flight Step 4. ✓
- Bonus `flutter build ios --no-codesign` on macOS → Task 2. ✓
- Open question "Supabase keys" → resolved in plan header + proven by Pre-flight Steps 3–4 (no `--dart-define`); decision: no secrets. ✓
- Open question "cache strategy for gradle/pub" → `subosito/flutter-action` `cache: true` (SDK+pub) + `actions/cache` for `~/.gradle/caches`+`~/.gradle/wrapper` (Task 1 Step 1). ✓
- "catches the next regression" → Task 4 makes `build` a required check. ✓ (beyond the literal spec but required to deliver the stated *why*.)

**Placeholder scan:** Only intentional placeholders are `<MERGE_SHA>` (explicitly defined as fill-on-merge in Task 5) and the repo slug `Maortz/allergy-detector` (verified from `git remote -v`). No "TBD"/"add error handling"/"similar to" placeholders. All YAML and commands are complete and runnable.

**Consistency:** The job `name:` `Analyze, Test & Build (web + apk)` is used identically in Task 1 (definition), Task 4 Step 1 (required context), and Task 4 Step 2 (verification). Flutter `3.41.7` and Java Temurin `21` are consistent across `build` and `ios` jobs and match the captured local environment. `working-directory: app` is applied in both jobs; `hashFiles` paths are correctly repo-root-relative while run steps are `app/`-relative — the one asymmetry, called out explicitly in Task 1 Step 1 notes.
