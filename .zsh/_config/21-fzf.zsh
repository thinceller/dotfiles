[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_TMUX=1
export FZF_TMUX_HEIGHT=40%

hbr() {
  local pr pr_num
  pr=$(hub pr list 2> /dev/null | fzf-tmux +m) &&
    pr_num=$(echo $pr | sed -e 's/^[ \t]*#\([0-9]*\)[ \t ]*.*/\1/') &&
    hub pr checkout $pr_num
}
