#!/usr/bin/env bash
# Append a daily Claude token/cost digest to the persistent agent-log volume.
# ccusage parses the local ~/.claude session JSONL — no API key needed.
set -uo pipefail

LOG=/var/log/agents/cost-digest.log
{
  echo "=== cost digest $(date -u +%F) ==="
  npx --yes ccusage@latest daily --since "$(date -u -d '7 days ago' +%Y%m%d)" 2>/dev/null \
    || echo "ccusage failed (offline or no session data)"
  echo
} >> "$LOG"
