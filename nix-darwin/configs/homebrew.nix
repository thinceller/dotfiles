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
      "chatgpt"
      "discord"
      "firefox"
      "google-chrome"
      "hammerspoon"
      "jordanbaird-ice"
      "karabiner-elements"
      "microsoft-edge"
      "notion"
      "notion-calendar"
      "orbstack"
      "raycast"
      "slack"
      "steam"
      "tailscale"
      "visual-studio-code"
      "zen-browser"
      "zoom"
    ];
  };
}
