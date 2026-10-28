---
name: driving-android-device
description: Use when running, debugging, or testing this Flutter app on an Android emulator or physical device — reproducing a bug interactively, verifying a UI change actually works, or any adb-driven tap/screenshot workflow against the running app.
---

# Driving Android Device

## Overview

Interact with the app on an Android emulator or phone via `adb`: launch it, tap through screens, read logs. Core principle: **get tap coordinates from `uiautomator dump`, never from eyeballing a screenshot.**

## When to Use

- Reproducing a bug interactively to find its root cause
- Verifying a code change actually works in the running app, not just in tests
- Any time you need to tap or type into the app via `adb`

## The Core Mistake to Avoid

Screenshot images shown by the Read tool are scaled down (e.g. a 1080×2400 device screen displayed at 900×2000), with the ratio printed under the image. Eyeballing a tap location from the displayed image and converting it by hand is unreliable: it's easy to use the wrong axis, forget the multiplier, or mis-estimate a small element's center — producing a tap that lands on the wrong element entirely. Two or more consecutive mis-taps on the same screen is the signal to stop guessing and switch to measured bounds.

## Core Pattern: Measure, Don't Guess

```bash
adb -s <serial> shell uiautomator dump /sdcard/ui.xml
adb -s <serial> shell cat /sdcard/ui.xml > /tmp/ui.xml
grep -oE '(text|content-desc)="[^"]*"[^>]*bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+\]"' /tmp/ui.xml
```

Each `bounds="[x1,y1][x2,y2]"` is already in real device pixels — tap the center directly, no conversion needed:

```bash
adb -s <serial> shell input tap $(( (x1+x2)/2 )) $(( (y1+y2)/2 ))
```

Screenshots (`adb -s <serial> exec-out screencap -p > shot.png`, then Read `shot.png`) are for *visually confirming* what happened after an action — use them to verify, not to aim.

If the target element has no `text`/`content-desc` (a bare icon button, for example), grep nearby elements by class/bounds instead, or fall back to a screenshot estimate as a last resort — but still prefer the dump when it's available.

## Quick Reference

| Need | Command |
|---|---|
| List connected devices | `adb devices -l` |
| Target one device | `adb -s <serial> ...` (serial is `emulator-5554`, or `<ip>:<port>` for wireless debugging) |
| Launch on emulator | `just run-emulator` (from repo root; starts the AVD if needed, sets up local Supabase) |
| Launch on a device | `just run-device [serial]` (sets up `adb reverse` for Supabase automatically) |
| Screenshot | `adb -s <serial> exec-out screencap -p > shot.png`, then Read `shot.png` |
| App's current PID | `adb -s <serial> shell pidof com.example.app` |
| Flutter-only logs for that PID | `adb -s <serial> logcat -d --pid=<pid> 'flutter:V' '*:S'` |
| Dismiss keyboard | `adb -s <serial> shell input keyevent 111` |
| Type text | `adb -s <serial> shell input text "value"` |
| Backspace | `adb -s <serial> shell input keyevent 67` |
| Back button | `adb -s <serial> shell input keyevent 4` |
| Force-stop + relaunch | `adb -s <serial> shell am force-stop com.example.app && adb -s <serial> shell am start -n com.example.app/.MainActivity` |

## Launching and Watching the Build

`just run-emulator` / `just run-device` run `flutter run`, which streams build progress and then stays attached for hot reload. To watch the build without blocking:

- Use the Monitor tool with a filtered grep, e.g. `"Error|FAILED|Installing|Flutter run key|Built build"`, so progress events surface without flooding context.
- The monitored process dying (e.g. a monitor timeout killing the piped command) does **not** kill the app on the device — check `adb shell pidof <package>` before assuming a relaunch is needed. Only hot-reload/live-logs are lost; the app keeps running.

## Common Mistakes

- **Guessing coordinates from a displayed screenshot** instead of measuring with `uiautomator dump` — the single biggest cause of wasted taps.
- **Reusing stale bounds after a layout shift** (keyboard appearing/disappearing, scroll position changing, an error message pushing content down). Re-dump after any layout-changing action; don't reuse coordinates captured before it.
- **Forgetting `-s <serial>`** when multiple devices/emulators are connected — the command silently targets the wrong one, or errors with "more than one device".
- **Assuming a killed `flutter run` process means the app died** — it doesn't. Check the on-device PID before relaunching from scratch.
- **Wireless-debugging connections drop silently.** If `adb` commands start timing out or the device disappears from `adb devices -l`, reconnect (`adb connect <ip>:<port>` — the port can change each time; re-check Settings → Developer options → Wireless debugging) and re-run `just run-device` to redo the `adb reverse` tunnel for Supabase.
