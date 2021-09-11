# direnv setting
if type direnv > /dev/null 2>&1
then
  eval "$(direnv hook zsh)"
fi

. $(brew --prefix asdf)/libexec/asdf.sh
