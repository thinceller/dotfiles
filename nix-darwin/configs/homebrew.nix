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
      "chatgpt"
      "claude"
      "cursor"
      "discord"
      "firefox"
      "ghostty"
      "google-chrome"
      "google-japanese-ime"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "logi-options+"
      "microsoft-edge"
      "nikitabobko/tap/aerospace"
      "notion"
      "notion-calendar"
      "orbstack"
      "raycast"
      "slack"
      "steam"
      "superwhisper"
      "tailscale"
      "visual-studio-code"
      "wezterm"
      "zen-browser"
      "zoom"
    ];
  };
}
