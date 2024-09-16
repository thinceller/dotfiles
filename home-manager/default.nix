{ config, nixpkgs, system, ... }:
let
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  programs = import ./programs { inherit pkgs; };
  files = import ./files.nix { inherit pkgs config; };
in {
  home.username = "thinceller";
  home.homeDirectory = "/Users/thinceller";

  home.sessionVariables = {
    LANG = "ja_JP.UTF-8";
    LC_ALL = "ja_JP.UTF-8";
  };

  home.packages = with pkgs; [
    curl
    ghq
    graphviz
    tig
    wget
    _1password
  ];

  imports = programs ++ [files];

  home.stateVersion = "24.05";
}
