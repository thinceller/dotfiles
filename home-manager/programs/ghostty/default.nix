{ pkgs }:
{
  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      font-family = "HackGen Console NF";
      font-size = 14;
      window-padding-x = 8;
      window-padding-y = 8;
      background-opacity = 0.85;
      theme = "tokyonight";
      macos-option-as-alt = true;
    };
  };
}
