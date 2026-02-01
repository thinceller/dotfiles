{ inputs }:
let
  inherit (inputs)
    self
    nixpkgs
    nix-darwin
    home-manager
    sops-nix
    edgepkgs
    mcp-servers-nix
    brew-nix
    nixpkgs-dotenvx
    nixpkgs-git-wt
    nixpkgs-1password
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
    };

  pkgs-dotenvx = import nixpkgs-dotenvx {
    inherit system;
  };

  pkgs-git-wt = import nixpkgs-git-wt {
    inherit system;
  };

  pkgs-1password = import nixpkgs-1password {
    inherit system;
    config.allowUnfree = true;
  };

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      edgepkgs.overlays.default
      brew-nix.overlays.default
      (_final: _prev: {
        dotenvx = pkgs-dotenvx.dotenvx;
        git-wt = pkgs-git-wt.git-wt;
        _1password-gui-latest = pkgs-1password._1password-gui;
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
      ];
      home-manager.extraSpecialArgs = {
        inherit
          userConfig
          sources
          mcp-servers-nix
          ;
      };
      home-manager.users."${userConfig.username}" = import ./home.nix;
    }
  ];
}
