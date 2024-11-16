{ pkgs }:
{
  programs.direnv = {
    enable = true;
    config = {
      global.disable_stdin = true;
    };
    nix-direnv = {
      enable = true;
    };
  };
}
