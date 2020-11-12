# Setup zinit
if [ -z "$ZINIT_HOME" ]; then
  ZINIT_HOME="$HOME/.zinit"
fi

if ! [ -d "$ZINIT_HOME" ]; then
  mkdir "$ZINIT_HOME"
  git clone --depth 10 https://github.com/zdharma/zinit.git ${ZPLG_HOME}/bin
fi

source "$ZINIT_HOME/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# plugins
zinit load mollifier/anyframe
zinit load zsh-users/zsh-completions
zinit load g-plane/zsh-yarn-autocompletions

zinit ice wait'!0'; zinit load zsh-users/zsh-autosuggestions
zinit ice wait'!0'; zinit load zdharma/fast-syntax-highlighting

zinit ice lucid wait"0" depth"1" blockf
zinit light yuki-ycino/fzf-preview.zsh

zinit ice depth=1; zinit light romkatv/powerlevel10k

# load completions
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit -C
zinit cdreplay -q
