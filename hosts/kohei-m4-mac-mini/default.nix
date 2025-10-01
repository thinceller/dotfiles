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
    ;
  system = "aarch64-darwin";
  userConfig =
    let
      username = "thinceller";
      homeDir = "/Users/${username}";
    in
    {
      inherit username homeDir;
      hostname = "kohei-m4-mac-mini";
      # このリポジトリをcloneして配置したディレクトリパス
      dotfilesDir = homeDir + "/.dotfiles";
    };
in
nix-darwin.lib.darwinSystem {
  specialArgs = {
    inherit self system userConfig;
  };
  modules = [
    ../../nix-darwin
    home-manager.darwinModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [
        sops-nix.homeManagerModules.sops
      ];
      home-manager.users."${userConfig.username}" =
        { config, lib, ... }:
        import ../../home-manager {
          inherit
            config
            nixpkgs
            lib
            system
            userConfig
            edgepkgs
            mcp-servers-nix
            ;
        };
    }
  ];
}
