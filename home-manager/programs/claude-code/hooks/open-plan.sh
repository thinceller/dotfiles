#!/bin/bash
set -euo pipefail

cat > /dev/null

MO="/opt/homebrew/bin/mo"
[[ -x "$MO" ]] || exit 0

PLANS_DIR="${HOME}/.claude/plans"
[[ -d "$PLANS_DIR" ]] || exit 0

PLAN_FILE=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
[[ -n "$PLAN_FILE" ]] || exit 0

"$MO" --open "$PLAN_FILE" &>/dev/null &

exit 0
