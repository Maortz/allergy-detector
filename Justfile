# Dev workflow for allergy-detector: Flutter build/run against a local
# Supabase stack, on the Android emulator or a real device over adb.
#
# Requires `just` itself (apt: `sudo apt install just`), Docker (user in the
# `docker` group — see note at the bottom), the Supabase CLI, and the Android
# SDK platform-tools (adb) + an `flutter emulators` entry named "pixel".
#
# Run `just` or `just --list` to see all recipes.

app_dir := "app"
supabase_dir := "supabase"
api_port := "54321"
emulator_name := "pixel"

default:
    @just --list

# --- Flutter ---

# Install Flutter package dependencies.
pub-get:
    cd {{app_dir}} && flutter pub get

# Static analysis (type checking included).
analyze:
    cd {{app_dir}} && flutter analyze

# Full test suite.
test:
    cd {{app_dir}} && flutter test

# --android-skip-build-dependency-validation (used here and in run-emulator /
# run-device) works around this host's Gradle (8.11.1) being older than
# Flutter's current minimum (8.14.0) — see issue #404, which tracks bumping
# the pinned Gradle version properly; once that lands, drop the flag.
# Full build verification: pub get + analyze + test + debug APK.
build: pub-get analyze test
    cd {{app_dir}} && flutter build apk --debug --android-skip-build-dependency-validation

# --- Android emulator / device ---

# Launch the "pixel" AVD if no emulator is already running, and wait for boot.
emulator-up:
    #!/usr/bin/env bash
    set -euo pipefail
    if adb devices | grep -q '^emulator-'; then
        echo "Emulator already running."
        exit 0
    fi
    flutter emulators --launch {{emulator_name}} &
    launch_pid=$!
    if ! wait "$launch_pid"; then
        echo "Failed to launch emulator '{{emulator_name}}' (check the AVD name with 'flutter emulators')." >&2
        exit 1
    fi
    echo "Waiting for emulator to boot..."
    if ! timeout 120 adb wait-for-device; then
        echo "Timed out waiting for the emulator device to appear." >&2
        exit 1
    fi
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
        sleep 2
    done
    echo "Emulator booted."

# Doesn't apply to the emulator (use 10.0.2.2 instead, see run-emulator).
# Re-run after every reconnect — adb reverse doesn't persist across them.
# Forward Supabase's API port to a USB- or wifi-adb-connected real device.
adb-reverse device="":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{device}}"
    if [ -z "$target" ]; then
        target=$(just _target-device)
    fi
    adb -s "$target" reverse tcp:{{api_port}} tcp:{{api_port}}
    echo "Reversed tcp:{{api_port}} on $target"

# --- shared helpers (not listed in `just --list`) ---

# First authorized, non-emulator adb device, or exit 1 with a message.
_target-device:
    #!/usr/bin/env bash
    set -euo pipefail
    target=$(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /^emulator-/ {print $1; exit}')
    if [ -z "$target" ]; then
        echo "No real (non-emulator) adb device found." >&2
        exit 1
    fi
    echo "$target"

# Local Supabase anon key, or exit 1 with a message.
_anon-key:
    #!/usr/bin/env bash
    set -euo pipefail
    anon_key=$(cd {{supabase_dir}} && supabase status -o env 2>/dev/null | grep '^ANON_KEY=' | cut -d'"' -f2)
    if [ -z "$anon_key" ]; then
        echo "Could not extract ANON_KEY from 'supabase status -o env'" >&2
        exit 1
    fi
    echo "$anon_key"

# --- Supabase local stack ---

# Start local Supabase (Postgres, PostgREST, Studio, ...) via Docker.
supabase-up:
    cd {{supabase_dir}} && supabase start

# Stop local Supabase containers.
supabase-down:
    cd {{supabase_dir}} && supabase stop

# Show local Supabase status (URLs, keys).
supabase-status:
    cd {{supabase_dir}} && supabase status

# --- Run the app against local Supabase ---

# 10.0.2.2 is the AVD's alias for the host machine's loopback — the emulator
# can't reach the host via 127.0.0.1/localhost.
# Run on the emulator against local Supabase.
run-emulator: supabase-up emulator-up
    #!/usr/bin/env bash
    set -euo pipefail
    target=$(adb devices | awk '/^emulator-/{print $1; exit}')
    anon_key=$(just _anon-key)
    cd {{app_dir}}
    flutter run --android-skip-build-dependency-validation \
        --dart-define=SUPABASE_URL=http://10.0.2.2:{{api_port}} \
        --dart-define=SUPABASE_KEY="$anon_key" \
        -d "$target"

# Already-connected/authorized USB or wifi-adb device; sets up adb reverse
# automatically. Pass device= to target a specific one if more than one
# is connected.
# Run on a real device against local Supabase.
run-device device="": supabase-up
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{device}}"
    if [ -z "$target" ]; then
        target=$(just _target-device)
    fi
    just adb-reverse "$target"
    anon_key=$(just _anon-key)
    cd {{app_dir}}
    flutter run --android-skip-build-dependency-validation \
        --dart-define=SUPABASE_URL=http://127.0.0.1:{{api_port}} \
        --dart-define=SUPABASE_KEY="$anon_key" \
        -d "$target"

# --- Diagnostics ---

# Sanity-check the local dev environment.
doctor:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== docker =="
    if docker ps >/dev/null 2>&1; then
        echo "OK: docker reachable"
    else
        echo "FAIL: docker not reachable. If you were just added to the"
        echo "      'docker' group, note that an already-running tmux SERVER"
        echo "      keeps the old group list for every pane/window it spawns,"
        echo "      even brand-new ones — 'tmux kill-server' and start a new"
        echo "      tmux, or work outside tmux, then retry."
    fi
    echo "== flutter =="
    flutter --version | head -1
    echo "== supabase CLI =="
    supabase --version
    echo "== adb devices =="
    adb devices
    echo "== gh auth =="
    gh auth status 2>&1 | head -3
