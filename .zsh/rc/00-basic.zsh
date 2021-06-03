# グロブ展開対策
setopt nonomatch

# zsh setting
bindkey -e

# edit-command-line
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line
