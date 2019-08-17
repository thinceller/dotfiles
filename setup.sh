#!/bin/bash

echo "Create synlink..."

for file in .??*
do
  [[ $file == ".git" ]] && continue
  [[ $file == ".DS_Store" ]] && continue

  if [[ $file == ".vimrc" ]]; then
    ln -sfnv $HOME/dotfiles/$file $HOME/$file
    ln -sfnv $HOME/dotfiles/$file $HOME/.config/nvim/init.vim
  else
    ln -sfnv $HOME/dotfiles/$file $HOME/$file
  fi
done

echo "Succeeded!"
