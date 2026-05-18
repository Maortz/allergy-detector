# Cross-Platform Build Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore green builds and a clean test suite on web, Android, and iOS so the project ships cleanly across all three intended platforms.

**Architecture:** Two unrelated breakages were introduced by the recent Android toolchain upgrade (AGP 7.3.0→8.2.0, Gradle 7.5→8.5, Kotlin 1.7.10→1.9.0) and the navigation refactor (commits `233a34a`, `0ab5e79`). Android: Gradle daemon OOMs at `JetifyTransform` because the heap is set to a pre-AGP-8 value of 1536M. Tests: three Hebrew-text assertions in `home_screen_test.dart` and `search_scan_screen_test.dart` reference UI elements (hardcoded sample products, a section header that only renders with data) that the refactor removed. Web already builds; iOS cannot be verified from Windows but the Dart layer analyzes clean.

**Tech Stack:** Flutter 3.41.7, Dart 3.11.5, AGP 8.2.0, Gradle 8.5, Kotlin 1.9.0, JDK 17, mockito 5.4.5.

---

## File Structure

Files this plan creates or modifies:

| File | Responsibility | Action |
|---|---|---|
| `app/android/gradle.properties` | Gradle daemon JVM args + AndroidX flags | Modify (raise `-Xmx` heap) |
| `app/test/widgets/screens/home_screen_test.dart` | Widget tests for `HomeScreen` | Modify (one assertion) |
| `app/test/widgets/screens/search_scan_screen_test.dart` | Widget tests for `SearchScanScreen` | Modify (two assertions) |
| `app/android/hs_err_pid91384.log` | Stale JVM crash dump from a failed build | Delete |

No production Dart code changes — the UI is correct as-is; only stale test expectations need to be aligned with the post-refactor reality.

---

## Task 1: Raise Android Gradle daemon heap to fix JetifyTransform OOM

**Context:** The Android build fails at `:app:checkDebugDuplicateClasses` with `Execution failed for JetifyTransform: ... Java heap space`. The Gradle JVM is launched with `-Xmx1536M` (see `app/android/gradle.properties:1`). AGP 8.x with Jetifier needs more headroom — modern Flutter templates default to `-Xmx4G`. A stale `hs_err_pid91384.log` from a previous OOM is still on disk and should be cleaned up.

**Files:**
- Modify: `app/android/gradle.properties:1`
- Delete: `app/android/hs_err_pid91384.log`

- [ ] **Step 1: Read current `app/android/gradle.properties`**

Run: `Get-Content app/android/gradle.properties`
Expected output:
```
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
```

- [ ] **Step 2: Update heap to `-Xmx4G`**

Edit `app/android/gradle.properties` so it reads:
```
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
```

Why these flags: `-Xmx4G` is the Flutter template default for AGP 8.x. `-XX:MaxMetaspaceSize=512m` prevents Kotlin compiler metaspace exhaustion on incremental builds. `-XX:+HeapDumpOnOutOfMemoryError` makes future OOMs diagnosable.

- [ ] **Step 3: Delete the stale JVM crash log**

Run: `Remove-Item app/android/hs_err_pid91384.log`
Expected: no output, exit 0.

- [ ] **Step 4: Stop any running Gradle daemons so the new JVM args take effect**

Run from `app/android/`: `.\gradlew.bat --stop`
Expected: "Stopping Daemon(s)" or "No Gradle daemons are running." (Windows uses the `.bat` wrapper, not the POSIX shell `gradlew`.)

- [ ] **Step 5: Verify Android build now succeeds**

Run: `cd app; flutter build apk --debug; cd ..`
Expected: build completes with `✓ Built build\app\outputs\flutter-apk\app-debug.apk`. Watch for:
- The previous failure (`JetifyTransform ... Java heap space`) MUST NOT appear.
- Kotlin and AGP deprecation warnings are acceptable — they are not blockers.
- Build time will be ~3-5 minutes the first time.

If the build still OOMs at a different transform, raise to `-Xmx6G` and re-run. If it OOMs in a different phase (e.g. dex), open the heap dump file (`java_pid*.hprof`) and inspect rather than guessing.

