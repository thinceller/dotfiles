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
export PATH="/usr/local/bin:$PATH"

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/sls.zsh