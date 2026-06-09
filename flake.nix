{
  description = "thinceller's nix configurations";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://thinceller-dotfiles.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "thinceller-dotfiles.cachix.org-1:ygv46mR2J9KTVXN+c13mtokug8dwhYmuYdoXaAGKIBY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # NixOS サーバ (oberon) 用は cache hit 率の高い stable channel を使う。
    # unstable はビルドキャッシュが Hydra に追いつかないことがあり、
    # 2GB RAM の kexec installer 上で大きな build が走ると OOM するため。
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    edgepkgs = {
      url = "github:natsukium/edgepkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cage = {
      url = "github:Warashi/cage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gh-prism = {
      url = "github:kawarimidoll/gh-prism";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # codex 0.125.0 (gpt-5.5 サポート: 0.123 以降) を含む nixpkgs リビジョン。
    # cache.nixos.org にビルド済みの最新を選んでいる。
    # 通常の nixpkgs が追いついたら削除する。
    nixpkgs-codex.url = "github:NixOS/nixpkgs/0de8465d2b54";
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
        nixosConfigurations = {
          "oberon" = import ./hosts/oberon { inherit inputs; };
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
