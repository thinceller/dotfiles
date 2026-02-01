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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    edgepkgs = {
      url = "github:natsukium/edgepkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    # dotenvx build failure workaround: https://github.com/NixOS/nixpkgs/issues/478005
    nixpkgs-dotenvx.url = "github:NixOS/nixpkgs/8198298755cad59b220641b8a76e372e27dc6471";
    # git-wt: pinned to a revision that includes git-wt 0.14.2
    nixpkgs-git-wt.url = "github:NixOS/nixpkgs/17a5fcf927843a8b80fa42f18f862a43ca9d1a7f";
    # 1password: pinned to nixpkgs HEAD for latest version (8.12.0)
    nixpkgs-1password.url = "github:NixOS/nixpkgs/043a781b82dff90b74f68cd5376d89cc29a5f6b5";
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
          "SC-N-843" = import ./hosts/SC-N-843 { inherit inputs; };
        };
      };
      perSystem =
        { config, pkgs, ... }:
        {
          apps = {
            update = {
              type = "app";
              program = "${pkgs.writeShellScriptBin "update" ''
                set -e
                echo "Updating flake inputs..."
                nix flake update
                echo "Executing nvfetcher..."
                nvfetcher
              ''}/bin/update";
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
              stylua.enable = true;
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
