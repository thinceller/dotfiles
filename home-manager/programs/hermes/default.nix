{
  config,
  lib,
  userConfig,
  ...
}:
let
  hermesHome = "${config.home.homeDirectory}/.hermes";
  rootDir = "${hermesHome}/workspace/dot-hermes";
  symlink = config.lib.file.mkOutOfStoreSymlink;
in
lib.mkIf (userConfig.hostname == "kohei-m4-mac-mini") {
  # 本体は公式インストーラで導入する (upstream の Nix パッケージは pnpm 依存の
  # 固定ハッシュが aarch64-darwin で一致せずビルドできない)。
  # 設定の実体は private リポジトリ thinceller/dot-hermes の clone (rootDir) にある。
  # Hermes 自身が日常的に書き換えるので、public で自動 deploy される dotfiles に置くと
  # 意図しない diff と公開が問題になる。ここでは clone への symlink と secret の配置だけを持つ。
  # 手順は docs/reference/hermes-mac-mini.md を参照。
  home.file = {
    ".hermes/config.yaml".source = symlink "${rootDir}/config.yaml";
    ".hermes/SOUL.md".source = symlink "${rootDir}/SOUL.md";
    ".hermes/workspace/AGENTS.md".source = symlink "${rootDir}/workspace/AGENTS.md";
    ".hermes/plugins/session-vault-export".source = symlink "${rootDir}/plugins/session-vault-export";
  };

  sops.secrets."hermes-env" = {
    sopsFile = ../../../secrets/hermes-mac.env;
    format = "dotenv";
    path = "${hermesHome}/.env";
  };

  # thinceller-hermes (GitHub machine account) の SSH 秘密鍵。vault の clone に設定した
  # core.sshCommand が読む。個人の Secure Enclave 鍵は無人の push に使えないため分ける。
  # 鍵の実体は oberon と共有している (secrets/oberon.yaml)。oberon の Hermes を
  # 撤去するときに、このキーを消さないこと。
  sops.secrets."hermes-github-ssh-key" = {
    sopsFile = ../../../secrets/oberon.yaml;
    path = "${hermesHome}/github-ssh-key";
    mode = "0400";
  };
}
