#!/usr/bin/env bash
# Watchdog for the endless agent-pipeline loop (see .claude/skills/agent-pipeline/SKILL.md).
# The pipeline runs forever inside a tmux window; cron only recreates the
# window if it died. flock guards against concurrent watchdog firings.
set -euo pipefail

LOG=/var/log/agents/agent-pipeline.log
SESSION=claude
WINDOW=pipeline

exec 9>/tmp/agent-pipeline-watchdog.lock
flock -n 9 || exit 0

tmux has-session -t "$SESSION" 2>/dev/null || tmux new-session -d -s "$SESSION"

if ! tmux list-windows -t "$SESSION" -F '#{window_name}' | grep -qx "$WINDOW"; then
  echo "[watchdog $(date -u +%FT%TZ)] pipeline window missing — starting" >> "$LOG"
  tmux new-window -d -t "$SESSION" -n "$WINDOW" \
    "cd /workspace && git checkout master && git pull origin master && claude --dangerously-skip-permissions -p '/agent-pipeline' 2>&1 | tee -a $LOG"
fi
