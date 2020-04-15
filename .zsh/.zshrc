# 環境変数の設定
export EDITOR=vim

export PATH=/usr/local/go/bin:$PATH

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
zinit load mollifier/anyframe
zinit load zsh-users/zsh-completions
zinit load g-plane/zsh-yarn-autocompletions

zinit ice wait'!0'; zinit load zsh-users/zsh-autosuggestions
zinit ice wait'!0'; zinit load zdharma/fast-syntax-highlighting

zinit light romkatv/powerlevel10k
[[ -f ~/.zsh/.p10k.zsh ]] && source ~/.zsh/.p10k.zsh

# load completions
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
zinit cdreplay -q

### 各種設定の読み込み
for f in $ZDOTDIR/_config/*.zsh
do
  source "$f"
done
