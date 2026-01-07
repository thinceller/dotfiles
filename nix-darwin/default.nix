{
  pkgs,
  self,
  system,
  userConfig,
  ...
}:
let
  inherit (userConfig) username hostname homeDir;

  fonts = import ./configs/fonts.nix { inherit pkgs; };
  homebrew = import ./configs/homebrew.nix;
  nix = import ./configs/nix.nix { inherit pkgs system; };
  systemSettings = import ./configs/system.nix { inherit self username; };
  services = import ./configs/services;
in
{
  ids.gids.nixbld = 350;

  # network configurations
  networking.computerName = hostname;
  networking.hostName = hostname;

  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
    pkgs.fish
  ];

  users.knownUsers = [ username ];
  users.users."${username}" = {
    uid = 501;
    home = homeDir;
    shell = pkgs.bashInteractive;
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Use Touch ID for sudo authentication.
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  imports = [
    fonts
    homebrew
    nix
    systemSettings
  ]
  ++ services;
}
