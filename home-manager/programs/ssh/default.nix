{
  lib,
  pkgs,
  ...
}:
{
  programs.ssh = {
    enable = true;
    # `Host *` を完全に自前管理する (home-manager 既定の Host * は出力しない)。
    enableDefaultConfig = false;
    # orbstack が `~/.orbstack/ssh/config` を動的に管理するため、それを include するだけにする。
    # orbstack は初回のみ ~/.ssh/config に追記するため、home-manager 生成後の再追記は発生しない。
    # `~/.ssh/conf.d/*` は Nix 管理外のホスト設定 (機密情報を含むものや一時的なもの) を置く場所。
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/conf.d/*"
    ];

    matchBlocks = {
      # VPS (cloudflared tunnel 経由)
      "oberon" = {
        hostname = "oberon.thinceller.dev";
        user = "thinceller";
        identityFile = "~/.ssh/id_ed25519";
        proxyCommand = "cloudflared access ssh --hostname %h";
        serverAliveInterval = 60;
      };
      # Forgejo SSH clone: clone URL は git@forgejo.thinceller.dev だが
      # tunnel ingress は forgejo-ssh.thinceller.dev に分かれているため、
      # ProxyCommand で別 hostname に流す非対称構成。
      "forgejo.thinceller.dev" = {
        hostname = "forgejo.thinceller.dev";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        proxyCommand = "cloudflared access ssh --hostname forgejo-ssh.thinceller.dev";
        serverAliveInterval = 60;
      };
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # macOS 限定: 1Password の SSH agent を全ホストに適用。
      # `IdentityAgent` のパスに空白が含まれるため、ダブルクオートを値ごと出力する。
      "*".extraOptions.IdentityAgent =
        "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
    };
  };

  # `Include ~/.ssh/conf.d/*` の受け皿。ディレクトリが無いと毎回 ssh が
  # `No such file or directory` を stderr に吐くため、activation で用意しておく。
  # ssh は ~/.ssh とその配下を 700 でないと拒否するので、パーミッションも合わせる。
  home.activation.sshConfDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CONF_D="$HOME/.ssh/conf.d"
    if [ ! -d "$CONF_D" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$CONF_D"
    fi
    ${pkgs.coreutils}/bin/chmod 700 "$CONF_D"
  '';
}