- [ ] **Step 6: Commit**

Run from repo root:
```powershell
git add app/android/gradle.properties
git rm app/android/hs_err_pid91384.log
git commit -m "fix(android): raise Gradle daemon heap to 4G for AGP 8 / Jetifier

The Gradle daemon was OOMing in JetifyTransform with the pre-AGP-8 default
of -Xmx1536M. Bump to -Xmx4G (the Flutter template default for AGP 8.x),
cap metaspace at 512M, and enable HeapDumpOnOutOfMemoryError for future
diagnosis. Removes the stale hs_err_pid91384.log from the previous crash."
```

---

## Task 2: Fix stale "recent activity" assertion in `home_screen_test.dart`

**Context:** The test `displays recent activity section with Hebrew text` asserts `find.text('פעילות אחרונה')` exists. In the post-refactor `HomeScreen._buildRecentActivitySection` (see `app/lib/screens/home_screen.dart:237-260`), that header only renders when `_recentActivities.isNotEmpty`. In the widget test there is no SharedPreferences mock data, so `ScanHistoryService.getRecentScans` returns `[]` and the screen renders the empty-state widget with text `'אין פעילות אחרונה מהסקר'` instead. The test should assert the empty-state, since that is the path under test.

**Files:**
- Modify: `app/test/widgets/screens/home_screen_test.dart:73-77`

- [ ] **Step 1: Run the failing test to confirm current behavior**

Run from `app/`: `flutter test test/widgets/screens/home_screen_test.dart --plain-name "displays recent activity section with Hebrew text"`
Expected: 1 test FAILS with:
```
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "פעילות אחרונה": []>
```

- [ ] **Step 2: Update the assertion to match the empty-state**

In `app/test/widgets/screens/home_screen_test.dart`, replace lines 73-77:

```dart
    testWidgets('displays recent activity section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('פעילות אחרונה'), findsOneWidget);
    });
```

With:

```dart
    testWidgets('displays recent activity empty-state with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      // ScanHistoryService is unmocked → recent scans = []; the section renders
      // its empty-state message. The populated-state header ("פעילות אחרונה") is
      // covered by integration tests where SharedPreferences is seeded.
      await tester.pumpAndSettle();

      expect(find.text('אין פעילות אחרונה מהסקר'), findsOneWidget);
    });
```

Why `pumpAndSettle`: `_loadRecentScans` is async; without settling, the build may still be in its initial frame where `_recentActivities` has not yet been assigned.

- [ ] **Step 3: Run the test and verify it passes**

Run from `app/`: `flutter test test/widgets/screens/home_screen_test.dart --plain-name "displays recent activity empty-state with Hebrew text"`
Expected: `+1: All tests passed!`

- [ ] **Step 4: Run the full file to make sure nothing else regressed**

Run from `app/`: `flutter test test/widgets/screens/home_screen_test.dart`
Expected: all tests pass.

- [ ] **Step 5: Commit**

Run from repo root:
```powershell
git add app/test/widgets/screens/home_screen_test.dart
git commit -m "test(home): assert recent-activity empty-state, not header

The 'פעילות אחרונה' header only renders when scan history is non-empty.
In a unit test ScanHistoryService returns [], so the empty-state widget
is what's actually under test. Add pumpAndSettle so the async load
completes before the assertion."
```

---

## Task 3: Fix stale "recent scans" sample-data assertion in `search_scan_screen_test.dart`

**Context:** The test `displays recent scans section with Hebrew text` asserts three texts: `'נסרק לארכונה'` (the section header — still in the code at `app/lib/screens/search_scan_screen.dart:359`), plus `'חלב שולו 5%'` and `'שולו'` (hardcoded sample products from before the refactor). The current `_buildRecentScansSection` reads from `ScanHistoryService.getRecentScans` which returns `[]` in widget tests. The two sample-product assertions cannot pass without seeding scan history — drop them and keep the header assertion.

