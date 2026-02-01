{
  pkgs,
  ...
}:
let
  inherit (pkgs) brewCasks;
in
{
  home.packages = [
    brewCasks.cursor
    brewCasks.figma
    brewCasks.sequel-ace
  ];
}
