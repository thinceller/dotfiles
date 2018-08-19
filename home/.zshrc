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
precmd() {
    pwd=$(pwd)
    cwd=${pwd##*/}
    print -Pn "\e]0;$cwd\a"
}
preexec() {
    printf "\033]0;%s\a" "${1%% *} | $cwd"
}

# zsh plugin: smart-change-directory
source ~/.Software/smart-change-directory/shellrcfiles/zshrc_scd

# Baseconnect setting
alias jsb='webpack --progress --colors --watch'
export PATH="/usr/local/bin:$PATH"
