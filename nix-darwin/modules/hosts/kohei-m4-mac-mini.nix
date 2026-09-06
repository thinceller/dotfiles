{
  userConfig,
  ...
}:
{
  ids.gids.nixbld = 350;

  # スマホから mosh で入るため。mosh client は `ssh <host> mosh-server new` を
  # 非対話で実行するが、ログインシェル (bash) の .bashrc は PATH を触らないので
  # sshd 既定の PATH のままで mosh-server が見つからない。sshd_config の SetEnv で
  # home-manager profile を足す (SetEnv は %u を展開しないためユーザー名を埋め込む)。
  services.openssh.extraConfig = ''
    SetEnv PATH=/etc/profiles/per-user/${userConfig.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin
  '';

  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  homebrew.casks = [
    "codex-app"
    "discord"
    "google-chrome"
    "obsidian"
    "readdle-spark"
    "slack"
    "steam"
    "tailscale-app"
    "zoom"
  ];
}
