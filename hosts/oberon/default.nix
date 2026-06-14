{ inputs }:
let
  inherit (inputs)
    self
    sops-nix
    disko
    edgepkgs
    hermes-agent
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
    hermes-agent.nixosModules.default
    ./disko.nix
    ./configuration.nix
  ];
}
