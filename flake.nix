{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs }:
  let
    system = "aarch64-darwin";
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#kohei-macbook-air
    darwinConfigurations."kohei-macbook-air" = nix-darwin.lib.darwinSystem {
      modules = [
        ./nix-darwin
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.thinceller = { config, lib, ... }: import ./home-manager {
            inherit system nixpkgs config;
          };
        }
      ];
      specialArgs = { inherit inputs; };
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."kohei-macbook-air".pkgs;
  };
}
