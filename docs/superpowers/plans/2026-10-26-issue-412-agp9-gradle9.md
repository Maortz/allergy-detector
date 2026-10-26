# Issue #412 — Gradle 9.1 / AGP 9.0.1 / KGP 2.3.20 Toolchain Bump Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended — one cohesive config change) or superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `flutter build apk --debug` on Flutter 3.47.7 succeed with **none** of the three "Flutter support for your project's … version … will soon be dropped" warnings, while keeping CI (Flutter 3.41.7, JDK 17) green.

**Architecture:** Android build-toolchain config change in `app/android/` (Gradle wrapper + AGP + KGP versions) plus one pub dependency bump (`device_info_plus`) that AGP 9 forces. `android.newDsl=false` and `android.builtInKotlin=false` are deliberately KEPT (see scope note). No Dart source changes.

**Tech Stack:** Flutter 3.47.7 (local) / 3.41.7 (CI), Gradle wrapper, Android Gradle Plugin, Kotlin Gradle Plugin, Kotlin DSL build scripts, JDK 17.

**Spec:** GitHub issue #412 (`gh issue view 412 --repo Maortz/allergy-detector`). Precedent: `docs/superpowers/plans/2026-10-25-issue-404-gradle-8-14.md`. No screen spec applies.

**Branch:** `agent/issue-412-agp9-gradle9` is ALREADY CREATED from up-to-date `origin/master` and checked out in the main checkout `/home/maortz/code/allergy-detector` (this plan file is the only, uncommitted, change). Do not re-create it. Execution starts at Task 1.

**Shell rule:** ONE command per Bash call — no `&&`, `;` or `|` chaining. Use absolute paths / `git -C /home/maortz/code/allergy-detector`. Flutter commands run with CWD `/home/maortz/code/allergy-detector/app` (`$APP` below). If your CWD is already `app/`, do not prefix `cd app` (fails with `app/app does not exist`). `flutter pub get` also accepts `--directory $APP`; `flutter analyze` accepts absolute paths (`flutter analyze $APP/lib $APP/test`).

## Research findings (done during planning — do not redo)

Flutter 3.47.7 `packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt:94-109`:

| Dependency | Error floor | Warn floor | master today | **Target** |
|---|---|---|---|---|
| Gradle | 8.14.0 | 9.1.0 | 8.14.3 | **9.1.0** |
| AGP | 8.11.1 | 9.0.1 | 8.11.1 | **9.0.1** |
| KGP | 2.2.20 | 2.3.20 | 2.2.20 | **2.3.20** |
| Java | 17 | 17 | 17 | 17 (unchanged) |

**Why the warn floors, not Flutter's template defaults (Gradle 9.3.1 / AGP 9.1.0 / KGP 2.4.0):** CI runs Flutter **3.41.7**, whose `gradle_utils.dart` knows `maxKnownAndSupportedAgpVersion = '9.0'` and validates AGP 9.0.x against Gradle `9.0 … 9.1.0` (`maxKnownAndSupportedGradleVersion = '9.1.0'`). Gradle 9.1.0 + AGP 9.0.1 is the newest pair inside 3.41.7's validated range; going higher only adds CI risk with no warning-removal benefit.

**Scope note — why the issue's premise ("requires the newDsl/builtInKotlin migration") is wrong, and why the flags stay `false`:**
- Flutter 3.47.7's own app template (`templates/app/android.tmpl/gradle.properties.tmpl`) ships AGP 9.1.0 **with** `android.newDsl=false` and `android.builtInKotlin=false`, and its migrators (`disable_new_dsl_migration.dart`, `disable_built_in_kotlin_migration.dart`) add those opt-outs to existing projects. AGP 9 honors both opt-outs (removed only in AGP 10).
- `android.newDsl=true` is **blocked upstream**: the Flutter Gradle Plugin still uses the legacy variant API / `BaseExtension`; Flutter's migration off them is in progress (flutter/flutter#180137, #166550; `docs/platforms/android/Migrating-Flutter-Gradle-Plugin-to-AGP-public-API.md`, phase P9 "newDsl flip" not landed).
- `android.builtInKotlin=true` is **blocked upstream**: `device_info_plus`, `package_info_plus` and `share_plus` — including their latest releases (13.3.0 / 10.2.2 / 13.3.1) — still `apply(plugin = "org.jetbrains.kotlin.android")` in their Android build scripts.
- The app keeps `id("kotlin-android")` in `app/android/app/build.gradle.kts`. Flutter 3.47.7 would auto-apply KGP if removed, but Flutter **3.41.7 (CI) has no such logic** (no `isBuiltInKotlinEnabled`, no newDsl/builtInKotlin migrators), so removing it would break the CI APK build.

