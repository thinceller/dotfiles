{ pkgs }:
{
  programs.lsd = {
    enable = true;
    enableFishIntegration = true;
  };
}
