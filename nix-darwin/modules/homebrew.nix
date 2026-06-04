{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
      # Homebrew の変更により `brew bundle install --cleanup` には
      # --force-cleanup 等の明示が必要になった
      # https://github.com/nix-darwin/nix-darwin/issues/1787
      extraFlags = [ "--force-cleanup" ];
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
      "linear"
      "logi-options+"
      "microsoft-edge"
      "nani"
      "obsidian"
      "orbstack"
      "raycast"
      "shottr"
      "thebrowsercompany-dia"
      "visual-studio-code"
      "wezterm"
      "zen"
    ];
  };
}