**Probe result (planning, reverted):** with exactly Gradle 9.1.0 / AGP 9.0.1 / KGP 2.3.20, `flutter build apk --debug` on 3.47.7 printed none of the "will soon be dropped" warnings but FAILED at `:device_info_plus:checkDebugAarMetadata` — `device_info_plus 9.1.2` hard-codes `compileSdkVersion 33` and AGP 9 rejects androidx deps needing compileSdk ≥ 34. Fix: `device_info_plus: ^12.4.0` (uses `compileSdk = flutter.compileSdkVersion`; requires Flutter ≥ 3.29.0 → CI 3.41.7 OK). `^13.x` is NOT usable: it needs `win32 ^6` which conflicts with `share_plus ^12.0.2` (would cascade into share_plus/package_info_plus major bumps). With `^12.4.0` the build succeeded (`✓ Built build/app/outputs/flutter-apk/app-debug.apk`, ~48 s) and `flutter analyze lib test` reported `No issues found!`. The only API used (`lib/services/device_context_service.dart:75-90`: `webBrowserInfo.platform/browserName`, `androidInfo.version.release/manufacturer/model`, `iosInfo.systemVersion/utsname.machine`) is unchanged.

**Expected residual (non-version) warnings after the change — acceptable, out of scope, mention in PR:**
- `WARNING: Your Android app project: app … applies the Kotlin Gradle Plugin, which will cause build failures in future versions of Flutter.` (kept for CI 3.41.7 compatibility, see above)
- `WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): device_info_plus, package_info_plus, share_plus` (upstream plugins)

JDK: Gradle 9 and AGP 9 both require JDK 17 to run — CI's Temurin 17 (`ci.yml`) and the local OpenJDK 17.0.20 suffice. **No workflow changes.**

## Global Constraints

- Gradle wrapper: `gradle-9.1.0-all.zip` (keep `-all`). Edit the properties line only — do NOT run `./gradlew wrapper`.
- AGP `com.android.application` = `9.0.1`; KGP `org.jetbrains.kotlin.android` = `2.3.20` (exact, no dynamic versions).
- `app/pubspec.yaml`: `device_info_plus: ^12.4.0`; no other dependency constraint changes. (`app/pubspec.lock` is gitignored — it is never staged.)
- `app/android/gradle.properties` is NOT edited: `android.newDsl=false`, `android.builtInKotlin=false`, and `org.gradle.jvmargs=-Xmx1g …` stay exactly as-is (the build succeeded at 1g during planning; never lower it).
- `app/android/app/build.gradle.kts` is NOT edited (keeps `id("kotlin-android")`).
- `.github/workflows/*` NOT edited (JDK 17 suffices; Gradle cache keys already hash `gradle-wrapper.properties` and `*.gradle*`).
- No Dart lib/test changes; `flutter analyze lib test` must stay at 0 issues.

## Review Focus

1. **CI on Flutter 3.41.7 with AGP 9.0.1** — cannot be reproduced locally (installing a second SDK was not permitted); pinned by the PR's `Build debug APK` CI job (Task 3 Step 8) with a STOP contingency.
2. **AAR-metadata / compileSdk failures in other plugins under AGP 9** — any plugin besides device_info_plus failing `check*AarMetadata` → pinned by Task 1 Step 4's build success; contingency is STOP, not opportunistic bumps.
3. **"will soon be dropped" warnings fully gone** — pinned by the grep-style check in Task 1 Step 4 (none of Gradle/AGP/Kotlin warning lines present).
4. **device_info_plus 9→12 API drift** — pinned by `flutter analyze lib test` (0 issues) and `test/unit/services/device_context_service_test.dart` in `flutter test` (Task 2).
5. **Accidental flag flip / heap change** — Task 1 Step 5 asserts the diff is exactly three files; `gradle.properties` must not appear.

---

### Task 1: Bump Gradle / AGP / KGP and device_info_plus

**Files:**
- Modify: `app/android/gradle/wrapper/gradle-wrapper.properties:5`
- Modify: `app/android/settings.gradle.kts:22-23`
- Modify: `app/pubspec.yaml:48`

**Interfaces:** none (config only). Produces a buildable Android project for Tasks 2–3.

- [ ] **Step 1: Baseline (record warnings)**

