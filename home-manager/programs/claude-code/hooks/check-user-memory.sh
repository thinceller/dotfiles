#!/bin/bash
# ~/.claude/CLAUDE.md (user memory) の消失検知。
# 2026-06 中旬〜2026-07-17 の間、この symlink が消えて全セッションから
# ユーザーメモリ (Lead Agent Policy 等) がサイレントに抜け落ちていた実績がある。
# 消失は home-manager の再 activation まで自己修復しないため、
# SessionStart で可読性を検証し、壊れていたらユーザーに警告を出す。
f="$HOME/.claude/CLAUDE.md"
if [ ! -r "$f" ]; then
  echo '{"systemMessage":"⚠ ~/.claude/CLAUDE.md (user memory) が読めません。このセッションには Lead Agent Policy 等が載っていません。darwin-rebuild switch で再配備してください。"}'
fi
exit 0
