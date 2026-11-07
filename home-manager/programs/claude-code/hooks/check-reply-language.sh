#!/bin/bash
# Stop hook: メインセッションの最終返答が日本語かを検査し、英語なら書き直しを 1 回だけ求める。
# language = "japanese" を設定していても、英語のツール出力やサブエージェント報告が長く続くと
# 返答が英語に切り替わることがある (2026-09-26 に 2 回発生)。
# 閾値 0.15 は実 transcript の返答 339 件で決めた: 英語の返答は日本語率 0.07 以下、
# 日本語の返答は表や識別子が多くても 0.28 以上だった。

# claude -p の出力はプログラムが読む (JSON 等) ことがあり、書き直させると壊れるので対象外
if [ "${CLAUDE_CODE_ENTRYPOINT:-}" = sdk-cli ]; then
  exit 0
fi
input=$(cat)
if [ "$(jq -r '.stop_hook_active // false' <<<"$input")" = true ]; then
  exit 0
fi
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
[ -r "$transcript" ] || exit 0

# 最後の user エントリ (tool_result を含む) より後の assistant text を最終返答とみなす。
# tool_use だけで終わったターンは text が空になり判定しない。
# コードブロック・インラインコード・URL・ファイルパスは言語判定の対象外。
jq -nR '
  reduce (inputs | fromjson? // empty | select(.isSidechain != true)) as $e ([];
    if $e.type == "user" then []
    elif $e.type == "assistant" then . + [$e.message.content[]? | select(.type == "text") | .text]
    else . end)
  | join("\n")
  | gsub("```[\\s\\S]*?(?:```|\\z)"; " ")
  | gsub("`[^`\n]*`"; " ")
  | gsub("[a-zA-Z][a-zA-Z0-9+.-]*://[^\\s)>\\]]+"; " ")
  | gsub("[A-Za-z0-9_.~@+-]*(?:/[A-Za-z0-9_.~@+-]+)+/?"; " ")
  | ([match("[\\p{Hiragana}\\p{Katakana}\\p{Han}]"; "g")] | length) as $ja
  | ([match("[A-Za-z]"; "g")] | length) as $latin
  | select($ja + $latin >= 40 and $ja < ($ja + $latin) * 0.15)
  | {decision: "block", reason: "返答が英語になっています。直前の返答を日本語で書き直してください(コード・識別子はそのまま)。ユーザーが英語での出力を明示的に求めている場合は、書き直さずそのままで構いません。"}
' "$transcript"
