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
      "atok"
      "chatgpt"
      "discord"
      "firefox"
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "hhkb-studio"
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
      "wezterm"
      "zen-browser"
      "zoom"
    ];
  };
}
