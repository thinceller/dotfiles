{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    casks = [
      "1password"
      "arc"
      "aquaskk"
      "chatgpt"
      "cursor"
      "discord"
      "firefox"
      "gather"
      "ghostty"
      "hammerspoon"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "logi-options+"
      "microsoft-edge"
      "mtgto/macskk/macskk"
      "nikitabobko/tap/aerospace"
      "notion"
      "notion-calendar"
      "orbstack"
      "raycast"
      "visual-studio-code"
      "wezterm"
      "zen-browser"
    ];
  };
}
