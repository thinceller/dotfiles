# 環境変数
export EDITOR=vim

export PATH=$HOME/bin:$PATH
export PATH=/usr/local/go/bin:$PATH

export PATH=/usr/local/opt/llvm/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH

export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)

export PATH="/Users/kawakami.kohei/.deno/bin:$PATH"

# brew tools
export PATH=/usr/local/opt/mysql@5.7/bin:$PATH
export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
