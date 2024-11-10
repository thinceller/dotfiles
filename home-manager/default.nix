{ config, nixpkgs, system, wezterm-flake, ... }:
let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # Load the generated sources by nvfetcher
  sources = pkgs.callPackage ../_sources/generated.nix {};

  programs = import ./programs { inherit pkgs sources wezterm-flake; };
  files = import ./files.nix { inherit pkgs config; };
in {
  home.username = "thinceller";
  home.homeDirectory = "/Users/thinceller";

  home.sessionVariables = {
    EDITOR = "nvim";
    LANG = "ja_JP.UTF-8";
    LC_ALL = "ja_JP.UTF-8";
  };

  home.packages = with pkgs; [
    curl
    ghq
    graphviz
    mactop
    nix-search-cli
    nixfmt-rfc-style
    nvfetcher
    tig
    wget
    _1password-cli
  ];

  imports = programs ++ [files];

  home.stateVersion = "24.05";
}
