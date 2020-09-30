alias ctags="`brew --prefix`/bin/ctags"

alias gfc='git commit --allow-empty -m "first commit"'

alias ssh='TERM=xterm-256color ssh'

if type nyan > /dev/null 2>&1; then
  alias cat='nyan'
fi

if type exa > /dev/null 2>&1; then
  alias ll='exa -alh'
  alias la='exa -ah'
else
  alias ll='ls -alh'
  alias la='ls -ah'
fi

if type kubectl > /dev/null 2>&1; then
  alias k='kubectl'
fi

