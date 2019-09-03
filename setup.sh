#!/bin/bash

echo "Create synlink..."

for file in .??*
do
  [[ $file == ".git" ]] && continue
  [[ $file == ".DS_Store" ]] && continue

  ln -sfnv $HOME/dotfiles/$file $HOME/$file
done

echo "Succeeded!"

