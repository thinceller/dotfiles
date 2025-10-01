{
  config,
  nixpkgs,
  lib,
  system,
  userConfig,
  edgepkgs,
  mcp-servers-nix,
  ...
}:
let
  inherit (userConfig) username homeDir dotfilesDir;

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [ edgepkgs.overlays.default ];
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
      dotfilesDir
      mcp-servers-nix
      ;
  };
  files = import ./files.nix { inherit pkgs config dotfilesDir; };
  packages = import ./pkgs { inherit pkgs; };
  services = import ./services;
in
{
  home.username = username;
  home.homeDirectory = homeDir;

  home.sessionVariables = {
    LANG = "ja_JP.UTF-8";
    LC_ALL = "ja_JP.UTF-8";
  };

  sops = {
    defaultSopsFile = ../secrets/default.yaml;
    age = {
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    };

    secrets.test = { };
  };

  imports = programs ++ files ++ packages ++ services;

  home.stateVersion = "24.05";
}
