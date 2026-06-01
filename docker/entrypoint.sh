#!/usr/bin/env bash
# Merge the baked seed into the (volume-mounted) settings.json so the rtk hook +
# plugins are configured without clobbering the persisted login.
set -e

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SEED=/opt/claude/settings.seed.json
DEST="$CFG_DIR/settings.json"

mkdir -p "$CFG_DIR"

if [ -f "$DEST" ]; then
  # deep-merge: seed values win for the keys it defines, keep everything else
  merged="$(jq -s '.[0] * .[1]' "$DEST" "$SEED")"
  printf '%s\n' "$merged" > "$DEST"
else
  cp "$SEED" "$DEST"
fi

exec "$@"
