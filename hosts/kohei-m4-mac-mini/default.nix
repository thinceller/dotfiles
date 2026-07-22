{ inputs }:
let
  inherit (inputs)
    self
    nixpkgs
    nix-darwin
    home-manager
    sops-nix
    edgepkgs
    nix-index-database
    gh-prism
    cage
    nixpkgs-codex
    hunk
    herdr
    ;
  system = "aarch64-darwin";
  userConfig =
    let
      username = "thinceller";
      homeDir = "/Users/${username}";
    in
    {
      inherit username homeDir system;
      uid = 501;
      hostname = "kohei-m4-mac-mini";
      dotfilesDir = homeDir + "/.dotfiles";
      isPersonal = true;
    };

  pkgs-codex = import nixpkgs-codex {
    inherit system;
  };

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      edgepkgs.overlays.default
      (_final: _prev: {
        cage = cage.packages.${system}.default;
        herdr = herdr.packages.${system}.default;
        # gpt-5.5 サポート (codex 0.123+) のため、locked nixpkgs が
        # 追いつくまで nixpkgs-codex から codex を上書き取得する。
        codex = pkgs-codex.codex;
      })
    ];
  };

  # Load the generated sources by nvfetcher
  sources = pkgs.callPackage ../../_sources/generated.nix { };
in
nix-darwin.lib.darwinSystem {
  inherit pkgs;
  specialArgs = {
    inherit self system userConfig;
  };
  modules = [
    ./darwin.nix
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [
        sops-nix.homeManagerModules.sops
        nix-index-database.homeModules.nix-index
        gh-prism.homeManagerModules.default
        hunk.homeManagerModules.default
      ];
      home-manager.extraSpecialArgs = {
        inherit
          userConfig
          sources
          ;
      };
      home-manager.users."${userConfig.username}" = import ./home.nix;
    }
  ];
}
