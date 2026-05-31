#!/usr/bin/env bash
# Merge the baked seed into the (volume-mounted) ~/.claude/settings.json so the
# rtk hook + plugins are configured without clobbering the persisted login.
set -e

SEED=/opt/claude/settings.seed.json
DEST="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"

if [ -f "$DEST" ]; then
  # deep-merge: seed values win for the keys it defines, keep everything else
  merged="$(jq -s '.[0] * .[1]' "$DEST" "$SEED")"
  printf '%s\n' "$merged" > "$DEST"
else
  cp "$SEED" "$DEST"
fi

exec "$@"
