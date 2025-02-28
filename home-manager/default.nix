{
  config,
  nixpkgs,
  lib,
  system,
  userConfig,
  ...
}:
let
  inherit (userConfig) username homeDir dotfilesDir;

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # Load the generated sources by nvfetcher
  sources = pkgs.callPackage ../_sources/generated.nix { };

  programs = import ./programs {
    inherit
      pkgs
      lib
      sources
      homeDir
      ;
  };
  files = import ./files.nix { inherit pkgs config dotfilesDir; };
in
{
  home.username = username;
  home.homeDirectory = homeDir;

  home.sessionVariables = {
    LANG = "ja_JP.UTF-8";
    LC_ALL = "ja_JP.UTF-8";
  };

  home.packages = with pkgs; [
    curl
    deno
    docker
    docker-credential-helpers
    ghq
    graphviz
    mactop
    nix-search-cli
    nixfmt-rfc-style
    nvfetcher
    tig
    uv
    wget
    _1password-cli
  ];

  imports = programs ++ [ files ];

  home.stateVersion = "24.05";
}
