if type pipenv > /dev/null 2>&1
then
  export PIPENV_VENV_IN_PROJECT=true
  eval "$(pipenv --completion)"
fi

# anyenv setting
ANYENV_ROOT="$HOME/.anyenv"
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

  if [ -d "$ANYENV_ROOT/envs/nodenv" ]; then
    if ! [ -f /tmp/nodenv.cache ]
    then
      nodenv init - > /tmp/nodenv.cache
      zcompile /tmp/nodenv.cache
    fi
    source /tmp/nodenv.cache
  fi

  if [ -d "$ANYENV_ROOT/envs/rbenv" ]; then
    if ! [ -f /tmp/rbenv.cache ]
    then
      nodenv init - > /tmp/rbenv.cache
      zcompile /tmp/rbenv.cache
    fi
    source /tmp/rbenv.cache
  fi

  if [ -d "$ANYENV_ROOT/envs/goenv" ]; then
    # lazy loading goenv
    export PATH="$ANYENV_ROOT/envs/goenv/shims:${PATH}"
    export GOENV_SHELL=zsh
    export GOROOT=$(go env GOROOT)
    export GOPATH=$(go env GOPATH)
    export PATH=$GOPATH/bin:$PATH
    goenv() {
      unfunction "$0"
      source <(goenv init -)
      $0 "$@"
    }
    # if ! [ -f /tmp/goenv.cache ]
    # then
    #   goenv init - > /tmp/goenv.cache
    #   zcompile /tmp/goenv.cache
    # fi
    # source /tmp/goenv.cache
  fi
fi

# direnv setting
if type direnv > /dev/null 2>&1
then
  eval "$(direnv hook zsh)"
fi
