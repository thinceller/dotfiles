{ pkgs, sources }:
let
  bat = import ./bat { inherit pkgs; };
  bottom = import ./bottom { inherit pkgs; };
  direnv = import ./direnv { inherit pkgs; };
  fish = import ./fish { inherit pkgs sources; };
  fzf = import ./fzf { inherit pkgs; };
  gh = import ./gh { inherit pkgs; };
  git = import ./git { inherit pkgs; };
  htop = import ./htop { inherit pkgs; };
  jq = import ./jq { inherit pkgs; };
  lsd = import ./lsd { inherit pkgs; };
  mise = import ./mise { inherit pkgs; };
  ripgrep = import ./ripgrep { inherit pkgs; };
  starship = import ./starship { inherit pkgs; };
  wezterm = import ./wezterm { inherit pkgs; };
in [
  bat
  bottom
  direnv
  fish
  fzf
  gh
  git
  htop
  jq
  lsd
  mise
  ripgrep
  starship
  wezterm
]
