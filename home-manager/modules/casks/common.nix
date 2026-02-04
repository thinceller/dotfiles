{
  pkgs,
  ...
}:
let
  inherit (pkgs) brewCasks;

  # ハッシュがないcasksのoverride用ヘルパー
  overrideHash =
    cask: hash:
    cask.overrideAttrs (oldAttrs: {
      src = pkgs.fetchurl {
        url = builtins.head oldAttrs.src.urls;
        inherit hash;
      };
    });

  # Claude Desktop用: バイナリを claude-desktop にリネーム（claude-codeとの競合回避）
  # postInstallはbrew-nixのカスタムinstallPhaseで呼び出されないため、postFixupを使用
  overrideClaudeDesktop =
    cask:
    cask.overrideAttrs (oldAttrs: {
      postFixup =
        let
          existingScript = oldAttrs.postFixup or "";
          renameScript = ''
            if [ -e "$out/bin/claude" ]; then
              mv "$out/bin/claude" "$out/bin/claude-desktop"
            fi
          '';
        in
        if existingScript == "" then renameScript else existingScript + "\n" + renameScript;
      meta = (oldAttrs.meta or { }) // {
        mainProgram = "claude-desktop";
      };
    });

  # ハッシュをoverrideしたcasks
  craft = overrideHash brewCasks.craft "sha256-Wj2lrMC4r5eQaki6ReTpdZPtdkdKRPVv00kT6wHhdn8=";
  google-chrome-beta =
    overrideHash brewCasks."google-chrome@beta"
      "sha256-8c1WMlyUUs4qLykVruU4lQivwLFIzf5h+SK3P6YBCtw=";

  # バイナリリネームしたcasks
  claude-desktop = overrideClaudeDesktop brewCasks.claude;
in
{
  # ============================================================
  # 除外cask一覧
  # 以下のcasksはbrew-nixで問題があるため、nix-darwinのhomebrew.casksで管理。
  # 設定: nix-darwin/modules/homebrew.nix
  # ============================================================
  #
  # azookey
  # - 理由: IMEとして認識されない（copyApps有効でも解決しない）
  #
  # hhkb-studio
  # - 理由: dmg/xar解析エラー（DMG内にPKGファイル、pbzx形式未対応）
  #
  # logi-options+
  # - 理由: ビルド失敗（インストーラスクリプト実行が必要）
  # ============================================================

  home.packages = [
    brewCasks.arc
    brewCasks.chatgpt
    brewCasks.chatgpt-atlas
    claude-desktop
    craft
    brewCasks.firefox
    google-chrome-beta
    brewCasks.jordanbaird-ice
    brewCasks.microsoft-edge
    brewCasks.nani
    brewCasks.notion
    brewCasks.raycast
    brewCasks.thebrowsercompany-dia
    brewCasks.visual-studio-code
    brewCasks.zen
  ];
}