**Files:**
- Modify: `app/test/widgets/screens/search_scan_screen_test.dart:48-54`

- [ ] **Step 1: Run the failing test to confirm**

Run from `app/`: `flutter test test/widgets/screens/search_scan_screen_test.dart --plain-name "displays recent scans section with Hebrew text"`
Expected: FAIL with:
```
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "חלב שולו 5%": []>
```

- [ ] **Step 2: Replace the assertion block**

In `app/test/widgets/screens/search_scan_screen_test.dart`, replace lines 48-54:

```dart
    testWidgets('displays recent scans section with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('נסרק לארכונה'), findsOneWidget);
      expect(find.text('חלב שולו 5%'), findsOneWidget);
      expect(find.text('שולו'), findsOneWidget);
    });
```

With:

```dart
    testWidgets('displays recent scans section header with Hebrew text', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      // ScanHistoryService returns [] in widget tests, so only the section
      // header is asserted; populated-state content is covered by integration
      // tests that seed SharedPreferences.
      await tester.pumpAndSettle();

      expect(find.text('נסרק לארכונה'), findsOneWidget);
    });
```

- [ ] **Step 3: Run the test and verify it passes**

Run from `app/`: `flutter test test/widgets/screens/search_scan_screen_test.dart --plain-name "displays recent scans section header with Hebrew text"`
Expected: `+1: All tests passed!`

- [ ] **Step 4: Commit**

Run from repo root:
```powershell
git add app/test/widgets/screens/search_scan_screen_test.dart
git commit -m "test(search-scan): drop hardcoded sample-product assertions

The recent-scans section now reads from ScanHistoryService, which returns
[] in widget tests. The 'חלב שולו 5%' / 'שולו' assertions tested fixture
data that no longer exists post-refactor. Keep the header assertion."
```

---

## Task 4: Fix `search input accepts text input` assertion

**Context:** The test enters `'חלב'` into the search field and then asserts `find.text('חלב'), findsOneWidget`. But typing into `SearchInput` calls `_onSearch`, which sets `_showActiveSearch = true` and the `build()` method returns `ActiveSearchScreen` instead of the search screen (see `app/lib/screens/search_scan_screen.dart:131-138`). After the transition, the original `TextField` is gone and `ActiveSearchScreen` renders `'תוצאות חיפוש: חלב'` — `find.text('חלב')` is an *exact* match so it finds 0 widgets. The test should verify the controller captured the input AND the active-search transition happened, not look for a stray exact-match text.

**Files:**
- Modify: `app/test/widgets/screens/search_scan_screen_test.dart:62-72`

- [ ] **Step 1: Run the failing test to confirm**

Run from `app/`: `flutter test test/widgets/screens/search_scan_screen_test.dart --plain-name "search input accepts text input"`
Expected: FAIL — exact failure may say `Found 0 widgets with text "חלב"`.

- [ ] **Step 2: Rewrite the test**

In `app/test/widgets/screens/search_scan_screen_test.dart`, replace lines 62-72:

```dart
    testWidgets('search input accepts text input', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'חלב');
      await tester.pump();

      expect(find.text('חלב'), findsOneWidget);
    });
```

With:

```dart
    testWidgets('search input accepts text and opens active search', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'חלב');
      await tester.pump();

      // _onSearch flips _showActiveSearch=true and the build() swaps in
      // ActiveSearchScreen, which echoes the query in its header.
      expect(find.text('תוצאות חיפוש: חלב'), findsOneWidget);
      expect(find.text('0 מוצרים נמצאו'), findsOneWidget);
    });
```

Why these two assertions: they verify both that the text was captured AND that the active-search transition fired. The `'0 מוצרים נמצאו'` line is deterministic because no `productService` is passed, so `_searchResults` stays `[]` (see `app/lib/screens/search_scan_screen.dart:107-109`).

- [ ] **Step 3: Run the test and verify it passes**

Run from `app/`: `flutter test test/widgets/screens/search_scan_screen_test.dart --plain-name "search input accepts text and opens active search"`
Expected: `+1: All tests passed!`

