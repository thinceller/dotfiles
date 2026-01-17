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
      "figma"
      "firefox"
      "google-chrome@beta"
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
      "thebrowsercompany-dia"
      "visual-studio-code"
      "zen"
    ];
  };
}
