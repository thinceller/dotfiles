{
  pkgs,
  system,
  ...
}:
{
  nix = {
    enable = true;
    settings = {
      experimental-features = "nix-command flakes";
    };
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
