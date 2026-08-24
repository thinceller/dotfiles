# Statusline command for Claude Code
# This script is wrapped by pkgs.writeShellScript (Nix bash 5.3)
# Do NOT add set -euo pipefail — resilience over strictness for statusline

# ── Fallback trap ───────────────────────────────────────────────────
# Ensure we always output something (4 lines) even on unexpected errors.
# Claude Code blanks the statusline when the command produces no output.
_output_done=""
trap '
  if [[ -z "$_output_done" ]]; then
    printf "\033[33m⚠ statusline error\033[0m\n\n\n"
  fi
' EXIT

# ── Nerd Font icons ──────────────────────────────────────────────────

ICON_REPO=$(printf '\xef\x90\x81')        # nf-oct-repo U+F401
ICON_FOLDER=$(printf '\xee\xaa\x83')      # nf-cod-folder U+EA83
ICON_BRANCH=$(printf '\xee\x9c\xa5')      # nf-dev-git_branch U+E725
ICON_WORKTREE=$(printf '\xf3\xb0\x99\x85') # nf-md-file_tree U+F0645
ICON_STAGED=$(printf '\xee\xab\x9c')      # nf-cod-diff_added U+EADC
ICON_MODIFIED=$(printf '\xee\xab\x9e')    # nf-cod-diff_modified U+EADE
ICON_UNTRACKED=$(printf '\xee\xa9\xb6')   # nf-cod-question U+EA76

# ── モデル別週次上限 (Fable 等) のキャッシュ設定 ──────────────────────
# statusline の stdin JSON が持つ rate_limits は全体の 5h/7d だけで、
# モデル別バケットは 2.1.238 時点でも未露出。そこだけ /api/oauth/usage を
# 直接叩いて補う (非公式 API)。キャッシュは全セッション共有で、
# TTL 内は誰も API を叩かない。
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
CACHE_FILE="$CACHE_DIR/usage.json"
LOCK_FILE="$CACHE_DIR/fetch.lock"
FAIL_FILE="$CACHE_DIR/fetch.fail"
CACHE_TTL=600      # これより新しいキャッシュがあれば API を叩かない
LOCK_TTL=60        # 同時 fetch の抑止 (ハングした fetch もこの後に再開)
BACKOFF_BASE=60    # 失敗 1 回目の待ち時間
BACKOFF_MAX=1800   # 失敗が続いた時の待ち時間の上限

# ── helpers ──────────────────────────────────────────────────────────

color_for_pct() {
  local pct=${1:-0}
  if (( pct < 50 )); then echo 32   # green
  elif (( pct < 80 )); then echo 33  # yellow
  else echo 31                        # red
  fi
}

render_bar() {
  local pct=${1:-0} width=${2:-20} color=${3:-32}
  pct=${pct%.*}; pct=${pct:-0}  # truncate float (e.g. "14.5" → "14", ".5" → "0")
  if (( pct > 100 )); then pct=100; fi
  if (( pct < 0 )); then pct=0; fi
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local filled_str="" empty_str=""
  if (( filled > 0 )); then printf -v filled_str '%*s' "$filled" '' && filled_str="${filled_str// /█}"; fi
  if (( empty > 0 )); then printf -v empty_str '%*s' "$empty" '' && empty_str="${empty_str// /░}"; fi
  printf '\033[%sm%s\033[90m%s\033[0m' "$color" "$filled_str" "$empty_str"
}

