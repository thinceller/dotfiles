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
      "k1LoW/tap"
      "manaflow-ai/cmux"
    ];
    brews = [
      "k1LoW/tap/tcmux"
    ];
    casks = [
      "1password"
      "arc"
      "arto-app/tap/arto"
      "azookey"
      "chatgpt"
      "chatgpt-atlas"
      "claude"
      "cmux"
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
