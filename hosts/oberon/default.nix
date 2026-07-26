{ inputs }:
let
  inherit (inputs)
    self
    sops-nix
    disko
    edgepkgs
    hermes-agent
    nix-index-database
    home-manager-stable
    gh-prism
    hunk
    herdr
    opencode
    ;
  # oberon は cache 安定性のため NixOS stable channel を使う (unstable ではない)。
  nixpkgs = inputs.nixpkgs-stable;
  system = "x86_64-linux";
  userConfig =
    let
      username = "thinceller";
      homeDir = "/home/${username}";
    in
    {
      inherit username homeDir system;
      hostname = "oberon";
      dotfilesDir = homeDir + "/.dotfiles";
      isPersonal = false;
    };

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      edgepkgs.overlays.default
      (_final: _prev: {
        herdr = herdr.packages.${system}.default;
        # opencode は上流 (anomalyco/opencode) HEAD をビルドして使う。
        opencode = opencode.packages.${system}.opencode;
      })
    ];
  };

  # Load the generated sources by nvfetcher (fish plugins 等で使用)
  sources = pkgs.callPackage ../../_sources/generated.nix { };
in
nixpkgs.lib.nixosSystem {
  inherit pkgs;
  specialArgs = {
    inherit self system userConfig;
  };
  modules = [
    sops-nix.nixosModules.sops
    disko.nixosModules.disko
    hermes-agent.nixosModules.default
    nix-index-database.nixosModules.nix-index
    ./disko.nix
    ./configuration.nix
    home-manager-stable.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [
        gh-prism.homeManagerModules.default
        hunk.homeManagerModules.default
      ];
      home-manager.extraSpecialArgs = {
        inherit userConfig sources;
      };
      home-manager.users."${userConfig.username}" = import ./home.nix;
    }
  ];
}
