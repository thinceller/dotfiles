if type pipenv > /dev/null 2>&1
then
  export PIPENV_VENV_IN_PROJECT=true
  eval "$(pipenv --completion)"
fi

# anyenv setting
export GOENV_DISABLE_GOPATH=1
export PATH=$HOME/.anyenv/bin:$PATH
if type anyenv > /dev/null 2>&1
then
  if ! [ -f /tmp/anyenv.cache ]
  then
    anyenv init - --no-rehash > /tmp/anyenv.cache
    zcompile /tmp/anyenv.cache
  fi
  source /tmp/anyenv.cache

  if ! [ -f /tmp/nodenv.cache ]
  then
    nodenv init - > /tmp/nodenv.cache
    zcompile /tmp/nodenv.cache
  fi
  source /tmp/nodenv.cache

  if ! [ -f /tmp/rbenv.cache ]
  then
    nodenv init - > /tmp/rbenv.cache
    zcompile /tmp/rbenv.cache
  fi
  source /tmp/rbenv.cache
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
