{
  pkgs,
  self,
  system,
  userConfig,
  ...
}:
let
  inherit (userConfig)
    username
    uid
    hostname
    homeDir
    ;

  fonts = import ./configs/fonts.nix { inherit pkgs; };
  homebrew = import ./configs/homebrew/minimum-for-work.nix;
  nix = import ./configs/nix.nix { inherit pkgs system; };
  services = import ./configs/services.nix;
  systemSettings = import ./configs/system.nix { inherit self; };
in
{
  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
    pkgs.fish
  ];

  users.knownUsers = [ username ];
  users.users."${username}" = {
    inherit uid;
    home = homeDir;
    shell = pkgs.fish;
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # Use Touch ID for sudo authentication.
  security.pam.enableSudoTouchIdAuth = true;

  imports = [
    fonts
    homebrew
    nix
    services
    systemSettings
  ];
}
