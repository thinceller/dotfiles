# グロブ展開対策
setopt nonomatch

# zsh setting
autoload -Uz compinit
compinit

bindkey -e

bindkey '^i' fzf-or-normal-completion

# edit-command-line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line
