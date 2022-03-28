#!/usr/bin/env bash

set -eu

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"
DOTFILES="$(pwd)"

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

get_linkables() {
  find -H "$DOTFILES" -maxdepth 3 -name '.*'
}

setup_symlinks() {
  title "Creating symlinks"

  local backup_dir
  backup_dir="$HOME/.dotfiles_backup"
  mkdir -p "$backup_dir"
  info "Create backup dir: $backup_dir"

  for file in $(get_linkables) ; do
    local filename
    filename=$(basename "$file")
    [[ $filename == ".git" || \
      $filename == ".gitignore" || \
      $filename == ".config" || \
      $filename == ".dotfiles" ]] && continue

    info "Creating symlink for $file"
    if [[ -e "$HOME/$filename" ]]; then
      if [[ -L "$HOME/$filename" ]]; then
        rm -f "$HOME/$filename"
      else
        mv "$HOME/$filename" "$backup_dir"
      fi
    fi

    ln -s "$file" "$HOME/$filename"
  done

  echo -e
  info "installing to ~/.config"
  if [ ! -d "$HOME/.config" ]; then
    info "Creating ~/.config"
    mkdir -p "$HOME/.config"
  fi

  config_files=$(find "$DOTFILES/.config" -maxdepth 1 2>/dev/null)
  for config in $config_files; do
    local filename
    filename=$(basename "$config")
    [[ $filename == ".config" ]] && continue

    target="$HOME/.config/$(basename "$config")"

    info "Creating symlink for $config"
    if [ -e "$target" ]; then
      if [ -L "$target" ]; then
        rm -f "$target"
      else
        mv "$target" "$backup_dir"
      fi
    fi

    ln -s "$config" "$target"
  done
}

setup_homebrew() {
  title "Setting up Homebrew"

  if [ ! "$(command -v brew)" ]; then
    info "Homebrew not installed. Installing."
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
  fi

  if [ "$(uname)" == "Linux" ]; then
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
  fi

  brew bundle
}

setup_shell() {
  title "Configuring shell"

  [[ -n "$(command -v brew)" ]] && zsh_path="$(brew --prefix)/bin/zsh" || zsh_path="$(which zsh)"
  if ! grep "$zsh_path" /etc/shells; then
    info "adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells
  fi

  if [[ "$SHELL" != "$zsh_path" ]]; then
    chsh -s "$zsh_path"
    info "default shell changed to $zsh_path"
  fi
}

setup_vim_plug() {
  title "Setting up vim-plug"

  if [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim" ]; then
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  fi
}

setup_rust() {
  title "Setting up Rust"

  if [ ! "$(command -v rustup)" ]; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
  fi
}

case "${1-default}" in
  link)
    setup_symlinks
    ;;
  homebrew)
    setup_homebrew
    ;;
  shell)
    setup_shell
    ;;
  vim)
    setup_vim_plug
    ;;
  rust)
    setup_rust
    ;;
  all)
    setup_symlinks
    setup_homebrew
    setup_shell
    setup_rust
    setup_vim_plug
    ;;
  *)
    echo -e "\nUsage: $(basename "$0") {link|homebrew|shell|vim|rust|all}\n"
    exit 1
    ;;
esac

echo -e
success "Done."
