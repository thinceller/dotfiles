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
      "azookey"
      "chatgpt"
      "chatgpt-atlas"
      "claude"
      "cursor"
      "figma"
      "firefox"
      "google-japanese-ime"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "logi-options+"
      "microsoft-edge"
      "notion"
      "orbstack"
      "raycast"
      "sequel-ace"
      "visual-studio-code"
      "wezterm"
      "zen"
    ];
  };
}
