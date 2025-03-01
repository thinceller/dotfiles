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
      "hammerspoon"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "logi-options+"
      "microsoft-edge"
      "mtgto/macskk/macskk"
      "nikitabobko/tap/aerospace"
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
