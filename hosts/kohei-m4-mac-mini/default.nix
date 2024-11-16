{ inputs }:
let
  inherit (inputs) nixpkgs nix-darwin home-manager wezterm-flake;
  system = "aarch64-darwin";
in
nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs; };
  modules = [
    ../../nix-darwin
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.thinceller = { config, lib, ... }: import ../../home-manager {
        inherit nixpkgs config wezterm-flake;
      };
    }
  ];
}
