# Issue #414 — Add pub cache + pinned Java 17 to android-build.yml Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended for this single-task CI fix) or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the manual "Android Build" workflow's setup in line with `ci.yml`'s `apk` job by adding a pub-cache step and a pinned Java 17 (Temurin) step.

**Architecture:** CI-YAML-only, purely additive change to `.github/workflows/android-build.yml`. Two steps are copied verbatim from `.github/workflows/ci.yml` (`apk` job, lines 70-74 and 83-88) and inserted in the same relative order `ci.yml` uses: Checkout → Java 17 → Flutter → Cache pub → Gradle cache → `flutter pub get`. No Dart code, no tests added, no screens affected.

**Tech Stack:** GitHub Actions (`actions/setup-java@v4`, `actions/cache@v4`), Flutter / Gradle.

**Spec:** GitHub issue #414 (`gh issue view 414 --repo Maortz/allergy-detector`).

**Branch:** `agent/issue-414-android-build-pub-cache-java17` — already created from up-to-date `origin/master` (880d0e5). Execution starts at Task 1. Do NOT re-create or rebase the branch.

**Plan file commit policy:** This plan file is left **uncommitted** by the planner. The execution agent commits it together with the workflow change in Task 1 Step 6 (single commit).

## Global Constraints

- ONE shell command per Bash tool call — no `&&`, `;`, or `|` chaining. Use absolute paths or `git -C /home/maortz/code/allergy-detector`.
- `flutter`/`dart` commands run with CWD `/home/maortz/code/allergy-detector/app` (do not prefix `cd app` if already there).
- Only file changed besides this plan: `.github/workflows/android-build.yml`. Do not touch `ci.yml`, `ios-build.yml`, Dart code, or Gradle files.
- Do not modify any existing step in `android-build.yml` (Setup Flutter keeps its `flutter-version: ${{ inputs.flutter_version || '' }}` input; Gradle restore/save steps, Build APK, Upload, Build summary unchanged). Additions only.
- Step names and bodies must be byte-identical to `ci.yml`'s `apk` job (names `Set up Java 17 (Temurin)` and `Cache pub`).
- Commit footer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

## Verified facts (planner checked against the repo at 880d0e5)

- `android-build.yml` steps today: Checkout repository (30-31), Setup Flutter (33-38), Restore Gradle cache (40-49), Flutter pub get (51-52), Build APK, Upload APK artifact, Save Gradle cache, Build summary. No `setup-java`, no `~/.pub-cache` cache.
- `ci.yml` `apk` job order: Checkout → Set up Java 17 (Temurin) → Set up Flutter → Cache pub → Cache Gradle → Install dependencies → Build.
- `hashFiles()` resolves from the repo root (ignores `defaults.run.working-directory: app`), so `hashFiles('app/pubspec.lock')` is the correct path; `app/pubspec.lock` is tracked.
- `actionlint` is NOT installed on the dev host; YAML validity is checked with Python `yaml.safe_load` (precedent: issue #411 plan).

## Review Focus

1. **Java before Flutter** — `setup-java` must precede `subosito/flutter-action` so `JAVA_HOME` is set for every later step (Gradle). Task 1 Step 3 checks step order.
2. **Pub cache before `flutter pub get`** — otherwise the restore is useless. Task 1 Step 3.
3. **Verbatim copy** — `java-version: '17'` must stay quoted (string), key `pub-${{ hashFiles('app/pubspec.lock') }}` with root-relative path, `restore-keys: pub-`. Task 1 Step 4 diffs the inserted lines against `ci.yml`.
4. **YAML still parses** — new `${{ }}` scalar and indentation (6 spaces for `- name`, 8 for `uses/with`, 10 for `with` keys). Task 1 Step 2.
5. **No stray edits** to existing steps or other workflows; overlap with `flutter-action`'s own `cache: true` is accepted (same as `ci.yml`). Task 1 Step 5 checks `git diff --stat` = 12 insertions, 0 deletions.

---

### Task 1: Add Java 17 and pub-cache steps to android-build.yml

**Files:**
- Modify: `/home/maortz/code/allergy-detector/.github/workflows/android-build.yml` (insert after line 31 and after line 38)
- Commit also: `/home/maortz/code/allergy-detector/docs/superpowers/plans/2026-10-26-issue-414-android-build-pub-cache-java17.md`

**Interfaces:** none (CI config only).

- [ ] **Step 1: Insert the two steps**

Edit 1 — insert the Java step between "Checkout repository" and "Setup Flutter". Use the Edit tool:
- old:
```yaml
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Flutter
```
- new:
```yaml
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java 17 (Temurin)
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Setup Flutter
```

Edit 2 — insert the pub-cache step between "Setup Flutter" and "Restore Gradle cache":
- old:
```yaml
          cache: true

      - name: Restore Gradle cache
```
- new:
```yaml
          cache: true

      - name: Cache pub
        uses: actions/cache@v4
        with:
          path: ~/.pub-cache
          key: pub-${{ hashFiles('app/pubspec.lock') }}
          restore-keys: pub-

      - name: Restore Gradle cache
```

- [ ] **Step 2: YAML validity**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1])); print('OK')" /home/maortz/code/allergy-detector/.github/workflows/android-build.yml`
Expected: `OK`

- [ ] **Step 3: Step order**

