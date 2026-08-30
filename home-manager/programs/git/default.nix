# darwin 専用の git 設定。portable 部分は common.nix にある。
{
  config,
  pkgs,
  userConfig,
  ...
}:
let
  inherit (userConfig) isPersonal;

  # Claude Code Remote Control でモバイル操作中は 1Password の鍵利用承認が押せず
  # 止まるため、個人 Mac では github.com 用に Secure Enclave 鍵で署名する。
  # /usr/bin/ssh-keygen を使うのは Apple 製 ssh-sk-helper と dylib の整合のため。
  sshSignSe = pkgs.writeShellScript "ssh-sign-se" ''
    export SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib
    exec /usr/bin/ssh-keygen "$@"
  '';
in
{
  imports = [ ./common.nix ];

  programs.gpg.enable = true;

  # Cloudflare Access (Forgejo CLI) の Service Token を含む git の include ファイルを
  # sops で暗号化して管理する。home-manager の activation で復号され、
  # ~/.config/git/cloudflare-access.gitconfig に symlink される。
  sops.secrets."cloudflare-access.gitconfig" = {
    sopsFile = ../../../secrets/cloudflare-access.gitconfig;
    format = "binary";
    path = "${config.home.homeDirectory}/.config/git/cloudflare-access.gitconfig";
  };

  programs.git = {
    signing = {
      format = "ssh";
      # 個人 Mac は Secure Enclave 鍵 (docs/reference/SECURE_ENCLAVE_SSH.md 参照)、
      # 仕事 Mac は既存の 1Password 管理鍵のまま。
      key =
        if isPersonal then
          "${config.home.homeDirectory}/.ssh/id_github_se"
        else
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQwsbXl/1tHIdW/f+fZE7TJArqzvmbbaUsdKRFPoyZB";
      signByDefault = true;
    };
    settings = {
      ghq = {
        # Cloudflare Access で保護された Forgejo は ghq の go-import 検出が通らない
        # (auth せずに HTTP GET すると Access のログイン HTML が返ってきて
        # <meta name="go-import"> が見えないため "unsupported VCS" エラーになる)。
        # URL prefix 別に vcs=git を明示して検出をスキップさせる。
        "https://forgejo.thinceller.dev".vcs = "git";
      };
      wt = {
        basedir = "./.git/wt";
        copy = [
          ".claude/settings.local.json"
        ];
      };
      gpg = {
        ssh = {
          # 個人 Mac は Secure Enclave 鍵での署名スクリプト、仕事 Mac は 1Password のまま。
          program =
            if isPersonal then "${sshSignSe}" else "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      # forgejo.thinceller.dev (Forgejo) は Cloudflare Access で保護されているので、
      # 該当ドメインを remote に持つリポジトリでのみ Service Token 用の
      # extraHeader を含むローカル設定ファイルを include する。
      # 実体は secrets/cloudflare-access.gitconfig (sops暗号化) を home-manager の
      # sops モジュールが activation で復号して配置している (上の sops.secrets 参照)。
      includeIf."hasconfig:remote.*.url:https://forgejo.thinceller.dev/**".path =
        "${config.home.homeDirectory}/.config/git/cloudflare-access.gitconfig";
    };
    ignores = [
      ".DS_Store"
    ];
  };
}
