# Android APK Clean-Build Fix Implementation Plan (revised baseline)

> **For agentic workers:** Execute task-by-task. Steps use checkbox (`- [ ]`) syntax. Every subagent MUST run exactly ONE shell command per tool call — no `&&`/`;`/pipe chaining, no batching. On Windows PowerShell never redirect native-exe stderr with `2>&1`.

**Goal:** Make `flutter build apk --debug` succeed from a genuinely clean checkout of `origin/master`, by cherry-picking the proven AGP 8 migration (`ad8c8ef`) onto `origin/master` and then de-duplicating the Gradle config onto the Kotlin DSL.

**Baseline correction (why this plan was revised):** The original plan assumed the migration was already on the working baseline. Investigation found local `master` (which has `ad8c8ef`) was never pushed and diverged from `origin/master`. `origin/master` still has the *real* bug: `app/android/settings.gradle` line 20 `apply from: ".../app_plugin_loader.gradle"` (imperative), `compileSdkVersion 34`, `gradle.properties=-Xmx1536M`, gradle-wrapper `gradle-7.5`, plus committed `.gradle`/`.gradle.kts` duplicate pairs. User decision: **branch off `origin/master` and cherry-pick `ad8c8ef`** (reuse proven work), then dedupe.

**Architecture:** `ad8c8ef` is a single self-contained migration commit (declarative `settings.gradle`, AGP 8.9.1, Kotlin 2.1.0, Gradle 8.11.1 wrapper, compileSdk 36, `Xmx3G -XX:+UseParallelGC`). Cherry-picking it onto `origin/master` will conflict only on `gradle.properties` (origin pre-image `-Xmx1536M` ≠ commit pre-image `-Xmx4G`); resolve to the commit's post-image. The migration fixes the Groovy files; we then delete those Groovy files and keep their `.kts` twins (pinned to the *verified* AGP 8.9.1 / Kotlin 2.1.0, `compileSdk = 36`).

**Tech Stack:** Flutter 3.41.x, Gradle 8.11.1 wrapper, AGP 8.9.1, Kotlin 2.1.0, compileSdk 36, GitHub Actions.

---

## Conventions (every task)

- **Work tree:** `C:\Users\Administrator\git\_apk-fix` (branch `fix/android-apk-clean-build`, based on `origin/master` @ `168916a`). Already created.
- **Source repo (read-only ref):** `C:\Users\Administrator\git\allergy-detector` — local `master` holds `ad8c8ef` to cherry-pick from. Do not modify it.
- **Reproduction temp:** `C:\Users\Administrator\git\_apk-repro` (throwaway).
- ONE shell command per tool call. No `2>&1` on native exes. `flutter` runs from the `app/` dir of the relevant tree.
- A fresh clone has no `app/android/local.properties` (gitignored); `flutter pub get` regenerates it — correct clean-tree behavior, matches CI.

---

## Task 1: Isolated branch off origin/master — DONE

Worktree `C:\Users\Administrator\git\_apk-fix` exists on `fix/android-apk-clean-build` @ `168916a` (origin/master, clean, no WIP). No commit. ✓ Complete.

---

## Task 2: Cherry-pick the proven migration `ad8c8ef`

**Files:** `app/android/settings.gradle`, `app/android/build.gradle`, `app/android/app/build.gradle`, `app/android/gradle.properties`, `app/android/gradle/wrapper/gradle-wrapper.properties` (all via cherry-pick).

- [ ] **Step 1: Start the cherry-pick**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix cherry-pick ad8c8ef`
Expected: either success, or a conflict stop reporting `app/android/gradle.properties` (and possibly others) in conflict. Do NOT abort on conflict — resolve in the next steps.

- [ ] **Step 2: Inspect conflict state**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix status`
Note exactly which files are "Unmerged". Expected primary conflict: `app/android/gradle.properties`.

- [ ] **Step 3: Resolve `gradle.properties` to the known-good post-migration content**

Set `C:\Users\Administrator\git\_apk-fix\app\android\gradle.properties` to EXACTLY:
```
org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+UseParallelGC
android.useAndroidX=true
android.enableJetifier=true
```
(This is `ad8c8ef`'s post-image — `Xmx3G` is correct for the 7 GB host; the template's 4G OOMs it. Do NOT use 4G.)

- [ ] **Step 4: Resolve any other conflicts to ad8c8ef's post-image**

For each remaining unmerged file, take **`ad8c8ef`'s version** (the incoming/migration side): `git -C C:\Users\Administrator\git\_apk-fix checkout --theirs <path>` then stage it. Rationale: the migration's post-image is the proven-good state; origin/master's side is the broken pre-migration state. (Expected: only `gradle.properties` needs manual merge; `settings.gradle`, `build.gradle`, `app/build.gradle`, `gradle-wrapper.properties` should apply cleanly since origin/master matches the commit's pre-image.)

