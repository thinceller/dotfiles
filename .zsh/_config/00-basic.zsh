# グロブ展開対策
setopt nonomatch

# zsh setting
autoload -Uz compinit
compinit

bindkey -e

bindkey '^i' fzf-or-normal-completion
