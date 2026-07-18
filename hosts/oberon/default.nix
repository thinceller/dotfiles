{ inputs }:
let
  inherit (inputs)
    self
    sops-nix
    disko
    edgepkgs
    hermes-agent
    nix-index-database
    home-manager
    ;
  # oberon は cache 安定性のため NixOS stable channel を使う (unstable ではない)。
  nixpkgs = inputs.nixpkgs-stable;
  system = "x86_64-linux";
  userConfig = {
    username = "thinceller";
    hostname = "oberon";
    inherit system;
    homeDir = "/home/thinceller";
    dotfilesDir = "/home/thinceller/.dotfiles";
    isPersonal = true;
  };

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      edgepkgs.overlays.default
    ];
  };

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
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      # HM-sops モジュールは入れない: oberon は system-level sops (/run/secrets/...)
      # で完結させ、user-scope の age 鍵を増やさない。
      home-manager.extraSpecialArgs = { inherit userConfig sources; };
      home-manager.users.${userConfig.username} = import ./home;
    }
    ./disko.nix
    ./configuration.nix
  ];
}
