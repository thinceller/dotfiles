{
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  system = userConfig.system or "aarch64-darwin";
  isDarwin = lib.hasSuffix "darwin" system;
in
lib.mkIf isDarwin {
  home.packages = with pkgs; [
    appcleaner
    pinentry_mac
    terminal-notifier
  ];
}
