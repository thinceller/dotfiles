#!/bin/bash
# Mnemos: Stop / SessionEnd hook。hook JSON をパースして共用 worker
# (vault-session-log-worker, scripts/vault-session-log-worker.sh) に引き渡すだけの薄い入口。
# worker 側でデバウンス・サイズゲート・ロック・detach を行うため、ここは即座に返る。

set -u

# worker が起動する headless claude 自身の hook 再帰を防ぐ
[ -n "${VAULT_SESSION_LOG_CHILD:-}" ] && exit 0

JQ=$(command -v jq || echo /usr/bin/jq)
WORKER=$(command -v vault-session-log-worker || echo "/etc/profiles/per-user/$USER/bin/vault-session-log-worker")
[ -x "$WORKER" ] || exit 0

input=$(cat)
transcript=$(printf '%s' "$input" | "$JQ" -r '.transcript_path // empty' 2>/dev/null)
session_id=$(printf '%s' "$input" | "$JQ" -r '.session_id // empty' 2>/dev/null)
event=$(printf '%s' "$input" | "$JQ" -r '.hook_event_name // empty' 2>/dev/null)

[ -n "$session_id" ] && [ -n "$transcript" ] || exit 0

if [ "$event" = "SessionEnd" ]; then
  "$WORKER" Claude-Code "$session_id" "$transcript" --final
else
  "$WORKER" Claude-Code "$session_id" "$transcript"
fi
exit 0
