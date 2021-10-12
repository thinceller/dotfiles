#!/bin/sh

width=${2:-62%}
height=${2:-38%}

envs="env TERM=$TERM"
[[ -n "$FZF_DEFAULT_OPTS"    ]] && envs="$envs FZF_DEFAULT_OPTS=$(printf %q "$FZF_DEFAULT_OPTS")"
[[ -n "$FZF_DEFAULT_COMMAND" ]] && envs="$envs FZF_DEFAULT_COMMAND=$(printf %q "$FZF_DEFAULT_COMMAND")"

if [ -n "$TMUX" ]; then
  tmux popup -xC -yC -w$width -h$height -E "$envs tmux list-sessions | fzf --height 100% | cut -d : -f 1 | xargs tmux switch -t"
fi
