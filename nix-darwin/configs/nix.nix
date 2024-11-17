{ pkgs, system, ... }:
{
  nix = {
    settings = {
      # Necessary for using flakes on this system.
      experimental-features = "nix-command flakes";
    };
    # package = pkgs.nix;
  };
  nixpkgs = {
    # The platform the configuration will be used on.
    hostPlatform = system;
  };
}
