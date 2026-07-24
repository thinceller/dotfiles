# herdr sidebar に直近使用した tool 名 + 短い要約をカスタムトークンとして報告する
# PreToolUse hook。configs/.config/herdr/config.toml の
# ui.sidebar.agents.rows_by_agent.claude 4 行目 ($tool) に対応する。
# best-effort: 失敗してもセッションを妨げないよう、非ゼロ exit で終わらせない。

# ガード: herdr pane 内でない、あるいは jq / herdr が無ければ何もしない
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)

# 3 行出力: tool_name / agent_id / 整形済み detail。
# detail は tool_input から優先順で最初の非空文字列を採用し、
# 1 行目のみ・40 文字 (超過時は … 付与) に jq 内で整形する。
jq_output=$(printf '%s' "$input" | jq -r '
  (.tool_name // ""),
  (.agent_id // ""),
  ((.tool_input // {}) as $ti |
    (if ($ti.command // "") != "" then $ti.command | split("\n")[0]
     elif ($ti.file_path // "") != "" then $ti.file_path | sub(".*/"; "")
     elif ($ti.skill // "") != "" then $ti.skill
     elif ($ti.pattern // "") != "" then $ti.pattern
     elif ($ti.url // "") != "" then $ti.url
     elif ($ti.description // "") != "" then $ti.description
     else "" end)
    | gsub("[\\r\\n]"; " ")
    | if length > 40 then .[0:40] + "…" else . end)
' 2>/dev/null) || exit 0

tool_name=""; agent_id=""; detail=""
{
  read -r tool_name
  read -r agent_id
  read -r detail
} <<< "$jq_output" || true

[ -n "$tool_name" ] || exit 0
# subagent の tool 使用は表示しない (herdr-agent-state.sh と同じ判定。
# 並列 subagent で sidebar の表示がチラつくのを防ぐ)
[ -z "$agent_id" ] || exit 0

if [ -n "$detail" ]; then
  token="${tool_name}(${detail})"
else
  token="$tool_name"
fi

herdr pane report-metadata "$HERDR_PANE_ID" \
  --source custom:claude-tool \
  --token "tool=${token}" >/dev/null 2>&1 &
