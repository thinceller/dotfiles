{ ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      # GUI アプリ (casks) は各アプリの自動更新に任せる。darwin-rebuild 中の
      # 更新は起動中のアプリを壊すことがある (dia で発生) ため upgrade しない。
      # brews の更新も手動 (`brew update && brew upgrade`) になる点に注意。
      autoUpdate = false;
      upgrade = false;
      # nix-darwin master (2026-06-17 以降) は cleanup = "uninstall" 時に
      # deprecated な --cleanup ではなく --force-cleanup を渡すようになった。
      cleanup = "uninstall";
    };
    # Homebrew 6.0 は HOMEBREW_REQUIRE_TAP_TRUST がデフォルト有効となり、非公式 tap は
    # `trusted: true` を Brewfile で明示しないと brew bundle install の cleanup フェーズ
    # (内部で brew cleanup を呼ぶ) が UntrustedTapError で exit 1 になる。
    taps = [
      {
        name = "k1LoW/tap";
        trusted = true;
      }
      {
        name = "nikitabobko/tap";
        trusted = true;
      }
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
      "claude"
      "firefox"
      "ghostty"
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
