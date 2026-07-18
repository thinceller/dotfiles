{ config, ... }:
{
  # Tailscale: admin SSH 経路を WireGuard 経由に分離する。
  # cloudflared (公開 HTTP) とは独立した経路。tailnet:22 は tailscaled が
  # Tailscale SSH として処理し、既存 sshd (127.0.0.1:22) とは衝突しない。
  sops.secrets."tailscale-authkey" = {
    sopsFile = ../../secrets/oberon.yaml;
    # mode は既定 0400。root が tailscaled の authKeyFile として読む。
  };

  services.tailscale = {
    enable = true;
    # 初回 up 時のみ使用。tag 付き auth key なのでノードは以後非失効。
    authKeyFile = config.sops.secrets."tailscale-authkey".path;
    # WireGuard 直結用 UDP 41641 を開放 (NAT 越え性能向上。閉じても DERP で動く)。
    openFirewall = true;
    # Tailscale SSH を有効化 + MagicDNS を受け入れる。
    extraUpFlags = [
      "--ssh"
      "--accept-dns=true"
    ];
  };

  # mosh: Tailscale (UDP が通る) 上で回線切替・スリープに強い接続を提供する。
  # スマホ (Blink Shell 等) からのモバイル接続で SSH 断の概念をほぼ消す。
  # UDP は tailscale0 インターフェイス限定で開け、firewall 全閉ポリシーを維持する。
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };
  networking.firewall.interfaces."tailscale0".allowedUDPPortRanges = [
    {
      from = 60000;
      to = 61000;
    }
  ];
}
