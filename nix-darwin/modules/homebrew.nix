{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:
let
  # Homebrew 6.x は brew bundle 実行時に taps の trust を要求し、trusted な tap 一覧を
  # ~/.homebrew/trust.json で管理する。darwin-rebuild の activation は非インタラクティブな
  # ため、ファイルが無い・古い・書き込めない場合 "Refusing to write insecure trust store" などで
  # 失敗する。`config.homebrew.taps` を単一の真実として、preActivation で実体ファイルを
  # ユーザー所有で書き出す (root が書いた後に chown する)。
  # nix-darwin の homebrew モジュールは入力文字列を `{ name, clone_target, ... }` の attrset
  # に正規化するため、`.name` を取り出して小文字化する (Homebrew の trust 比較は小文字基準)。
  trustJson = pkgs.writeText "homebrew-trust.json" (
    builtins.toJSON {
      trustedtaps = map (t: lib.toLower t.name) config.homebrew.taps;
    }
  );
in
{
  # brew bundle は home-manager activation よりも前に走るため、ここで trust.json を整える。
  # 旧構成では `home.file.".homebrew/trust.json"` が Nix store への symlink を作っており、
  # Homebrew 6.x が trust store を書き戻そうとして所有者チェックで停止していた。
  system.activationScripts.preActivation.text = ''
    TRUST_DIR="${userConfig.homeDir}/.homebrew"
    TRUST_FILE="$TRUST_DIR/trust.json"
    ${pkgs.coreutils}/bin/mkdir -p "$TRUST_DIR"
    # 旧構成で残った Nix store への symlink を実体ファイルに置き換える
    if [ -L "$TRUST_FILE" ]; then
      ${pkgs.coreutils}/bin/rm -f "$TRUST_FILE"
    fi
    ${pkgs.coreutils}/bin/install -m 0644 ${trustJson} "$TRUST_FILE"
    # root で配置するため、ユーザー所有に戻す (Homebrew は所有者チェックで非ユーザーを拒否)
    ${pkgs.coreutils}/bin/chown -R ${userConfig.username}:staff "$TRUST_DIR"
  '';

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