Run: `python3 -c "import yaml,sys; print([s['name'] for s in yaml.safe_load(open(sys.argv[1]))['jobs']['build']['steps']])" /home/maortz/code/allergy-detector/.github/workflows/android-build.yml`
Expected exactly:
`['Checkout repository', 'Set up Java 17 (Temurin)', 'Setup Flutter', 'Cache pub', 'Restore Gradle cache', 'Flutter pub get', 'Build APK', 'Upload APK artifact', 'Save Gradle cache', 'Build summary']`

- [ ] **Step 4: Verbatim match with ci.yml**

Run: `python3 -c "import yaml,sys; a={s['name']:s for s in yaml.safe_load(open(sys.argv[1]))['jobs']['build']['steps']}; c={s['name']:s for s in yaml.safe_load(open(sys.argv[2]))['jobs']['apk']['steps']}; print(all(a[n]==c[n] for n in ['Set up Java 17 (Temurin)','Cache pub']))" /home/maortz/code/allergy-detector/.github/workflows/android-build.yml /home/maortz/code/allergy-detector/.github/workflows/ci.yml`
Expected: `True`

- [ ] **Step 5: Diff scope check**

Run: `git -C /home/maortz/code/allergy-detector diff --stat`
Expected: only `.github/workflows/android-build.yml | 12 ++++++++++++` (1 file, 12 insertions, 0 deletions). The plan file is untracked (shown by `git status`, not `diff`).

- [ ] **Step 6: Commit**

Run (each a separate call):
- `git -C /home/maortz/code/allergy-detector add .github/workflows/android-build.yml docs/superpowers/plans/2026-10-26-issue-414-android-build-pub-cache-java17.md`
- `git -C /home/maortz/code/allergy-detector commit -m "fix(ci): add pub cache and pinned Java 17 to android-build.yml (#414)" -m "Mirror ci.yml's apk job: set up Temurin JDK 17 before Flutter so the manual Android Build compiles against the same JDK as CI instead of the runner-image default, and cache ~/.pub-cache keyed on app/pubspec.lock before flutter pub get." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

Expected: 1 commit, 2 files changed.

---

### Task 2: Regression sanity (app unaffected)

**Files:** none modified. CWD `/home/maortz/code/allergy-detector/app`, one command per call.

- [ ] **Step 1:** `flutter pub get` — Expected: `Got dependencies!` (or `Resolving dependencies...` with no errors). `pubspec.lock` must not change (`git -C /home/maortz/code/allergy-detector status --short` shows nothing new under `app/`).
- [ ] **Step 2:** `flutter analyze lib test` — Expected: `No issues found!`
- [ ] **Step 3:** `flutter test` — Expected: `All tests passed!` (record the pass count for the PR body). If a test fails, check whether it also fails on `master` — a CI-YAML change cannot cause Dart test failures; note pre-existing failures in the PR body rather than fixing them.

---

### Task 3 (A6): Spec tracker

No screen is affected by this CI-only change — **no change warranted**; do not edit `docs/superpowers/specs/2026-05-19-stitch-screens/index.md`.

---

### Task 4 (A7): Drift check

- [ ] **Step 1:** `git -C /home/maortz/code/allergy-detector fetch origin`
- [ ] **Step 2:** `git -C /home/maortz/code/allergy-detector log origin/master..HEAD --oneline`
Expected: exactly ONE commit — the Task 1 commit. If any foreign commit appears (concurrent agents share the working copy), STOP: comment on #414, release the claim (Task 6 Step 2), and return `STOPPED foreign commits on branch`.

---

### Task 5 (A8): Push and open PR

- [ ] **Step 1:** `git -C /home/maortz/code/allergy-detector push -u origin agent/issue-414-android-build-pub-cache-java17`
- [ ] **Step 2:** `gh pr create --repo Maortz/allergy-detector --base master --head agent/issue-414-android-build-pub-cache-java17 --title "fix(ci): add pub cache and pinned Java 17 to android-build.yml (#414)" --body-file <tmpfile>` where `<tmpfile>` (written to the scratchpad) contains:

```markdown
Closes #414

## Summary
- `.github/workflows/android-build.yml` (manual `workflow_dispatch` Android Build) now mirrors `ci.yml`'s `apk` job setup:
  - **Set up Java 17 (Temurin)** (`actions/setup-java@v4`) before Setup Flutter — the manual build no longer depends on the `ubuntu-latest` image's default JDK.
  - **Cache pub** (`actions/cache@v4`, `~/.pub-cache`, key `pub-${{ hashFiles('app/pubspec.lock') }}`) before `flutter pub get`.
- Purely additive (12 lines); no existing steps changed. No Dart code changes; no screens affected.

## Verification
- YAML parses (`yaml.safe_load`): OK
- Step order: Checkout → Java 17 → Flutter → Cache pub → Gradle cache → pub get → Build …
- New steps are identical to `ci.yml` `apk` job steps (parsed-YAML equality): True
- `git diff --stat`: 1 file, 12 insertions, 0 deletions
- `flutter analyze lib test`: <result>
- `flutter test`: <result, N passed>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
Fill `<result>` placeholders with the actual Task 1/Task 2 output before running.

---

### Task 6 (A9): Link, release claim, return to master

- [ ] **Step 1:** `gh issue comment 414 --repo Maortz/allergy-detector --body "Fix opened in <PR URL> — android-build.yml now sets up Temurin Java 17 and caches ~/.pub-cache, matching ci.yml's apk job."`
- [ ] **Step 2:** `gh issue edit 414 --repo Maortz/allergy-detector --remove-label agent-in-progress`
- [ ] **Step 3:** `git -C /home/maortz/code/allergy-detector checkout master`
