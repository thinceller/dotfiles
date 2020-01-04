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
fpath+=${ZDOTDIR:-~}/.zsh_functions
export PATH="$HOME/.cargo/bin:$PATH"
# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6D6D6D'

# グロブ展開対策
setopt nonomatch

# zsh setting
autoload -Uz compinit
compinit

# spaceship settings
export SPACESHIP_DOCKER_SHOW=false
export SPACESHIP_KUBECONTEXT_SHOW=false

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

# go settings
export GOROOT="/usr/local/go"
export GOPATH=$(go env GOPATH)
export PATH="$GOPATH/bin:$PATH"


# direnv setting
export EDITOR=/usr/local/bin/vim
eval "$(direnv hook zsh)"


# google-cloud-sdk setting
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/kohei/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/kohei/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/kohei/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/kohei/google-cloud-sdk/completion.zsh.inc'; fi


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
# fd() {
#   local dir
#   dir=$(find ${1:-.} -path '*/\.*' -prune \
#                   -o -type d -print 2> /dev/null | fzf +m) &&
#   cd "$dir"
# }

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

ghq-fzf() {
  local dir
  dir=$(ghq list -p > /dev/null | fzf-tmux --reverse +m) &&
    cd $dir
}
alias fd='ghq-fzf'
zle -N ghq-fzf
bindkey "^g" ghq-fzf


# alias
alias gfc='git commit --allow-empty -m "first commit [ci skip]"'
alias cat='nyan'
alias ll='exa -alh'
alias la='exa -ah'

export PATH="/usr/local/opt/llvm/bin:$PATH"

# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
[[ -f /Users/kohei/src/github.com/Baseconnect/Baseconnect/crawler/node_modules/tabtab/.completions/slss.zsh ]] && . /Users/kohei/src/github.com/Baseconnect/Baseconnect/crawler/node_modules/tabtab/.completions/slss.zsh
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
