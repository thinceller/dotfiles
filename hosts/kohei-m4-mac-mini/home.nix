{
  pkgs,
  ...
}:
{
  imports = [
    ../../home-manager/programs
    ../../home-manager/modules/common.nix
    ../../home-manager/modules/pkgs
    ../../home-manager/files.nix
    ../../home-manager/services
  ];

  home.packages = with pkgs; [
    codex
  ];
}
