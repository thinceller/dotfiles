{ inputs }:
let
  inherit (inputs)
    self
    sops-nix
    disko
    edgepkgs
    nix-index-database
    ;
  # oberon は cache 安定性のため NixOS stable channel を使う (unstable ではない)。
  nixpkgs = inputs.nixpkgs-stable;
  system = "x86_64-linux";
  userConfig = {
    username = "thinceller";
    hostname = "oberon";
    inherit system;
  };

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [
      edgepkgs.overlays.default
    ];
  };
in
nixpkgs.lib.nixosSystem {
  inherit pkgs;
  specialArgs = {
    inherit self system userConfig;
  };
  modules = [
    sops-nix.nixosModules.sops
    disko.nixosModules.disko
    nix-index-database.nixosModules.nix-index
    ./disko.nix
    ./configuration.nix
  ];
}
