{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    taps = [
      "k1LoW/tap"
      "manaflow-ai/cmux"
      "nikitabobko/tap"
    ];
    brews = [
      "k1LoW/tap/mo"
      "k1LoW/tap/tcmux"
      "pinentry-mac"
      "vite-plus"
      {
        name = "node";
        link = false;
      }
    ];
    casks = [
      "1password"
      "aerospace"
      "alacritty"
      "appcleaner"
      "arc"
      "azookey"
      "chatgpt"
      "chatgpt-atlas"
      "claude"
      "cmux"
      "craft"
      "firefox"
      "ghostty"
      "google-chrome@beta"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "linear-linear"
      "logi-options+"
      "microsoft-edge"
      "nani"
      "obsidian"
      "orbstack"
      "raycast"
      "thebrowsercompany-dia"
      "visual-studio-code"
      "wezterm"
      "zen"
    ];
  };
}
