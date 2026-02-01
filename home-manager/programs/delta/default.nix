{ pkgs, ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
