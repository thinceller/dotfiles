{
  description = "thinceller's nix configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    wezterm-flake = {
      url = "github:wez/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, flake-parts, wezterm-flake }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
      ];
      flake = {
        darwinConfigurations = {
          "kohei-m4-mac-mini" = nix-darwin.lib.darwinSystem {
            modules = [
              ./nix-darwin
              home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.thinceller = { config, lib, ... }: import ./home-manager {
                  inherit nixpkgs config wezterm-flake;
                };
              }
            ];
            specialArgs = { inherit inputs; };
          };
        };
      };
      perSystem = {};
    };
}
