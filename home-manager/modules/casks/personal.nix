{
  pkgs,
  ...
}:
let
  inherit (pkgs) brewCasks;

  # ハッシュがないcasksのoverride用ヘルパー
  overrideHash =
    cask: hash:
    cask.overrideAttrs (oldAttrs: {
      src = pkgs.fetchurl {
        url = builtins.head oldAttrs.src.urls;
        inherit hash;
      };
    });

  google-chrome = overrideHash brewCasks.google-chrome "sha256-+1bfrMyoEnKTYUOpx19c20AAY/cOTN118wW9syu2IAE=";
  steam = overrideHash brewCasks.steam "sha256-X1VnDJGv02A6ihDYKhedqQdE/KmPAQZkeJHudA6oS6M=";
in
{
  home.packages = [
    brewCasks.antigravity
    brewCasks.discord
    google-chrome
    brewCasks.obsidian
    brewCasks.readdle-spark
    brewCasks.slack
    steam
    brewCasks.zoom
  ];
}
