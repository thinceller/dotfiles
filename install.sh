#!/usr/bin/env bash

set -eu

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
  echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
  echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
  echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
  exit 1
}

warning() {
  echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
  echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
  echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

setup_rust() {
  title "Setting up Rust"

  if test ! "$(command -v rustup)"; then
    # curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    curl https://sh.rustup.rs -sSf | sh -s -- -y
  fi

  source $HOME/.cargo/env

  if test ! "$(command -v dot)"; then
    info "Installing dot"
    cargo install --git https://github.com/ubnt-intrepid/dot.git
  fi
}

setup_homebrew() {
  title "Setting up Homebrew"

  if test ! "$(command -v brew)"; then
    info "Homebrew not installed. Installing."
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
  fi

  if [ "$(uname)" == "Linux" ]; then
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
  fi
}

setup_symlinks() {
  if test ! "$(command -v dot)"; then
    setup_rust
  fi

  info "Setting up symlinks"
  dot init thinceller/dotfiles
}

setup_rust
setup_homebrew
