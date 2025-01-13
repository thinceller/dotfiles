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
      "ghostty"
      "google-chrome"
      "hammerspoon"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "microsoft-edge"
      "mtgto/macskk/macskk"
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
