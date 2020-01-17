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
eval "$(rbenv init -)"

# anyenv setting
export PATH=$HOME/.anyenv/bin:$PATH
if type anyenv > /dev/null 2>&1
then
  eval "$(anyenv init -)"
fi

# direnv setting
eval "$(direnv hook zsh)"
