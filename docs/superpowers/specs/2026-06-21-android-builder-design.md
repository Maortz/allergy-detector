# android-builder Design

**Date:** 2026-06-21  
**Repo:** `Maortz/android-builder`  
**Reference:** mirrors `MobAI-App/ios-builder` structure and UX

## Overview

A Go CLI binary that triggers a remote Android APK build on GitHub Actions, downloads the artifact, installs it on a connected Android device via adb, and starts a Flutter hot-reload dev session. Equivalent to ios-builder but targeting Android — simpler because no MobAI service or code signing is required.

## Repo Structure

```
cmd/builder/
  main.go          # entry point
  root.go          # cobra root, init cmd, android cmd wiring
  android.go       # `builder android build` command
  flutter.go       # `builder dev flutter` command
internal/
  auth/auth.go     # GitHub token storage (same keyring pattern as ios-builder)
  build/
    coordinator.go # trigger GHA → poll artifact → download APK
    progress.go    # phase/spinner progress UI
  config/
    types.go       # Config struct with Android section
    config.go      # load/save builder.json
  github/          # GitHub API client (trigger workflow, poll, download artifact)
  dev/
    session.go     # adb install → app launch → flutter attach subprocess
    flutter.go     # FlutterHandler: hot-reload loop
    watcher.go     # file watcher → writes 'r\n' to flutter attach stdin
  workflow/
    templates/
      android-build.yml  # embedded GHA workflow template
install.sh
go.mod
```

## Configuration (`builder.json`)

```json
{
  "project": "allergy-detector",
  "platform": "android",
  "github": { "owner": "Maortz", "repo": "allergy-detector" },
  "android": {
    "buildType": "debug",
    "flavor": "",
    "packageName": ""
  },
  "flutter": {
    "version": "3.x.x",
    "watch": {
      "dirs": ["lib"],
      "patterns": [".dart"],
      "ignore": [".g.dart", ".freezed.dart"],
      "debounce": 100
    }
  }
}
```

- `android.buildType`: `"debug"` (default) or `"release"`
- `android.flavor`: optional product flavor (e.g. `"free"`)
- `android.packageName`: optional override; auto-detected from APK via `aapt` if empty

## GHA Workflow (`android-build.yml`)

Runs on `ubuntu-latest` — no macOS runner, ~10× cheaper and faster than ios-builder.

**`workflow_dispatch` inputs:**

| Input | Default | Description |
|-------|---------|-------------|
| `build_id` | required | UUID prefix (e.g. `"a3f2c1b0"`) |
| `build_type` | `debug` | `debug` or `release` |
| `flutter_version` | `` | Pinned Flutter version; empty = latest stable |

**Steps:**

1. `actions/checkout@v4`
2. `subosito/flutter-action@v2` (channel: stable, cache: true)
3. Restore Gradle cache (`~/.gradle/caches`, keyed on `app/android/build.gradle*` hash)
4. `flutter pub get` (working-dir: `app/`)
5. `flutter build apk --debug` (or `--release` per `build_type`)
6. Rename output: `app-debug.apk` → `<build_id>.apk`
7. `actions/upload-artifact@v4` — name: `apk`, path: renamed APK, retention: 7 days
8. Save Gradle cache
9. Build summary step (build_id, status, APK size, Gradle cache hit)

## CLI Commands

### `builder init`

- Detects Flutter project (`pubspec.yaml`)
- Detects GitHub owner/repo from `git remote get-url origin`
- Prompts: project name, Flutter version (auto-detected from local `flutter --version`)
- Writes `.github/workflows/android-build.yml` (embedded template)
- Writes `builder.json`
- Offers to commit + push, then optionally run build

### `builder android build`

```
builder android build [--output dist] [--timeout 30m] [--release]
```

Flow:
1. Load and validate `builder.json`
2. Generate `build_id` (uuid[:8])
3. `TriggerWorkflow("android-build.yml", {build_id, build_type, flutter_version})`
4. `PollForWorkflowStart` (2-minute timeout)
5. `PollForArtifact("apk")` — downloads as soon as artifact is uploaded, before job end
6. Extract `.apk` from artifact zip → `dist/<project>-<build_id>.apk`
7. Print APK path + GHA workflow URL

### `builder dev flutter`

```
builder dev flutter [--apk path] [--device id] [--package com.x.y]
                    [--no-attach] [--no-watch] [--skip-install]
```

Flow:
1. Find APK in `dist/` (newest match), or use `--apk`
2. `adb devices` → if multiple, prompt user to select
3. `adb install -r <apk>`
4. Detect package name:
   - `builder.json android.packageName` if set
   - else: `aapt dump badging <apk> | grep "package: name"`
   - else: require `--package` flag
5. Launch app: `adb shell monkey -p <package> -c android.intent.category.LAUNCHER 1`
6. `flutter attach --device-id <adb-device-id>` (subprocess)
7. File watcher (`lib/**/*.dart`, debounced) → write `r\n` to flutter attach stdin on change
8. Ctrl-C → kill flutter attach, cleanup

### `builder auth github`

Stores GitHub token (keyring or `~/.config/android-builder/token`). Identical to ios-builder.

## Error Handling

| Error | Message |
|-------|---------|
| `adb` not on PATH | "adb not found. Install Android SDK Platform-Tools: https://developer.android.com/tools/releases/platform-tools" |
| No adb devices | "No Android devices found. Enable USB debugging on your device and reconnect." |
| Package detection fails | "Could not detect package name. Use --package com.your.app or set android.packageName in builder.json" |
| `aapt` not on PATH | Fall back to `--package` flag requirement; warn user |
| GHA workflow not found | "android-build.yml not found. Run: builder init" |
| Build timeout | Prints workflow URL for manual inspection |

## Key Differences from ios-builder

| | ios-builder | android-builder |
|--|-------------|-----------------|
| GHA runner | `macos-latest` | `ubuntu-latest` |
| Artifact | `.ipa` | `.apk` |
| Install method | MobAI service | `adb install` |
| Code signing | Optional (dev certs) | None (debug auto-signed) |
| Device launch | MobAI API | `adb shell monkey` |
| Cache | DerivedData + Pods | Gradle |
| Local dep | MobAI running | adb on PATH |
