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

# グロブ展開対策
setopt nonomatch

# zsh setting
autoload -Uz compinit
compinit

# ctags setting
alias ctags="`brew --prefix`/bin/ctags"

# pyenv setting
PYENV_ROOT=~/.pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

export PIPENV_VENV_IN_PROJECT=true
eval "$(pipenv --completion)"


# rbenv setting
eval "$(rbenv init -)"

# nodenv setting
eval "$(nodenv init -)"

# goenv setting
eval "$(goenv init -)"
export PATH="$HOME/go/bin:$PATH"


# direnv setting
export EDITOR=/usr/bin/vim
eval "$(direnv hook zsh)"


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
export PKG_CONFIG_PATH=/opt/ImageMagick/lib/pkgconfig


# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/kohei/projects/Baseconnect/crawler/node_modules/tabtab/.completions/sls.zsh


# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_TMUX=1
export FZF_TMUX_HEIGHT=40%

# fzf function
# fbr - checkout git branch
fbr() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# fv - fuzzy open with vim from anywhere
# 参考: https://qiita.com/Sa2Knight/items/6635af9fc648a5431685
fv() {
  files=$(git ls-files) &&
  selected_files=$(echo "$files" | fzf -m --preview 'head -100 {}') &&
  vim $selected_files
}

# fkill - kill process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x"  ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}


# alias
alias gfc='git commit --allow-empty -m "first commit [ci skip]"'

