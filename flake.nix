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
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      git-hooks-nix,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
      ];
      imports = [
        git-hooks-nix.flakeModule
        treefmt-nix.flakeModule
      ];
      flake = {
        darwinConfigurations = {
          "kohei-m4-mac-mini" = import ./hosts/kohei-m4-mac-mini { inherit inputs; };
        };
      };
      perSystem =
        { config, pkgs, ... }:
        {
          apps = {
            update = {
              type = "app";
              program = pkgs.writeShellScriptBin "update" ''
                set -e
                echo "Updating flake inputs..."
                nix flake update
                echo "Executing nvfetcher..."
                nvfetcher
              '';
            };
          };

          pre-commit = {
            check.enable = true;
            settings = {
              src = ./.;
              hooks = {
                treefmt.enable = true;
              };
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              stylua = {
                enable = true;
                settings = {
                  indent_type = "Spaces";
                  indent_width = 2;
                };
              };
            };
            settings = {
              global = {
                excludes = [
                  "_sources/**"
                ];
              };
            };
          };

          devShells = {
            default = pkgs.mkShell {
              # see:
              # * https://github.com/numtide/treefmt-nix#flake-parts
              # * https://community.flake.parts/haskell-flake/devshell#composing-devshells
              inputsFrom = [
                config.pre-commit.devShell
                config.treefmt.build.devShell
              ];
            };
          };
        };
    };
}
