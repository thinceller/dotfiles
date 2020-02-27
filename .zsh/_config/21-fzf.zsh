[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_TMUX=1
export FZF_TMUX_HEIGHT=40%

# hub pull-request checkout
hbr() {
  local pr
  pr=$(
    gh pr list --limit 100 \
      | fzf-tmux --preview 'gh pr view -p {1}' \
      | cut -f1
  )
  if [ -z $pr ]; then
    return
  fi
  gh pr checkout $pr
}

# hub browse any repository
hshow() {
  local repo
  repo=$(ghq list | fzf-tmux +m | cut -d '/' -f 2,3)
  if [ -z $repo ]; then
    return
  fi
  hub browse $repo
}