- [ ] **Step 5: Stage resolved files**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix add app/android/gradle.properties`
Then, only if Step 4 found other files, one `git add <path>` per remaining file (one command per call).

- [ ] **Step 6: Verify the resolved settings.gradle is declarative (no imperative apply)**

Read `C:\Users\Administrator\git\_apk-fix\app\android\settings.gradle`. Confirm it has a top-level `plugins { ... dev.flutter.flutter-plugin-loader ... com.android.application ... org.jetbrains.kotlin.android ... }` block and **no** `apply from: ".../app_plugin_loader.gradle"` line. If the imperative line is still present, the conflict was mis-resolved — fix it to ad8c8ef's post-image before continuing.

- [ ] **Step 7: Complete the cherry-pick**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix cherry-pick --continue`
If git opens an editor, the command should accept the existing message. Expected: a new commit on the branch with `ad8c8ef`'s message.

- [ ] **Step 8: Confirm**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix log --oneline -2`
Expected: top commit is the cherry-picked migration; parent is `168916a`.

---

## Task 3: De-duplicate — pin verified versions in the Kotlin files

**Files (work tree):** `app/android/settings.gradle.kts`, `app/android/app/build.gradle.kts`

- [ ] **Step 1: Pin verified AGP/Kotlin in `settings.gradle.kts`**

In `C:\Users\Administrator\git\_apk-fix\app\android\settings.gradle.kts`, change the `plugins {}` block from the untested:
```kotlin
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
```
to the verified (matches the cherry-picked Groovy settings.gradle):
```kotlin
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```
Leave the `dev.flutter.flutter-plugin-loader` line and everything else unchanged.

- [ ] **Step 2: Pin explicit `compileSdk = 36` in `app/build.gradle.kts`**

In `C:\Users\Administrator\git\_apk-fix\app\android\app\build.gradle.kts`, change `compileSdk = flutter.compileSdkVersion` to `compileSdk = 36`. Leave `ndkVersion = flutter.ndkVersion`, `namespace = "com.example.app"`, Java 17 options, and the debug `signingConfig` unchanged.

- [ ] **Step 3: Confirm Kotlin source layout needs no `srcDirs` override**

Confirm `C:\Users\Administrator\git\_apk-fix\app\android\app\src\main\kotlin\com\example\app\MainActivity.kt` exists. The `org.jetbrains.kotlin.android` plugin treats `src/main/kotlin` as a source root by default in Kotlin 2.x, so the Groovy file's explicit `srcDirs` override is not needed once it is deleted in Task 4. No edit; confirmation only.

- [ ] **Step 4: Commit**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix add app/android/settings.gradle.kts app/android/app/build.gradle.kts`
Then (one command): `git -C C:\Users\Administrator\git\_apk-fix commit -m "fix(android): pin verified AGP 8.9.1/Kotlin 2.1.0 and compileSdk 36 in Kotlin DSL"` (append `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>` as a second message line via a second `-m`).

---

## Task 4: Delete the Groovy duplicates

**Files (work tree):** delete `app/android/settings.gradle`, `app/android/build.gradle`, `app/android/app/build.gradle`. Do NOT touch `gradle.properties` (no duplicate; 3G heap is host-critical).

- [ ] **Step 1: git rm the three Groovy files**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix rm app/android/settings.gradle app/android/build.gradle app/android/app/build.gradle`
Expected: three `rm '...'` lines.

- [ ] **Step 2: Confirm no functional references to the deleted files**

Use the Grep tool to search `C:\Users\Administrator\git\_apk-fix\app\android` and `.github` for `apply from` and literal `settings.gradle"` / `build.gradle'`. Expected: none functional (an `app_android.iml` IDE-artifact mention is cosmetic, ignorable).

- [ ] **Step 3: Commit**

Run (one command): `git -C C:\Users\Administrator\git\_apk-fix commit -m "fix(android): delete Groovy Gradle duplicates, standardize on Kotlin DSL" -m "Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"`

---

## Task 5: Verify from a genuinely clean tree

**Files:** none (the success gate).

- [ ] **Step 1:** Run (one command): `Remove-Item -Recurse -Force C:\Users\Administrator\git\_apk-repro -ErrorAction SilentlyContinue`
- [ ] **Step 2:** Run (one command): `git clone --branch fix/android-apk-clean-build C:\Users\Administrator\git\_apk-fix C:\Users\Administrator\git\_apk-repro`
- [ ] **Step 3:** Run (one command, in `C:\Users\Administrator\git\_apk-repro\app`): `flutter pub get` → expect `Got dependencies!`
- [ ] **Step 4:** Run (one command, in `C:\Users\Administrator\git\_apk-repro\app`): `flutter build apk --debug` → expect `✓ Built build\app\outputs\flutter-apk\app-debug.apk`. **Primary success gate.** On failure: capture full output, do NOT proceed, report for diagnosis.
- [ ] **Step 5:** Run (one command, in `C:\Users\Administrator\git\_apk-repro\app`): `flutter analyze` (no `2>&1`) → expect 0 errors; ~32 pre-existing infos/warnings unchanged.
- [ ] **Step 6:** Run (one command, in `C:\Users\Administrator\git\_apk-repro\app`): `flutter test` → expect all pass (~184 baseline; count may differ on origin/master — any *failure* is a regression, stop).
- [ ] **Step 7:** No commit. Record the APK build success line for the PR body.

