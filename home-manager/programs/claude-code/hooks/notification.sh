#!/bin/bash
set -euo pipefail

INPUT=$(cat)

SESSION_ID=$(jq -r '.session_id // "unknown"' <<< "$INPUT")
MESSAGE=$(jq -r '.message // "通知があります"' <<< "$INPUT")
TITLE=$(jq -r '.title // "Claude Code"' <<< "$INPUT")
NOTIFICATION_TYPE=$(jq -r '.notification_type // "unknown"' <<< "$INPUT")

case "$NOTIFICATION_TYPE" in
  permission_prompt)   SUBTITLE="権限の確認が必要です" ;;
  idle_prompt)         SUBTITLE="入力待ちです" ;;
  elicitation_dialog)  SUBTITLE="追加情報が必要です" ;;
  *)                   SUBTITLE="" ;;
esac

ICON_PATH="@iconPath@"

ARGS=(-title "$TITLE" -message "$MESSAGE" -group "$SESSION_ID" -sound Breeze)
[[ -n "$SUBTITLE" ]] && ARGS+=(-subtitle "$SUBTITLE")
[[ -f "$ICON_PATH" ]] && ARGS+=(-contentImage "$ICON_PATH")

if [[ -n "${TMUX:-}" ]]; then
  TMUX_SOCKET="${TMUX%%,*}"
  # TMUX_PANE (e.g. %5) でセッション・ウィンドウ・ペインを一括切り替え
  # フォールバック: セッション名のみ（従来の動作）
  SWITCH_TARGET="${TMUX_PANE:-$(tmux -S "$TMUX_SOCKET" display-message -p '#S' 2>/dev/null || true)}"

  if [[ -n "$SWITCH_TARGET" ]]; then
    # 一時スクリプトを作成（-executeでのエスケープ問題を回避）
    ACTIVATE_SCRIPT="/tmp/claude/activate-tmux-${SESSION_ID}.sh"
    mkdir -p /tmp/claude
    cat > "$ACTIVATE_SCRIPT" << EOF
#!/bin/bash
export PATH=/etc/profiles/per-user/\$USER/bin:/run/current-system/sw/bin:/usr/local/bin:/opt/homebrew/bin:\$PATH
osascript -e 'tell application "Alacritty" to activate'
for client in \$(tmux -S '$TMUX_SOCKET' list-clients -F '#{client_tty}'); do
  tmux -S '$TMUX_SOCKET' switch-client -c "\$client" -t '$SWITCH_TARGET' 2>/dev/null || true
done
EOF
    chmod +x "$ACTIVATE_SCRIPT"
    ARGS+=(-execute "$ACTIVATE_SCRIPT")
  fi
fi

terminal-notifier "${ARGS[@]}"
