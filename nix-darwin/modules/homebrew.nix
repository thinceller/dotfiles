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
      "arto-app/tap"
    ];
    casks = [
      "arc"
      "arto"
      "azookey"
      "chatgpt"
      "chatgpt-atlas"
      "claude"
      "craft"
      "firefox"
      "google-chrome@beta"
      "hhkb-studio"
      "jordanbaird-ice"
      "karabiner-elements"
      "logi-options+"
      "microsoft-edge"
      "nani"
      "notion"
      "obsidian"
      "orbstack"
      "raycast"
      "thebrowsercompany-dia"
      "visual-studio-code"
      "zen"
    ];
  };
}
