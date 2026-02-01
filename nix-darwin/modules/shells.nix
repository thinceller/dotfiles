{
  pkgs,
  ...
}:
{
  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
    pkgs.fish
  ];

  programs.zsh.enable = true;
  programs.fish.enable = true;
}
