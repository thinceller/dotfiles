{ pkgs, system, ... }:
{
  nix = {
    enable = true;
    settings = {
      # Necessary for using flakes on this system.
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
    # The platform the configuration will be used on.
    hostPlatform = system;
  };
}