Run (CWD `$APP`): `flutter build apk --debug`
Expected: `✓ Built …app-debug.apk` preceded by three warnings beginning `Warning: Flutter support for your project's Gradle version (8.14.3) will soon be dropped`, `… Android Gradle Plugin version 8.11.1) will soon be dropped`, `… Kotlin version (2.2.20) will soon be dropped`. Record these lines for the PR body.

- [ ] **Step 2: Edit versions**

- `app/android/gradle/wrapper/gradle-wrapper.properties` line 5 becomes exactly:
  `distributionUrl=https\://services.gradle.org/distributions/gradle-9.1.0-all.zip`
- `app/android/settings.gradle.kts`:
  - `id("com.android.application") version "8.11.1" apply false` → `version "9.0.1" apply false`
  - `id("org.jetbrains.kotlin.android") version "2.2.20" apply false` → `version "2.3.20" apply false`
- `app/pubspec.yaml`: `  device_info_plus: ^9.1.2` → `  device_info_plus: ^12.4.0`

- [ ] **Step 3: Resolve dependencies**

Run: `flutter pub get --directory /home/maortz/code/allergy-detector/app`
Expected: exit 0, output contains `> device_info_plus 12.4.0 (was 9.1.2)` (version may be a newer 12.x patch; must be 12.x). If resolution fails → STOP (contingency below).

- [ ] **Step 4: Prove the build works and the deprecation warnings are gone**

Run (CWD `$APP`): `flutter build apk --debug`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`. Output must contain NONE of: `will soon be dropped`, `lower than Flutter's minimum supported version`, `checkDebugAarMetadata`. The two KGP-usage `WARNING:` blocks listed in "Expected residual warnings" are expected and acceptable. Save the last ~5 lines plus the residual warnings for the PR body.

Contingencies (do not improvise beyond these):
- Flutter names a higher floor than the table → bump to exactly that version, rerun, note it in the PR body.
- Any other plugin fails (AAR metadata, compile error against AGP 9 / KGP 2.3.20), dependency resolution fails, or Gradle OOMs (`Java heap space`, daemon disappeared) → STOP: revert with `git -C /home/maortz/code/allergy-detector checkout -- app/android/gradle/wrapper/gradle-wrapper.properties app/android/settings.gradle.kts app/pubspec.yaml`, comment the error on #412, release the claim (Task 3 Step 10 command), return `STOPPED <error summary>`.

- [ ] **Step 5: Confirm the diff is exactly three files**

Run: `git -C /home/maortz/code/allergy-detector status --short`
Expected: ` M app/android/gradle/wrapper/gradle-wrapper.properties`, ` M app/android/settings.gradle.kts`, ` M app/pubspec.yaml`, plus `?? docs/superpowers/plans/2026-10-26-issue-412-agp9-gradle9.md`. Nothing else (no `gradle.properties`, `build/`, `.gradle/`, `local.properties`, `pubspec.lock`, `gradlew*`).

### Task 2: Full Flutter verification (one command per call, CWD `$APP`)

- [ ] **Step 1:** `flutter pub get` → exit 0.
- [ ] **Step 2:** `flutter analyze lib test` → `No issues found!`
- [ ] **Step 3:** `flutter test` → `All tests passed!` (do not add `pumpAndSettle` anywhere; no test edits expected). If `device_context_service_test.dart` fails because of a device_info_plus 12 API change, STOP per Task 1 contingency rather than editing app code — that would be scope creep needing review. Any other failure: compare against `origin/master`; if pre-existing, note it in the PR body rather than fixing it.

### Task 3: A6–A9 — Spec index, drift check, commit, PR, issue hand-off

- [ ] **Step 1 (A6):** No change — Android build-toolchain change only; no screens affected, so `docs/superpowers/specs/2026-05-19-stitch-screens/index.md` is NOT modified. State this in the PR body.
- [ ] **Step 2 (A7 drift):** `git -C /home/maortz/code/allergy-detector fetch origin`
- [ ] **Step 3 (A7 drift):** `git -C /home/maortz/code/allergy-detector log origin/master..HEAD --oneline`
  Expected: empty. If any commit appears that you did not author → STOP (release claim, return `STOPPED foreign commits on branch`).
- [ ] **Step 4 (A8 stage):** `git -C /home/maortz/code/allergy-detector add app/android/gradle/wrapper/gradle-wrapper.properties app/android/settings.gradle.kts app/pubspec.yaml docs/superpowers/plans/2026-10-26-issue-412-agp9-gradle9.md`
- [ ] **Step 5 (A8 commit):** one `git -C /home/maortz/code/allergy-detector commit -F <tmpfile>` (write the message file under `/tmp`, never in the repo) with message:

