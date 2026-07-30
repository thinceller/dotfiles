#!/usr/bin/env bash
# SessionStart hook: Claude Code on the web のクラウドセッションで Nix を使えるようにする。
# ローカルセッションでは何もしない。
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# 環境設定の Setup script が未設定でも動くようにするフォールバック
"$CLAUDE_PROJECT_DIR/scripts/setup-claude-cloud.sh"

# 以後の Bash コマンドで nix が PATH に入るようにする (resume 時の重複追記は避ける)
case ":$PATH:" in
*":$HOME/.nix-profile/bin:"*) ;;
*)
  if [ -n "${CLAUDE_ENV_FILE:-}" ] && [ -d "$HOME/.nix-profile/bin" ]; then
    echo "PATH=$HOME/.nix-profile/bin:$PATH" >> "$CLAUDE_ENV_FILE"
  fi
  ;;
esac
