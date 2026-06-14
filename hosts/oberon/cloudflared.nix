{ config, ... }:
{
  # Cloudflare Tunnel credentials JSON は secrets/cloudflared.json (sops 暗号化済み)。
  # format = "binary" でファイル全体を unwrap して /run/secrets/cloudflared に書き出す。
  # (format = "json" は JSON 内の特定キーを取り出すモードなのでここでは不適切。)
  # NixOS 25.11 から services.cloudflared は DynamicUser のため user/group が指定不可。
  # systemd の LoadCredential 機構経由で読まれるので root:root 0400 で配置する。
  sops.secrets."cloudflared" = {
    sopsFile = ../../secrets/cloudflared.json;
    format = "binary";
    mode = "0400";
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "998f8ee3-075b-44db-a2f1-88351b8c17cd" = {
        credentialsFile = config.sops.secrets."cloudflared".path;
        # ingress は Cloudflare ダッシュボード (edge config) で管理する。
        # ここに書いても起動時に remote config で上書きされるため dead code になる。
        # 参照: docs/sakura-vps-nixos-lessons.md §5
        #
        # 現在の Public Hostnames (メモ):
        #   forgejo.thinceller.dev → http://localhost:3000
        #   hermes.thinceller.dev  → http://localhost:9119  (要ダッシュボード追加)
        #   oberon.thinceller.dev  → ssh://localhost:22
        ingress = { };
        default = "http_status:404";
      };
    };
  };
}
