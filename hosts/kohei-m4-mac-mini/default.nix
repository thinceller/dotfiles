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
    nix-index-database
    gh-prism
    cage
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

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      edgepkgs.overlays.default
      (_final: _prev: {
        cage = cage.packages.${system}.default;
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
        mcp-servers-nix.homeManagerModules.default
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
