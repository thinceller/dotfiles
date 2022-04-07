#================================================
# basic
#================================================
setopt nonomatch
bindkey -e

#================================================
# alias
#================================================
alias ll='exa -alh'
alias la='exa -ah'

if type kubectl > /dev/null 2>&1; then
  alias k='kubectl'
fi

if type nvim > /dev/null 2>&1; then
  alias vim='nvim'
fi

#================================================
# plugins
#================================================
eval "$(sheldon source)"

#================================================
# prompt
#================================================
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#================================================
# direnv
#================================================
eval "$(direnv hook zsh)"

#================================================
# asdf
#================================================
. $(brew --prefix asdf)/libexec/asdf.sh

#================================================
# fzf
#================================================
[[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh ]] && $(brew --prefix)/opt/fzf/install --xdg --no-bash --no-fish

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh ] && source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh

export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

#================================================
# zeno
#================================================
export ZENO_HOME="$HOME/.config/zeno"
export ZENO_ENABLE_SOCK=1
export ZENO_GIT_CAT="bat --color=always"
export ZENO_GIT_TREE="exa --tree"

if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet

  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^i' zeno-completion

  bindkey '^r' zeno-history-selection
  bindkey '^g' zeno-ghq-cd
fi
