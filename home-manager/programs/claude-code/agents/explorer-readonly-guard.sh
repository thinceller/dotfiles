#!/usr/bin/env bash
# PreToolUse guard for the explorer subagent: block non-read-only Bash commands.
# Receives the hook JSON on stdin. Exit 2 blocks the tool call (stderr is shown
# to the agent), exit 0 allows it. False positives are acceptable: this is a
# behavioral guard, not a security boundary (explorer has no Edit/Write tools).
set -uo pipefail

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -z "$cmd" ] && exit 0

deny() {
  echo "explorer is read-only: '$1' is not allowed. Use Read/Glob/Grep or a read-only command (rg, ls, find, cat, git log/show/diff/status, ...)." >&2
  exit 2
}

# Strip quoted strings: they commonly contain '>' or separators (e.g. rg "->")
# that would confuse the naive checks below. The first word of a segment is
# never quoted, so the allowlist check is unaffected.
scrubbed=$(sed -E "s/'[^']*'//g"' ; s/"[^"]*"//g' <<<"$cmd")
# Scrub harmless stderr/null redirections (2>&1, 2>/dev/null, >/dev/null),
# which are common in read-only usage. Any remaining '>' writes a file.
scrubbed=$(sed -E 's@[0-9]*>&[0-9]+@@g; s@[0-9]*> */dev/null@@g' <<<"$scrubbed")
case "$scrubbed" in
  *'>'*) deny "output redirection" ;;
esac

# Note: no 'env' (env VAR=x cmd runs arbitrary commands); printenv covers reads.
allowed='rg grep egrep fgrep ls find fd cat head tail wc file stat tree du df which type printenv echo printf awk sort uniq cut tr column diff comm jq yq basename dirname realpath readlink date'
git_allowed='log show diff status blame branch remote ls-files grep rev-parse describe shortlog tag reflog'

# Check the first word of each pipeline/sequence segment. Splitting on |;& is
# naive (also splits inside quotes) but errs on the side of blocking.
while IFS= read -r segment; do
  segment="${segment#"${segment%%[![:space:]]*}"}"
  [ -z "$segment" ] && continue
  first=${segment%% *}
  first=${first##*/}
  case " $allowed " in
    *" $first "*) continue ;;
  esac
  if [ "$first" = "git" ]; then
    sub=$(awk '{print $2}' <<<"$segment")
    case " $git_allowed " in
      *" $sub "*) continue ;;
    esac
    deny "git $sub"
  fi
  deny "$first"
done < <(tr '|;&' '\n' <<<"$scrubbed")

exit 0
