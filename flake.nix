{
  description = "thinceller's nix configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    wezterm-flake = {
      url = "github:wez/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs, wezterm-flake }:
  let
    system = "aarch64-darwin";
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#kohei-m4-mac-mini
    darwinConfigurations."kohei-m4-mac-mini" = nix-darwin.lib.darwinSystem {
      modules = [
        ./nix-darwin
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.thinceller = { config, lib, ... }: import ./home-manager {
            inherit system nixpkgs config wezterm-flake;
          };
        }
      ];
      specialArgs = { inherit inputs; };
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."kohei-m4-mac-mini".pkgs;
  };
}
