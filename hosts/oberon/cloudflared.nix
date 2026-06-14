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

        # ingress / DNS / Access policy は Cloudflare ダッシュボードで管理する。
        # Nix で ingress を書いても、cloudflared が起動時に edge から remote
        # config を pull して local YAML をオーバーライドするため dead code に
        # なる (実例: 2026-05-17 の forgejo-ssh deploy で発覚)。
        #
        # ダッシュボードの場所:
        #   - Public Hostname (ingress): Cloudflare One → Networks → Tunnels
        #     → 998f8ee3-... → Public Hostnames タブ
        #   - DNS CNAME: Cloudflare → thinceller.dev zone → DNS → Records
        #   - Access policy: Cloudflare One → Access → Applications
        #
        # 現在の Public Hostnames (バックアップ目的の記録):
        #   - forgejo.thinceller.dev     → http://localhost:3000  (Forgejo Web/HTTPS clone)
        #   - forgejo-ssh.thinceller.dev → ssh://localhost:2222   (Forgejo built-in SSH)
        #   - oberon.thinceller.dev      → ssh://localhost:22     (管理 SSH)
        #   - hermes.thinceller.dev      → http://localhost:9119  (hermes-agent dashboard)
        #
        # default は cloudflared が ingress 配列に必ず要求する catch-all。
        ingress = { };
        default = "http_status:404";
      };
    };
  };
}
