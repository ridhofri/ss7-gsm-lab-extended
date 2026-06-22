#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS="$ROOT/logs"
CFG="$ROOT/config"

mkdir -p "$LOGS"

SESSION="ss7lab"

tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION" || true
tmux new-session -d -s "$SESSION" -n stp "osmo-stp -c $CFG/osmo-stp.cfg 2>&1 | tee $LOGS/stp.log"
sleep 0.5
tmux new-window -t "$SESSION" -n hlr "osmo-hlr -c $CFG/osmo-hlr.cfg 2>&1 | tee $LOGS/hlr.log"
sleep 0.5
tmux new-window -t "$SESSION" -n mgw "osmo-mgw -c $CFG/osmo-mgw.cfg 2>&1 | tee $LOGS/mgw.log"
sleep 0.5
tmux new-window -t "$SESSION" -n msc "osmo-msc -c $CFG/osmo-msc.cfg 2>&1 | tee $LOGS/msc.log"
sleep 0.5

echo "Started tmux session: $SESSION"
echo "Attach with: tmux attach -t $SESSION"