---

## Task 6: Make CI `apk` job report honest red/green

**Files (work tree):** `.github/workflows/ci.yml` (present — origin/master has CI from PR #1).

- [ ] **Step 1:** Read `C:\Users\Administrator\git\_apk-fix\.github\workflows\ci.yml`; locate the `apk` job's `continue-on-error: true`.
- [ ] **Step 2:** Remove that line from the `apk` job ONLY (leave the `ios` job's `continue-on-error` intact — out of scope). Do not attempt branch-protection (blocked: private repo, no Pro).
- [ ] **Step 3:** Visually confirm YAML indentation still valid (job key / `runs-on` / `steps` aligned).
- [ ] **Step 4:** Commit. Run (one command): `git -C C:\Users\Administrator\git\_apk-fix add .github/workflows/ci.yml` then (one command): `git -C C:\Users\Administrator\git\_apk-fix commit -m "ci: make apk job blocking now that clean-tree build is green" -m "Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"`

---

## Task 7: Update ROADMAP + project memory

**Files:** `docs/ROADMAP.md` (work tree). `docs/ROADMAP.md` is NOT on origin/master (it was untracked WIP). Create it fresh in the work tree from the canonical content, OR if absent, add a short `docs/ROADMAP.md` Done entry. Also update user memory files in place (outside git).

- [ ] **Step 1:** Check whether `C:\Users\Administrator\git\_apk-fix\docs\ROADMAP.md` exists. If not, this branch (off origin/master) never had it — create it containing at minimum a `## Done` entry (below) plus a `## Backlog` note; do not attempt to reconstruct the full prior roadmap.
- [ ] **Step 2:** Done entry text:
```
- **Android APK clean-build fix** — 2026-05-18, branch `fix/android-apk-clean-build` off `origin/master`. origin/master still had the real imperative `apply from: app_plugin_loader.gradle` bug (+ compileSdk 34, Xmx1536M, gradle-7.5, .gradle/.kts duplicates). Fixed by cherry-picking the proven migration `ad8c8ef` (declarative settings.gradle, AGP 8.9.1, Kotlin 2.1.0, Gradle 8.11.1, compileSdk 36, Xmx3G+UseParallelGC) then deleting the Groovy duplicates to standardize on Kotlin DSL. Verified `flutter build apk --debug` green from a fresh clone. CI `apk` job de-`continue-on-error`'d. Note: local `master` had `ad8c8ef` but was never pushed and is diverged — separate cleanup. Deferred: enforced branch-protection blocked on GitHub Pro/public.
```
- [ ] **Step 3:** Backlog note: `- Reconcile diverged local master (has unpushed ad8c8ef + feature/test commits) with origin/master.`
- [ ] **Step 4:** Commit. (one command) `git -C C:\Users\Administrator\git\_apk-fix add docs/ROADMAP.md` then (one command) `git -C C:\Users\Administrator\git\_apk-fix commit -m "docs(roadmap): record Android APK clean-build fix done" -m "Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"`
- [ ] **Step 5:** Update `C:\Users\Administrator\.claude\projects\C--Users-Administrator-git-allergy-detector\memory\project_ci_state_2026_05.md`: replace the "APK BROKEN from clean checkout" bullet with the fixed status + the diverged-master finding; update the matching `MEMORY.md` one-liner. (User memory, in place, not git.)

---

## Task 8: Finish the development branch

- [ ] **Step 1:** Re-confirm Task 5 gates green; `git -C C:\Users\Administrator\git\_apk-fix status` clean; `git -C C:\Users\Administrator\git\_apk-fix log --oneline 168916a..fix/android-apk-clean-build` shows the expected commits.
- [ ] **Step 2:** (one command) `Remove-Item -Recurse -Force C:\Users\Administrator\git\_apk-repro -ErrorAction SilentlyContinue`
- [ ] **Step 3:** Invoke `superpowers:finishing-a-development-branch`. Recommended: push branch + open PR to `origin/master` so the now-blocking CI `apk` job validates the fix in the real gate, then remove the `_apk-fix` worktree.

---

## Self-review notes

- Baseline corrected to `origin/master` per user decision; Task 1 already satisfied it.
- Cherry-pick (Task 2) reuses proven `ad8c8ef` rather than redoing the migration; only `gradle.properties` needs manual resolution (to `Xmx3G` — host-critical, not the template 4G).
- `45fee99` deliberately NOT cherry-picked: `ad8c8ef` supersedes its 4G with 3G; pulling 45fee99 would add a no-op then-reverted hunk.
- Dedupe + version-pin (Tasks 3–4) unchanged in intent from the original spec; verified versions (8.9.1/2.1.0) chosen over the `.kts`'s untested 8.11.1/2.2.20.
- Clean-tree gate (Task 5) catches the Java 8→17 / desugaring risk and any residual cherry-pick error.
- ROADMAP/memory handling adjusted because `docs/ROADMAP.md` is not on origin/master (was untracked WIP).
- One-command-per-tool-call enforced in every task per user requirement.
