# darwin 専用の git 設定。portable 部分は common.nix にある。
{ config, ... }:
{
  imports = [ ./common.nix ];

  programs.gpg.enable = true;

  # Secure Enclave に格納した SSH キーを git commit 署名に使う。
  # キーハンドルファイルは各 Mac で `sc_auth create-ctk-identity`
  # を使って生成する必要がある。
  home.file.".local/bin/ssh-sign" = {
    executable = true;
    text = ''
      #!/bin/sh
      export SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib
      exec /usr/bin/ssh-keygen "$@"
    '';
  };

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
      # Secure Enclave 内の SSH キーハンドルを指す。
      # 対応する公開鍵は ~/.ssh/id_github_se.pub に置く。
      key = "~/.ssh/id_github_se";
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
          program = "${config.home.homeDirectory}/.local/bin/ssh-sign";
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
