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
ICON_WORKTREE=$(printf '\xee\xa9\xa8')    # nf-cod-source_control U+EA68
ICON_STAGED=$(printf '\xee\xab\x9c')      # nf-cod-diff_added U+EADC
ICON_MODIFIED=$(printf '\xee\xab\x9e')    # nf-cod-diff_modified U+EADE
ICON_UNTRACKED=$(printf '\xee\xa9\xb6')   # nf-cod-question U+EA76

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

# ── main ─────────────────────────────────────────────────────────────

input=$(cat)

# Parse all fields from stdin JSON in a single jq call (one field per line)
model="Unknown"; ctx_raw_pct=0; current_dir=""; worktree_name=""
five_hour_pct=0; five_hour_reset=""; seven_day_pct=0; seven_day_reset=""

if jq_output=$(printf '%s' "$input" | jq -r '
  (.model.display_name // "Unknown"),
  (.context_window.used_percentage // 0),
  (.workspace.current_dir // .cwd // ""),
  (.worktree.name // ""),
  (.rate_limits.five_hour.used_percentage // 0),
  (.rate_limits.five_hour.resets_at // ""),
  (.rate_limits.seven_day.used_percentage // 0),
  (.rate_limits.seven_day.resets_at // "")
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

line2="🤖 \033[35m${model}\033[0m | 📊 [${ctx_bar}] \033[${ctx_color}m${ctx_pct}%\033[0m (compact@${compact_threshold}%)"

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
line4="📅 7d [${seven_bar}] \033[${seven_color}m${seven_pct_str}\033[0m  🔄 ${seven_reset_fmt}"

# ── Output ───────────────────────────────────────────────────────────

printf '%b\n%b\n%b\n%b' "$line1" "$line2" "$line3" "$line4"
_output_done=1
