{ inputs }:
let
  inherit (inputs) self nixpkgs nix-darwin home-manager wezterm-flake;
  system = "aarch64-darwin";
  username = "thinceller";
  hostname = "kohei-m4-mac-mini";
in
nix-darwin.lib.darwinSystem {
  specialArgs = { inherit self system username hostname; };
  modules = [
    ../../nix-darwin
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users."${username}" = { config, lib, ... }: import ../../home-manager {
        inherit nixpkgs config wezterm-flake system;
      };
    }
  ];
}
