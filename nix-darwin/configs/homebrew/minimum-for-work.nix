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
      "claude"
      "cursor"
      "discord"
      "firefox"
      "gather"
      "ghostty"
      "google-japanese-ime"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "logi-options+"
      "microsoft-edge"
      "notion"
      "notion-calendar"
      "orbstack"
      "raycast"
      "sequel-ace"
      "superwhisper"
      "visual-studio-code"
      "wezterm"
      "zen-browser"
    ];
  };
}
