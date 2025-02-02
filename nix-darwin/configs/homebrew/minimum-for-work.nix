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
      "atok"
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
      "microsoft-edge"
      "mtgto/macskk/macskk"
      "ngrok/ngrok/ngrok"
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