fish_style_path() {
  local path=$1
  [[ -z "$path" ]] && return
  [[ "$path" == "$HOME"* ]] && path="~${path#"$HOME"}"

  local IFS='/' parts=() result=()
  read -ra parts <<< "$path"
  local last_idx=$(( ${#parts[@]} - 1 ))
  for i in "${!parts[@]}"; do
    local part="${parts[$i]}"
    if [[ -z "$part" ]]; then
      continue
    elif (( i == last_idx )) || [[ "$part" == "~" ]]; then
      result+=("$part")
    elif [[ "$part" == .* ]]; then
      result+=("${part:0:2}")
    else
      result+=("${part:0:1}")
    fi
  done

  local IFS='/'
  echo "${result[*]}"
}

format_jst() {
  local ts=$1 fmt=${2:-"%H:%M JST"}
  if [[ -z "$ts" || "$ts" == "null" || "$ts" == "0" ]]; then echo "N/A"; return; fi

  local epoch

  if [[ "$ts" =~ ^[0-9]+$ ]]; then
    epoch="$ts"
  else
    local clean="${ts%%+*}"
    clean="${clean%%Z*}"
    clean="${clean%%.*}"
    epoch=$(TZ=UTC /bin/date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" "+%s" 2>/dev/null) || { echo "N/A"; return; }
  fi

  TZ=Asia/Tokyo /bin/date -j -r "$epoch" "+${fmt}" 2>/dev/null || echo "N/A"
}

mtime_of() {
  /usr/bin/stat -f %m "$1" 2>/dev/null || echo 0
}

# /api/oauth/usage を叩いてキャッシュを差し替える。成否を終了コードで返す。
_do_fetch() {
  local creds token response
  creds=$(/usr/bin/security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || return 1
  token=$(printf '%s' "$creds" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null) || return 1
  if [[ -z "$token" ]]; then return 1; fi

  response=$(/usr/bin/curl -s --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return 1

  # limits[] を持たない body (認証エラー等) はキャッシュしない
  printf '%s' "$response" | jq -e 'has("limits")' >/dev/null 2>&1 || return 1

  local tmp="$CACHE_FILE.$$"
  printf '%s' "$response" > "$tmp" 2>/dev/null || return 1
  mv -f "$tmp" "$CACHE_FILE" 2>/dev/null
}

# バックグラウンドで走る本体。失敗回数を記録してロックを外す。
_refresh_cache() {
  if _do_fetch; then
    rm -f "$FAIL_FILE"
  else
    local fails
    fails=$(cat "$FAIL_FILE" 2>/dev/null) || fails=0
    if [[ ! "$fails" =~ ^[0-9]+$ ]]; then fails=0; fi
    printf '%s' "$(( fails + 1 ))" > "$FAIL_FILE"
  fi
  rm -f "$LOCK_FILE"
}

# キャッシュが古ければバックグラウンドで更新する (描画はブロックしない)。
# 429 や認証切れで叩き続けないよう、失敗が続く間は指数バックオフする。
maybe_refresh_usage_cache() {
  local now=$1
  # トークンは macOS Keychain からしか取れない。この設定は Linux ホスト
  # (oberon) にも配られるので、そこでは何もしない (mtime_of が常に 0 を返し、
  # 毎描画で fetch を撒いてしまうため)。
  [[ -x /usr/bin/security ]] || return
  mkdir -p "$CACHE_DIR" 2>/dev/null || return

  if (( now - $(mtime_of "$CACHE_FILE") < CACHE_TTL )); then return; fi

  if [[ -f "$FAIL_FILE" ]]; then
    local fails delay
    fails=$(cat "$FAIL_FILE" 2>/dev/null) || fails=1
    if [[ ! "$fails" =~ ^[0-9]+$ ]] || (( fails < 1 )); then fails=1; fi
    if (( fails > 6 )); then fails=6; fi
    delay=$(( BACKOFF_BASE << (fails - 1) ))
    if (( delay > BACKOFF_MAX )); then delay=$BACKOFF_MAX; fi
    if (( now - $(mtime_of "$FAIL_FILE") < delay )); then return; fi
  fi

  # 他セッションが fetch 中なら任せる
  if (( now - $(mtime_of "$LOCK_FILE") < LOCK_TTL )); then return; fi

  touch "$LOCK_FILE" 2>/dev/null || return
  # リダイレクトはサブシェル自体に掛ける。statusline の stdout を掴んだままに
  # すると Claude Code 側がコマンド完了を待ってしまう。
  _refresh_cache >/dev/null 2>&1 </dev/null &
  disown 2>/dev/null
}

# キャッシュから weekly_scoped (モデル別週次) を "名前<TAB>整数%" で列挙する。
# resets_at を過ぎたエントリはリセット済みの古い値なので捨てる (認証が壊れて
# fetch が長時間失敗した時に古い値を出し続けないため)。resets_at は UTC の
# ISO8601 なので、秒より下を切り捨てて jq 側で比較する。
scoped_weekly_usage() {
  [[ -f "$CACHE_FILE" ]] || return

  jq -r '
    def not_expired:
      (.resets_at // "") as $r
      | ($r | length) >= 19
        and (($r[0:19] + "Z" | try fromdateiso8601 catch 0) > now);
    .limits[]?
    | select(.kind == "weekly_scoped")
    | select((.scope.model.display_name // "") != "")
    | select(not_expired)
    | "\(.scope.model.display_name)\t\((.percent // 0) | floor)"
  ' "$CACHE_FILE" 2>/dev/null
}

# ── main ─────────────────────────────────────────────────────────────

now=$(/bin/date +%s) || now=0

# git 処理と並行させたいので、描画より先に投げておく
maybe_refresh_usage_cache "$now"

input=$(cat)

# Parse all fields from stdin JSON in a single jq call (one field per line)
model="Unknown"; ctx_raw_pct=0; current_dir=""; worktree_name=""
five_hour_pct=0; five_hour_reset=""; seven_day_pct=0; seven_day_reset=""
effort=""

if jq_output=$(printf '%s' "$input" | jq -r '
  (.model.display_name // "Unknown"),
  ((.context_window.used_percentage // 0) | floor),
  (.workspace.current_dir // .cwd // ""),
  (.worktree.name // ""),
  ((.rate_limits.five_hour.used_percentage // 0) | floor),
  (.rate_limits.five_hour.resets_at // ""),
  ((.rate_limits.seven_day.used_percentage // 0) | floor),
  (.rate_limits.seven_day.resets_at // ""),
  (.effort.level // "")
' 2>/dev/null); then
  {
    read -r model
    read -r ctx_raw_pct
    read -r current_dir
    read -r worktree_name
    read -r five_hour_pct
    read -r five_hour_reset
    read -r seven_day_pct
    read -r seven_day_reset
    read -r effort
  } <<< "$jq_output" || true
fi

# Convert context usage to percentage of auto-compact threshold
compact_threshold=${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE:-95}
ctx_pct=$(printf '%s' "${ctx_raw_pct:-0}" | awk -v threshold="$compact_threshold" '{printf "%d", $1 / threshold * 100}') || ctx_pct=0

# ── Line 1: Git info ────────────────────────────────────────────────

line1=""
if [[ -n "$current_dir" ]] && git -C "$current_dir" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_root=$(git -C "$current_dir" --no-optional-locks rev-parse --show-toplevel 2>/dev/null) || git_root=""
  repo_name=$(fish_style_path "$git_root")
  branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null) || branch=""

  # Relative path from git root
  rel_path=""
  if [[ -n "$git_root" && "$current_dir" != "$git_root" ]]; then
    rel_path="${current_dir#"$git_root"/}"
  fi

  # Worktree detection: from JSON or .git file
  wt=""
  if [[ -n "$worktree_name" ]]; then
    wt="$worktree_name"
  elif [[ -f "$current_dir/.git" ]]; then
    wt=$(basename "$current_dir")
  fi

  # Git status counts (with 150ms timeout to prevent slow execution)
  staged=0; modified=0; untracked=0
  git_porcelain=""
  if read -r -d '' -t 0.15 git_porcelain < <(git -C "$current_dir" --no-optional-locks status --porcelain 2>/dev/null) 2>/dev/null; then
    : # completed within timeout
  fi
  # Process whatever output we got (full or partial)
  if [[ -n "$git_porcelain" ]]; then
    while IFS= read -r st_line; do
      [[ -z "$st_line" ]] && continue
      x="${st_line:0:1}"; y="${st_line:1:1}"
      if [[ "$x" == "?" ]]; then (( untracked++ )) || true; continue; fi
      if [[ "$x" != " " && "$x" != "?" ]]; then (( staged++ )) || true; fi
      if [[ "$y" != " " && "$y" != "?" ]]; then (( modified++ )) || true; fi
    done <<< "$git_porcelain"
  fi

  # Build line 1
  line1="\033[36m${ICON_REPO} ${repo_name}\033[0m"
  if [[ -n "$rel_path" ]]; then line1+="  \033[34m${ICON_FOLDER} ${rel_path}\033[0m"; fi
  if [[ -n "$branch" ]]; then line1+="  \033[35m${ICON_BRANCH} ${branch}\033[0m"; fi
  if [[ -n "$wt" ]]; then line1+="  \033[33m${ICON_WORKTREE} ${wt}\033[0m"; fi
  if (( staged > 0 )); then line1+="  \033[32m${ICON_STAGED} ${staged}\033[0m"; fi
  if (( modified > 0 )); then line1+="  \033[33m${ICON_MODIFIED} ${modified}\033[0m"; fi
  if (( untracked > 0 )); then line1+="  \033[31m${ICON_UNTRACKED} ${untracked}\033[0m"; fi
else
  # Not in git repo
  display_dir=$(fish_style_path "$current_dir")
  line1="\033[36m${ICON_FOLDER} ${display_dir}\033[0m"
fi

# ── Line 2: Model / Context ─────────────────────────────────────────

ctx_color=$(color_for_pct "$ctx_pct")
ctx_bar=$(render_bar "$ctx_pct" 20 "$ctx_color")

line2="🤖 \033[35m${model}\033[0m"
if [[ -n "$effort" ]]; then line2+=" \033[36m⚡${effort}\033[0m"; fi
line2+=" | 📊 [${ctx_bar}] \033[${ctx_color}m${ctx_pct}%\033[0m (compact@${compact_threshold}%)"

# ── Lines 3-4: Usage (session / weekly) ─────────────────────────────

five_color=$(color_for_pct "$five_hour_pct")
five_bar=$(render_bar "$five_hour_pct" 20 "$five_color")
five_reset_fmt=$(format_jst "$five_hour_reset" "%H:%M JST")

seven_color=$(color_for_pct "$seven_day_pct")
seven_bar=$(render_bar "$seven_day_pct" 20 "$seven_color")
seven_reset_fmt=$(format_jst "$seven_day_reset" "%m/%d %H:%M JST")

printf -v five_pct_str '%3d%%' "${five_hour_pct:-0}"
printf -v seven_pct_str '%3d%%' "${seven_day_pct:-0}"
line3="⏱  5h [${five_bar}] \033[${five_color}m${five_pct_str}\033[0m  🔄 ${five_reset_fmt}"
line4="📅 7d [${seven_bar}] \033[${seven_color}m${seven_pct_str}\033[0m"

# モデル別週次 (Fable 等) を 7d 行に併記する。reset 時刻は 7d と同じ窓なので共有。
while IFS=$'\t' read -r scoped_name scoped_pct; do
  if [[ -z "$scoped_name" ]]; then continue; fi
  scoped_color=$(color_for_pct "$scoped_pct")
  scoped_bar=$(render_bar "$scoped_pct" 10 "$scoped_color")
  printf -v scoped_pct_str '%3d%%' "${scoped_pct:-0}"
  line4+="  ✨ ${scoped_name} [${scoped_bar}] \033[${scoped_color}m${scoped_pct_str}\033[0m"
done < <(scoped_weekly_usage)

line4+="  🔄 ${seven_reset_fmt}"

# ── Output ───────────────────────────────────────────────────────────

printf '%b\n%b\n%b\n%b' "$line1" "$line2" "$line3" "$line4"
_output_done=1

# ── herdr sidebar metadata ───────────────────────────────────────────
# herdr pane 内なら model / effort / ctx をカスタムトークンとして報告し、
# サイドバーの Claude エントリ (configs/.config/herdr/config.toml の
# rows_by_agent.claude) に表示させる。best-effort: 失敗しても statusline
# 本体には影響させず、描画を遅らせないようバックグラウンドで実行する。
if [[ "${HERDR_ENV:-}" == "1" && -n "${HERDR_PANE_ID:-}" ]] && command -v herdr >/dev/null 2>&1; then
  herdr_args=(
    pane report-metadata "$HERDR_PANE_ID"
    --source custom:claude-statusline
    --token "model=${model}"
    --token "ctx=ctx ${ctx_pct}%"
  )
  if [[ -n "$effort" ]]; then
    herdr_args+=(--token "effort=⚡${effort}")
  else
    herdr_args+=(--clear-token effort)
  fi
  herdr "${herdr_args[@]}" >/dev/null 2>&1 &
fi
