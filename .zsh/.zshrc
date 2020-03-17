# 環境変数の設定
export EDITOR=vim

export PATH=/usr/local/go/bin:$PATH
export GOROOT=$(go env GOROOT)
export GOPATH=$(go env GOPATH)
export PATH=$GOPATH/bin:$PATH

export PATH=/usr/local/opt/llvm/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH

# brew tools
export PATH=/usr/local/opt/mysql@5.7/bin:$PATH

### Added by Zinit's installer
source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit installer's chunk

### plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma/fast-syntax-highlighting
zinit light mollifier/anyframe

zinit light romkatv/powerlevel10k
[[ -f ~/.zsh/.p10k.zsh ]] && source ~/.zsh/.p10k.zsh

### 各種設定の読み込み
for f in $ZDOTDIR/_config/*.zsh
do
  source "$f"
done

fpath=(~/.zsh/completions $fpath)
autoload -U compinit && compinit
