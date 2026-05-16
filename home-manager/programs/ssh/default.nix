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
    includes = [ "~/.orbstack/ssh/config" ];

    matchBlocks = {
      # VPS (cloudflared tunnel 経由)
      "oberon" = {
        hostname = "oberon.thinceller.dev";
        user = "thinceller";
        identityFile = "~/.ssh/id_ed25519";
        proxyCommand = "cloudflared access ssh --hostname %h";
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
}
