{ config, pkgs, ... }:
{
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
    enable = true;
    signing = {
      format = "ssh";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQwsbXl/1tHIdW/f+fZE7TJArqzvmbbaUsdKRFPoyZB";
      signByDefault = true;
    };
    settings = {
      alias = {
        pushf = "push --force-with-lease --force-if-includes";
      };
      user = {
        email = "thinceller@gmail.com";
        name = "thinceller";
      };
      core = {
        editor = "vim";
      };
      ghq = {
        # dotfiles (~/.dotfiles) も ghq list に載せるため root を複数指定する。
        # ghq 1.9.4 では git config の解決順 (last wins) で最後のエントリが
        # primary root (ghq get の clone 先) になるため ~/src を末尾に置く。
        root = [
          "~/.dotfiles"
          "~/src"
        ];
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
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      rebase = {
        autostash = true;
        autosquash = true;
      };
      pull = {
        rebase = true;
      };
      merge = {
        ff = false;
      };
      init = {
        defaultBranch = "main";
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
      ".claude/worktrees"
    ];
  };
}
