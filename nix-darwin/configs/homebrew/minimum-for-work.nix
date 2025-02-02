{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # cleanup = "uninstall";
    };
    casks = [
      "1password"
      "aquaskk"
      "chatgpt"
      "cursor"
      "discord"
      "firefox"
      "ghostty"
      "hammerspoon"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "microsoft-edge"
      "mtgto/macskk/macskk"
      "ngrok/ngrok/ngrok"
      "raycast"
      "visual-studio-code"
      "wezterm"
      "zen-browser"
    ];
  };
}
