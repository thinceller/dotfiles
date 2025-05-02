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
      config
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
    age
    curl
    deno
    docker
    docker-credential-helpers
    ghq
    graphviz
    mactop
    nix-search-cli
    nixfmt-rfc-style
    nodejs_22
    nvfetcher
    sops
    tig
    uv
    wget
    _1password-cli
  ];

  sops = {
    defaultSopsFile = ../secrets/default.yaml;
    age = {
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    };

    secrets.test = { };
  };

  imports = programs ++ [ files ];

  home.stateVersion = "24.05";
}
