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
