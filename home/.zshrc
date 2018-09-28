#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
# ====================================================================================================
# LANG setting
export LANG=ja_JP.UTF-8

# zsh setting
autoload -Uz compinit
compinit

# pyenv setting
PYENV_ROOT=~/.pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# rbenv setting
eval "$(rbenv init -)"

# Node.js setting
export PATH=$PATH:/Users/kohei/.nodebrew/current/bin

# google-cloud-sdk setting
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kohei/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/kohei/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kohei/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/kohei/google-cloud-sdk/completion.zsh.inc'; fi

# tab title set for hyper setting
title() { export TITLE_OVERRIDDEN=1; echo -en "\e]0;$*\a" }
autotitle() { export TITLE_OVERRIDDEN=0 }; autotitle
overridden() { [[ $TITLE_OVERRIDDEN == 1 ]]; }
gitDirty() { [[ $(git status 2> /dev/null | grep -o '\w\+' | tail -n1) != ("clean"|"") ]] && echo "*" }
# Show cwd when shell prompts for input.
precmd() {
   if overridden; then return; fi
   cwd=${$(pwd)##*/} # Extract current working dir only
   print -Pn "\e]0;$cwd$(gitDirty)\a" # Replace with $pwd to show full path
}

# Prepend command (w/o arguments) to cwd while waiting for command to complete.
preexec() {
   if overridden; then return; fi
   printf "\033]0;%s\a" "${1%% *} | $cwd$(gitDirty)" # Omit construct from $1 to show args
}

# zsh plugin: smart-change-directory
source ~/.Software/smart-change-directory/shellrcfiles/zshrc_scd

# Baseconnect setting
export PATH="/usr/local/bin:$PATH"

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/sls.zsh
