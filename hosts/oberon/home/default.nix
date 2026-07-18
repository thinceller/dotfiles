# oberon 専用の home-manager プロファイル。
#
# darwin の home-manager/ 集約 (programs/files/pkgs/services) は import しない:
# あちらは Homebrew / 1Password / cage / GUI アプリなど macOS 前提が多く、
# サーバーには不要な依存を持ち込むため。共有するのは設定 attrset ではなく
# 実ファイルのみ (herdr hooks / plugin、skills、user-memory.md、herdr config)。
{ pkgs, userConfig, ... }:
{
  imports = [
    ./herdr.nix
    ./claude-code.nix
    ./opencode.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDir;
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    jq
    fzf
    ripgrep
  ];

  # herdr の default_shell = "fish" (configs/.config/herdr/config.toml) と揃える。
  # darwin の fish モジュールは homebrew / op / cage 前提のため共有しない。
  programs.fish = {
    enable = true;
    shellInit = ''
      # opencode (OpenCode Go) の認証トークン。値は hermes と共用で、
      # sops (secrets/oberon.yaml の opencode-go-api-key) から供給される。
      # herdr が spawn する pane / 非対話シェルにも効くよう shellInit に置く。
      # secret 未配備でも壊れないよう readable ガード付き。
      if test -r /run/secrets/opencode-go-api-key
        set -gx OPENCODE_GO_API_KEY (cat /run/secrets/opencode-go-api-key)
      end
    '';
  };

  # 最小限の git。darwin 側の署名 (op-ssh-sign) や alias は持ち込まない。
  programs.git = {
    enable = true;
    userName = "thinceller";
    userEmail = "thinceller@gmail.com";
  };
}
