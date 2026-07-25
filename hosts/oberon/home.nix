# oberon の home-manager 構成。Mac の hosts/*/home.nix と違い、
# darwin 依存モジュール (fish/git/claude-code/opencode) はサーバー版を import し、
# GUI / sops / vault 関連は含めない。
{
  config,
  pkgs,
  userConfig,
  ...
}:
let
  inherit (userConfig) dotfilesDir;
  rootDir = /. + dotfilesDir + /configs;
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [
    ../../home-manager/programs/bat
    ../../home-manager/programs/bottom
    ../../home-manager/programs/claude-code/server.nix
    ../../home-manager/programs/delta
    ../../home-manager/programs/direnv
    ../../home-manager/programs/fish/server.nix
    ../../home-manager/programs/fzf
    ../../home-manager/programs/gh
    ../../home-manager/programs/git/server.nix
    ../../home-manager/programs/htop
    ../../home-manager/programs/hunk
    ../../home-manager/programs/jq
    ../../home-manager/programs/lazygit
    ../../home-manager/programs/lsd
    ../../home-manager/programs/opencode/server.nix
    ../../home-manager/programs/ripgrep
  ];

  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDir;

  # oberon は glibc locale を en_US.UTF-8 しか生成していない
  # (nixos/modules/common.nix の defaultLocale 参照)。ja_JP を設定すると
  # locale エラーになるので en_US に固定する。
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
  };

  # HM input は master (nixpkgs unstable 追従) だが oberon の pkgs は
  # nixpkgs-stable。programs.claude-code / opencode の最新オプションを
  # Mac と揃えるために master を使うので、バージョン不一致警告を止める。
  home.enableNixpkgsReleaseCheck = false;

  home.packages = with pkgs; [
    ghq
    herdr
    # herdr-launch の editor タブが nvim を起動する。Mac の neovim module
    # (nvfetcher plugin 群) は重いので、まずは素の neovim を置く。
    neovim
  ];

  # herdr 設定 + プロジェクトランチャー (Mac と同じファイルを共有)。
  # out-of-store symlink の実体は on-server clone (/home/thinceller/.dotfiles)。
  home.file.".local/bin/herdr-launch" = {
    source = symlink /${rootDir}/bin/herdr-launch;
  };
  # 単一ファイル symlink にする理由: herdr は ~/.config/herdr/ 配下に
  # ログやローカル override を書くため (home-manager/files.nix と同じ)。
  xdg.configFile."herdr/config.toml" = {
    source = symlink /${rootDir}/.config/herdr/config.toml;
  };

  home.stateVersion = "25.11";
}
