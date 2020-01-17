### Added by Zplugin's installer
source "$HOME/.zplugin/bin/zplugin.zsh"
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin installer's chunk

### plugins
zplugin light zsh-users/zsh-autosuggestions
zplugin light zdharma/fast-syntax-highlighting
zplugin light mollifier/anyframe

zplugin light romkatv/powerlevel10k
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

### 各種設定の読み込み
for f in $ZDOTDIR/_config/*.zsh
do
  source "$f"
done

fpath=(~/.zsh/completions $fpath)
autoload -U compinit && compinit
