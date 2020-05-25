if [[ -d $HOME/.pyenv ]]
then
  PYENV_ROOT=$HOME/.pyenv
  export PYENV_ROOT=$HOME/.pyenv
  export PATH=$PYENV_ROOT/bin:$PATH
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

if type pipenv > /dev/null 2>&1
then
  export PIPENV_VENV_IN_PROJECT=true
  eval "$(pipenv --completion)"
fi

# rbenv setting
if [[ -d $HOME/.rbenv ]]
then
  eval "$(rbenv init -)"
fi

# anyenv setting
export GOENV_DISABLE_GOPATH=1
export PATH=$HOME/.anyenv/bin:$PATH
if type anyenv > /dev/null 2>&1
then
  eval "$(anyenv init -)"
fi
# anyenv の設定後に GOPATH 等を設定する
export GOROOT=$(go env GOROOT)
export GOPATH=$(go env GOPATH)
export PATH=$GOPATH/bin:$PATH

# direnv setting
if type direnv > /dev/null 2>&1
then
  eval "$(direnv hook zsh)"
fi
