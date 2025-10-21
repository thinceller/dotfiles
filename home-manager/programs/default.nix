{
  config,
  pkgs,
  lib,
  sources,
  homeDir,
  dotfilesDir,
  mcp-servers-nix,
}:
let
  alacritty = import ./alacritty { inherit pkgs; };
  bat = import ./bat { inherit pkgs; };
  bottom = import ./bottom { inherit pkgs; };
  claude-code = import ./claude-code { inherit pkgs mcp-servers-nix; };
  clock-rs = import ./clock-rs { inherit pkgs; };
  delta = import ./delta { inherit pkgs; };
  direnv = import ./direnv { inherit pkgs; };
  fish = import ./fish {
    inherit
      pkgs
      lib
      sources
      homeDir
      config
      dotfilesDir
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
  tmux = import ./tmux { inherit pkgs; };
  wezterm = import ./wezterm { inherit pkgs; };
in
[
  alacritty
  bat
  bottom
  claude-code
  clock-rs
  delta
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
  tmux
  wezterm
]