```
chore(android): bump Gradle 9.1.0, AGP 9.0.1, KGP 2.3.20 (#412)

Flutter 3.47.7 warns that support for Gradle < 9.1.0, AGP < 9.0.1 and
KGP < 2.3.20 will soon be dropped. Bump all three to exactly those
floors (newest pair inside CI Flutter 3.41.7's validated AGP/Gradle
range). AGP 9 rejects device_info_plus 9.x (hard-coded compileSdk 33),
so bump it to ^12.4.0.

android.newDsl / android.builtInKotlin stay false, matching Flutter's
own AGP 9.1 template: flipping them is blocked upstream (Flutter Gradle
Plugin still on legacy AGP APIs; device_info_plus, package_info_plus
and share_plus still apply KGP).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

- [ ] **Step 6 (A8 re-check):** rerun `git -C /home/maortz/code/allergy-detector log origin/master..HEAD --oneline` → exactly one line, your commit.
- [ ] **Step 7 (A8 push + PR):** `git -C /home/maortz/code/allergy-detector push -u origin agent/issue-412-agp9-gradle9`, then (separate call) `gh pr create --repo Maortz/allergy-detector --base master --head agent/issue-412-agp9-gradle9 --title "chore(android): bump Gradle 9.1.0 / AGP 9.0.1 / KGP 2.3.20 (#412)" --body-file <tmpfile under /tmp>` where the body contains, in order:
  - `Closes #412`
  - Summary: the version table; the device_info_plus `^9.1.2 → ^12.4.0` bump and why (AAR-metadata failure; why not 13.x); the scope note (flags stay false — Flutter template does the same; newDsl/builtInKotlin blocked upstream; `kotlin-android` kept for CI Flutter 3.41.7).
  - Verification (verbatim from this session): baseline warning lines (Task 1 Step 1); build success line and explicit statement "no `will soon be dropped` warnings"; residual KGP-usage warnings quoted as known follow-ups; `flutter analyze lib test` → No issues found!; `flutter test` → All tests passed!
  - `A6: no screens affected — stitch-screens index.md unchanged.`
  - `No workflow changes: Gradle 9 / AGP 9 run on CI's JDK 17. gradle.properties untouched.`
  - Follow-ups (not done here): flip `android.newDsl` once Flutter's FGP P9 lands; flip `android.builtInKotlin` and drop `kotlin-android` once CI Flutter ≥ 3.47 and the three plus-plugins migrate to built-in Kotlin.
  - Final line exactly: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
- [ ] **Step 8 (A9 CI):** `gh pr checks <PR#> --repo Maortz/allergy-detector --watch` — `Build debug APK` (Flutter 3.41.7) must be green. If it fails: read `gh run view <run-id> --repo Maortz/allergy-detector --log-failed`. If the failure is 3.41.7 not supporting AGP 9.0.1 / Gradle 9.1.0 (or anything outside Task 1's contingencies), do NOT bump the CI Flutter version in this PR — comment the log excerpt on the PR and on #412, release the claim, return `STOPPED CI Flutter 3.41.7 incompatible with AGP 9: <summary>`.
- [ ] **Step 9 (A9 comment):** `gh issue comment 412 --repo Maortz/allergy-detector --body "Implementation PR: <PR URL> — Gradle 9.1.0 / AGP 9.0.1 / KGP 2.3.20 + device_info_plus ^12.4.0; debug APK builds on Flutter 3.47.7 with no 'will soon be dropped' warnings. newDsl/builtInKotlin intentionally stay false (blocked upstream; see PR)."`
- [ ] **Step 10 (A9 release):** `gh issue edit 412 --repo Maortz/allergy-detector --remove-label agent-in-progress`
- [ ] **Step 11 (A9 return):** `git -C /home/maortz/code/allergy-detector checkout master` then (separate call) `git -C /home/maortz/code/allergy-detector status --short` → clean.

## Staff-level standards

- Minimal, reviewable diff: three files + this plan; no opportunistic dependency bumps, template-comment cleanup, or workflow edits.
- Evidence before claims: every "green" in the PR body is backed by a command run in this session, quoted verbatim.
- Versions pinned exact and justified against the Flutter SDK's checker source and CI Flutter's compat table.
- Never bare `git stash`; never force-push.
