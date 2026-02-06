{
  pkgs,
  system,
  userConfig,
  ...
}:
{
  nix = {
    enable = true;
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "root"
        userConfig.username
      ];
    };
    optimise.automatic = true;
    registry = {
      dev = {
        to = {
          type = "github";
          owner = "thinceller";
          repo = "flake-templates";
        };
      };
    };
    package = pkgs.nix;
  };
  nixpkgs = {
    hostPlatform = system;
    config.allowUnfree = true;
  };
}
