# 汎用的な環境変数の設定
export LANG=ja_JP.UTF-8
export EDITOR=vim

export PATH=/usr/local/go/bin:$PATH
export GOROOT=$(go env GOROOT)
export GOPATH=$(go env GOPATH)
export PATH=$GOPATH/bin:$PATH

export PATH="/usr/local/opt/llvm/bin:$PATH"
export PATH=$HOME/.cargo/bin:$PATH
