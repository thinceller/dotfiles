#!/usr/bin/env sh

set -x

# golang 環境がない場合は exit
if !(type go > /dev/null 2>&1); then
  exit 1
fi

# インストール
go get -u github.com/x-motemen/ghq
go get -u golang.org/x/tools/cmd/goimports
go get -u github.com/motemen/gore/cmd/gore
go get -u github.com/github/hub
go get -u github.com/mattn/memo
go get -u github.com/toshimaru/nyan
