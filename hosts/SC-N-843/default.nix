{ inputs }:
let
  inherit (inputs)
    self
    nixpkgs
    nix-darwin
    home-manager
    wezterm-flake
    ;
  system = "aarch64-darwin";
  userConfig =
    let
      username = "kawakami.kohei";
      homeDir = "/Users/${username}";
    in
    {
      inherit username homeDir;
      uid = 502;
      hostname = "SC-N-843";
      dotfilesDir = homeDir + "/.dotfiles";
    };
in
nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit self system userConfig;
  };
  modules = [
    ../../nix-darwin/minimum-for-work.nix
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users."${userConfig.username}" =
        { config, lib, ... }:
        import ../../home-manager {
          inherit
            nixpkgs
            lib
            config
            wezterm-flake
            system
            userConfig
            ;
        };
    }
  ];
}
