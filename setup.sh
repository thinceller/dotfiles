#!/bin/bash

echo "Create synlink..."

for file in .??*
do
  [[ $file == ".git" ]] && continue
  [[ $file == ".DS_Store" ]] && continue

  ln -sfnv $HOME/dotfiles/$file $HOME/$file
done

# init.vimのみ.vimrcとして$HOME直下に配置する
ln -sfnv $HOME/dotfiles/.config/nvim/init.vim $HOME/.vimrc

echo "Succeeded!"

