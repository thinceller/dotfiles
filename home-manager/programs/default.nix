{
  config,
  pkgs,
  lib,
  sources,
  homeDir,
}:
let
  bat = import ./bat { inherit pkgs; };
  bottom = import ./bottom { inherit pkgs; };
  direnv = import ./direnv { inherit pkgs; };
  fish = import ./fish {
    inherit
      pkgs
      lib
      sources
      homeDir
      config
      ;
  };
  fzf = import ./fzf { inherit pkgs; };
  gh = import ./gh { inherit pkgs; };
  git = import ./git { inherit pkgs; };
  htop = import ./htop { inherit pkgs; };
  jq = import ./jq { inherit pkgs; };
  lazygit = import ./lazygit { inherit pkgs; };
  lsd = import ./lsd { inherit pkgs; };
  mise = import ./mise { inherit pkgs; };
  neovim = import ./neovim { inherit pkgs; };
  ripgrep = import ./ripgrep { inherit pkgs; };
in
[
  bat
  bottom
  direnv
  fish
  fzf
  gh
  git
  htop
  jq
  lazygit
  lsd
  mise
  neovim
  ripgrep
]
