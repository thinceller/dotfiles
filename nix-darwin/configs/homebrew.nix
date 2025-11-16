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
      "azookey"
      "chatgpt"
      "chatgpt-atlas"
      "claude"
      "craft"
      "cursor"
      "discord"
      "firefox"
      "google-chrome"
      "google-japanese-ime"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "logi-options+"
      "microsoft-edge"
      "notion"
      "notion-calendar"
      "obsidian"
      "orbstack"
      "raycast"
      "readdle-spark"
      "slack"
      "steam"
      "visual-studio-code"
      "zen"
      "zoom"
    ];
  };
}
