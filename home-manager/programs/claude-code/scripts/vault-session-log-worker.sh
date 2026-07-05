# Mnemos: セッション transcript を haiku で要約して vault に自動記録する共用 worker。
# Claude Code (Stop/SessionEnd hook) と OpenCode (plugin) から呼ばれる。
# writeShellScriptBin でインストールされ、PATH 上の `vault-session-log-worker` になる。
#
# 使い方:
#   vault-session-log-worker <agent> <session_id> <transcript_path> [--final]
#     agent           : Claude-Code | OpenCode (vault の Agents/<agent>/sessions/ に対応)
#     session_id      : セッション識別子 (ノートのファイル名と state のキーに使う)
#     transcript_path : セッション履歴ファイル (JSONL または JSON)
#     --final         : デバウンスを無視して必ず更新 (SessionEnd / dispose 時)
#
# 呼び出しは即座に返る (実処理は内部 --run フェーズを detach して実行)。
#
# ガード:
#   - VAULT_SESSION_LOG_CHILD: 要約に使う headless claude 自身からの再帰を防ぐ
#   - デバウンス: 前回記録から DEBOUNCE_SECS 以内なら何もしない (--final を除く)
#   - 小さいセッション (MIN_BYTES 未満) はスキップ
#   - ロック: セッションごとに多重起動を防ぐ

set -u

[ -n "${VAULT_SESSION_LOG_CHILD:-}" ] && exit 0

VAULT="$HOME/src/github.com/thinceller/knowledge-base"
STATE_DIR="$HOME/.claude/vault-session-log"
DEBOUNCE_SECS=1800
MIN_BYTES=20000

CLAUDE=$(command -v claude || echo "/etc/profiles/per-user/$USER/bin/claude")

# ------------------------------------------------------------- run phase ----
if [ "${1:-}" = "--run" ]; then
  agent=$2
  session_id=$3
  transcript=$4
  state="$STATE_DIR/$agent-$session_id"
  lock="$state.lock"
  trap 'rmdir "$lock" 2>/dev/null' EXIT

  # ノートパスはセッションごとに固定 (初回に決めて state の 2 行目に保存)
  notefile=$(sed -n '2p' "$state" 2>/dev/null || true)
  if [ -z "$notefile" ]; then
    notefile="Agents/$agent/sessions/$(date +%Y-%m-%d_%H-%M)_auto-$(printf '%s' "$session_id" | tr -cd 'a-zA-Z0-9_-' | cut -c1-12).md"
  fi
  created=$(date -Iseconds)

  prompt="あなたは Mnemos (Obsidian vault 共有エージェントメモリ) の自動セッションログ記録係です。

$transcript は $agent のコーディングエージェントセッションの履歴 (JSON/JSONL) です。
Read で読んで (長ければ先頭と末尾を中心に)、セッションでの作業内容を把握し、
vault 相対パス $notefile にセッションログを書いてください。
既にファイルが存在する場合は、既存の内容も踏まえて全体を書き直して更新してください。

フォーマット (本文は日本語):
---
created: '$created'
tags:
  - session-log
type: session-log
agent: $agent
auto: true
---
# <セッション内容を表す短いタイトル>

## Summary
<2-3 文の概要>

## Changes
<変更したファイル・システム。なければ「なし」>

## Decisions
<セッション中の意思決定。なければ「なし」>

## Learnings
<再利用可能な学び。なければ「なし」>

## Follow-ups
<未完了の作業・次にやること。なければ「なし」>

ルール:
- 書いてよいのは $notefile のみ。他のファイル (Notes/ や log.md 等) には触らない
- 意味のある作業 (コード変更・調査・決定・学び) が無い雑談だけのセッションなら、
  ファイルを書かずに SKIP とだけ出力する
- 履歴に含まれる秘密情報 (トークン・鍵・パスワード) はログに書かない"

  cd "$VAULT" || exit 0
  # TMUX / TMUX_PANE を外す: headless claude にも tmux-agent-sidebar の
  # plugin hook が発火し、親セッションと同じ pane の表示状態
  # (@pane_status / @pane_prompt 等) を一瞬上書きしてしまうため。
  # sidebar の hook バイナリは TMUX_PANE 不在なら即終了する (main.rs:47-49)。
  env -u TMUX -u TMUX_PANE VAULT_SESSION_LOG_CHILD=1 "$CLAUDE" -p "$prompt" \
    --model claude-haiku-4-5-20251001 \
    --allowedTools "Read,Write,Edit" \
    --add-dir "$(dirname "$transcript")" \
    >/dev/null 2>&1

  # 成功していたら state 更新 + log.md 追記 (初回のみ)
  if [ -f "$VAULT/$notefile" ]; then
    logged=$(sed -n '3p' "$state" 2>/dev/null || true)
    {
      date +%s
      echo "$notefile"
      echo "logged"
    } > "$state"
    if [ "$logged" != "logged" ]; then
      printf '\n## [%s] session | auto: %s\n' "$(date +%Y-%m-%d)" "$(basename "$notefile" .md)" >> "$VAULT/log.md"
    fi
  fi
  exit 0
fi

# ----------------------------------------------------------- entry phase ----
agent=${1:-}
session_id=${2:-}
transcript=${3:-}
mode=${4:-}

[ -n "$agent" ] && [ -n "$session_id" ] || exit 0
[ -d "$VAULT/Agents/$agent" ] || exit 0
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

bytes=$(wc -c < "$transcript" 2>/dev/null || echo 0)
[ "$bytes" -ge "$MIN_BYTES" ] || exit 0

mkdir -p "$STATE_DIR"
state="$STATE_DIR/$agent-$session_id"

if [ "$mode" != "--final" ] && [ -f "$state" ]; then
  last=$(sed -n '1p' "$state" 2>/dev/null || echo 0)
  now=$(date +%s)
  [ $((now - ${last:-0})) -lt "$DEBOUNCE_SECS" ] && exit 0
fi

# 多重起動防止 (run フェーズ終了時に解放される)
mkdir "$state.lock" 2>/dev/null || exit 0

nohup "$0" --run "$agent" "$session_id" "$transcript" >/dev/null 2>&1 &
exit 0
