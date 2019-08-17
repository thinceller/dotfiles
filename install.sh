#!/bin/bash

cd $HOME

git clone 'https://github.com/thinceller/dotfiles.git' $HOME/dotfiles

cd dotfiles

bash setup.sh