- [ ] **Step 4: Run the full file**

Run from `app/`: `flutter test test/widgets/screens/search_scan_screen_test.dart`
Expected: all tests pass.

- [ ] **Step 5: Commit**

Run from repo root:
```powershell
git add app/test/widgets/screens/search_scan_screen_test.dart
git commit -m "test(search-scan): assert active-search transition, not stray text

Entering text fires _onSearch and SearchScanScreen.build returns
ActiveSearchScreen. The old 'find.text(חלב)' was a brittle exact-match
that found 0 widgets because the only echo of the query is the
'תוצאות חיפוש: חלב' header. Assert that header + the empty-results
count instead."
```

---

## Task 5: Run the full suite + web + Android builds to confirm green

**Context:** Verification before declaring "all three platforms build." Web already built once during status check; we re-verify after the test changes (which don't touch web code, but cheap insurance). Android needs to build with the new heap. iOS verification is documented in Task 6.

- [ ] **Step 1: Run the full Flutter test suite**

Run from `app/`: `flutter test`
Expected: `All tests passed!` with **184 +** (previously 181 passed + 3 fixed = 184). If the count is anything other than 184 passing 0 failing, stop and investigate before moving on — a fix may have broken a sibling test.

- [ ] **Step 2: Run `flutter analyze` and confirm no new errors**

Run from `app/`: `flutter analyze`
Expected: exit code 1 with the same 32 info/warning issues as before (no new ones from the test edits). Zero errors.

- [ ] **Step 3: Build for web**

Run from `app/`: `flutter build web --no-tree-shake-icons`
Expected: `✓ Built build\web`.

- [ ] **Step 4: Build for Android**

Run from `app/`: `flutter build apk --debug`
Expected: `✓ Built build\app\outputs\flutter-apk\app-debug.apk`. If this OOMs again, return to Task 1 Step 5.

- [ ] **Step 5: Commit a verification stamp (optional)**

Skip if no files changed in Step 1-4. If the build produced any expected lockfile/regenerated content, stage and commit it; otherwise this step is a no-op.

---

## Task 6: Document iOS verification handoff

**Context:** iOS cannot be built from Windows (Xcode is required). The Dart/Flutter layer already analyzes clean and the `ios/` project structure is intact. Document the exact commands a teammate must run on a Mac so iOS verification isn't a guessing game later.

**Files:**
- Modify: `app/README.md` (append a short section)

- [ ] **Step 1: Read current README to find an appropriate insertion point**

Run: `Get-Content app/README.md | Select-Object -First 30`

- [ ] **Step 2: Append an iOS verification section**

Add to the end of `app/README.md`:

```markdown

## iOS verification (Mac required)

The CI on Windows cannot build iOS. On a Mac with Xcode installed:

```sh
cd app
flutter pub get
cd ios && pod install && cd ..
flutter build ios --debug --no-codesign
```

Expected: `✓ Built build/ios/iphoneos/Runner.app`. If `pod install` reports a deployment-target mismatch, open `ios/Podfile`, set `platform :ios, '13.0'`, and re-run.
```

- [ ] **Step 3: Commit**

Run from repo root:
```powershell
git add app/README.md
git commit -m "docs: add iOS verification commands for Mac teammates"
```

---

## Done

After Task 6, the project has:
- **Web:** verified green (`flutter build web`).
- **Android:** verified green (`flutter build apk --debug`) with a stable heap config.
- **iOS:** verifiable green on a Mac via a 4-line documented procedure.
- **Tests:** 184/184 passing.
- **Analyzer:** 0 errors, same 32 pre-existing info/warning lints (out of scope — separate cleanup).

Out of scope for this plan (track as follow-ups):
- Upgrade Kotlin 1.9.0 → ≥ 2.1.0 (Flutter warned this support will drop).
- Consider `android.enableJetifier=false` (all deps are AndroidX; would speed up build) — verify with a separate build, separate commit.
- Cleanup of the 32 lint warnings (unused imports in tests, `withOpacity` → `withValues`, `prefer_final_fields`).
