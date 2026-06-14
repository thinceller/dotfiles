# Oberon Tailscale 導入計画 (admin SSH 経路の分離)

## 背景・狙い

oberon の admin SSH は現在 **Mac → Cloudflare edge → cloudflared → localhost:22** の経路しかない
(`home-manager/programs/ssh/default.nix` の `oberon` ブロック + `ProxyCommand cloudflared access ssh`)。
cloudflared の TCP 中継は対話 SSH のような長寿命接続に弱く、ネットワーク切替・Mac スリープ・
edge 側リセット・経路系 deploy 時のトンネル再起動で頻繁に切れる。cloudflared は本来
**公開 HTTP サービス向き**で、常用 admin シェルには不向き。

**狙い**: admin SSH を Tailscale (WireGuard) 経由に分離する。

- WireGuard はローミング・スリープに強く、接続断がほぼ無くなる
- **outbound 接続のみ・inbound ポート開放不要** (DERP relay 経由でも動く) なので
  現状の「firewall 全閉」ポリシー (`nixos/modules/common.nix` の `allowedTCPPorts = []`) と両立
- cloudflared は公開 Web (forgejo / hermes dashboard) 専用、Tailscale は admin、と役割分担
- cloudflared 経路はそのまま残すので **fallback** として機能 (Tailscale 故障時も到達可能)

> 関連: 切断対策の全体像は本リポジトリの過去検討 (SSH 切れ対策 3 レイヤー: keepalive+tmux /
> Tailscale / deploy-rs) のうち「本命」に当たる。deploy 方式は [`oberon-deploy.md`](oberon-deploy.md) 参照。

## 設計判断

| 論点 | 採用 | 理由 |
|---|---|---|
| SSH 認可方式 | **Tailscale SSH** (`tailscale up --ssh`) | SSH 鍵管理不要、tailnet identity + ACL で認可、監査可。tailnet:22 は tailscaled が処理し、既存 sshd (127.0.0.1:22) と非衝突 |
| 既存 sshd | **残す** | cloudflared + 127.0.0.1 経路を fallback として維持。Tailscale が死んでも cloudflared / VNC で到達可能 |
| firewall | `openFirewall = true` (UDP 41641 のみ) | 直結で低遅延。閉じても DERP relay で動くが、公開 IP の VPS なら直結が有利。開けるのは認証済み WireGuard 1 ポートのみ |
| auth key | **tag 付き** (`tag:server`) | tagged node は key expiry が無く、サーバが勝手に deauth されない。auth key は初回 `up` のみ使用 |
| node 認証の永続性 | tag により非失効 | 再起動・再 deploy でも再認証不要 |

## 事前準備 (Tailscale 管理コンソール、一度きり・手動)

NixOS では宣言できない部分。`https://login.tailscale.com/admin` で実施。

1. **tailnet 用意**: 既存アカウントの tailnet を使う (無ければ作成)。
2. **ACL / tag 定義**: Access Controls に最低限を追記。
   ```jsonc
   {
     "tagOwners": {
       "tag:server": ["autogroup:admin"]
     },
     "ssh": [
       {
         "action": "accept",
         "src": ["autogroup:member"],     // 自分のユーザー
         "dst": ["tag:server"],
         "users": ["thinceller", "autogroup:nonroot"]
       }
     ]
   }
   ```
   - `autogroup:nonroot` で root 以外を許可。root SSH が要るなら `"root"` を追加 (非推奨、sudo で十分)。
3. **auth key 発行**: Settings → Keys → Generate auth key。
   - **Reusable**: off で可 (1 ノード分)。再 provisioning するなら on。
   - **Tags**: `tag:server` を付与 ← これで非失効ノードになる。
   - **Ephemeral**: off (常駐サーバなので消えてはいけない)。
   - 生成された `tskey-auth-...` を次節で SOPS に保存。

## 手順 1: SOPS に auth key を登録

```bash
sops secrets/oberon.yaml
# エディタで以下を追記 (他の oberon secret と同じファイルに集約。secrets リネーム済み)
#   tailscale-authkey: tskey-auth-xxxxxxxxxxxx
```

`.sops.yaml` の `secrets/oberon.yaml` 向け creation rule は既存のまま (oberon の age 鍵が対象)
なので追加設定は不要。

## 手順 2: NixOS 側変更

### 新規ファイル `hosts/oberon/tailscale.nix`

```nix
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
}
```

### `hosts/oberon/configuration.nix` の imports に追加

```nix
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./users.nix
    ./forgejo.nix
    ./cloudflared.nix
    ./hermes-agent.nix
    ./tailscale.nix          # ← 追加
    ../../nixos/modules/common.nix
  ];
```

> 注意: `nixos/modules/common.nix` の firewall は全閉のままで良い。`services.tailscale.openFirewall`
> が UDP 41641 を別途開けるため、共通ポリシーを緩める必要は無い。sshd の bootstrap トグル
> (127.0.0.1 bind) もそのまま。Tailscale SSH は sshd とは別系統。

## 手順 3: Mac 側変更

### Homebrew cask 追加 (`nix-darwin/modules/homebrew.nix`)

```nix
  casks = [
    # ... 既存
    "tailscale"   # 標準アプリ (CLI + ネットワーク拡張 + MagicDNS)
  ];
```

`darwin-rebuild switch` 後に Tailscale.app を起動して同じ tailnet にログイン。

### SSH client 設定 (`home-manager/programs/ssh/default.nix`)

MagicDNS で `oberon` が tailnet IP に解決されるようになる。既存の cloudflared 経由を
fallback (`oberon-cf`) に退避し、`oberon` を Tailscale 主経路にする:

```nix
    settings = {
      # admin 主経路: Tailscale (MagicDNS で tailnet IP に解決)。
      # Tailscale SSH なので鍵認証は tailscaled が処理 (IdentityFile 不要だが害は無い)。
      "oberon" = {
        HostName = "oberon";            # MagicDNS short name (または oberon.<tailnet>.ts.net)
        User = "thinceller";
        ServerAliveInterval = 60;
      };
      # fallback: cloudflared 経由 (Tailscale 故障時 / 経路系 deploy 時)。
      "oberon-cf" = {
        HostName = "oberon.thinceller.dev";
        User = "thinceller";
        IdentityFile = "~/.ssh/id_ed25519";
        ProxyCommand = "cloudflared access ssh --hostname %h";
        ServerAliveInterval = 60;
      };
      # forgejo はそのまま (cloudflared 経由)
      "forgejo.thinceller.dev" = { /* 既存のまま */ };
    }
```

## 手順 4: デプロイ (デッドロック無し)

Tailscale 有効化は cloudflared / sshd / network interface を一切触らない「アプリ層」変更
([`oberon-deploy.md`](oberon-deploy.md) 方式 A 相当)。**既存の cloudflared 経路をそのまま使って 1 回 deploy**
すれば Tailscale が立ち上がる。swapfile 導入済み (commit `47e99d3`) なので on-server ビルドでも OOM しない。

```bash
# 変更を push
git add hosts/oberon/tailscale.nix hosts/oberon/configuration.nix
git commit -m "feat(oberon): add Tailscale for admin SSH"
git push origin master

# oberon で (cloudflared 経由 SSH、tmux 内推奨)
ssh oberon-cf   # まだ oberon=cloudflared なら ssh oberon
tmux new -s deploy
cd ~/.dotfiles && git pull origin master && sudo nixos-rebuild switch --flake .#oberon

# Mac 側も反映
sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
```

## 手順 5: 検証

```bash
# oberon 側: tailscaled が up し authority に認証されたか
tailscale status
tailscale ip -4            # tailnet IP が振られている

# Mac 側: MagicDNS で解決し、Tailscale SSH で入れるか
tailscale status | grep oberon
ssh oberon                 # ProxyCommand 無しで直接入れれば成功
#   → 入れたら `who` や `hostname` で oberon を確認

# Tailscale SSH 経由であることの確認 (sshd ログには出ない)
#   接続元が 100.x.x.x (tailnet) であること
```

合否: `ssh oberon` が cloudflared を介さず即接続でき、ネットワーク切替やスリープ後も
切れにくくなっていれば成功。

## 手順 6: ロールバック

Tailscale が原因で問題が出ても **cloudflared 経路は無傷**なので、`ssh oberon-cf` で常に入れる。

- 設定を戻す: `hosts/oberon/tailscale.nix` を imports から外して再 deploy (cloudflared 経由)
- ノードを deauth: 管理コンソール → Machines → oberon を削除
- 最終 fallback: Sakura VNC コンソール ([`sakura-vps-nixos-lessons.md`](sakura-vps-nixos-lessons.md) §14)

## 任意: mosh で更に堅牢化

Tailscale (UDP が通る) 上なら mosh が動く。スリープ・回線切替で接続断という概念がほぼ消える。

```nix
# hosts/oberon/tailscale.nix もしくは common.nix
programs.mosh = {
  enable = true;
  # mosh の UDP は tailscale0 インターフェイスに限定して開ける (全閉ポリシー維持)。
  openFirewall = false;
};
networking.firewall.interfaces."tailscale0".allowedUDPPortRanges = [
  { from = 60000; to = 61000; }
];
```

Mac には `mosh` を入れて `mosh oberon` で接続。

## チェックリスト

- [ ] Tailscale 管理コンソールで tag:server / ssh ACL を定義
- [ ] tag:server 付き auth key を発行
- [ ] `sops secrets/oberon.yaml` に `tailscale-authkey` を登録
- [ ] `hosts/oberon/tailscale.nix` 作成
- [ ] `hosts/oberon/configuration.nix` の imports に追加
- [ ] `nix-darwin/modules/homebrew.nix` に `tailscale` cask 追加
- [ ] `home-manager/programs/ssh/default.nix` の `oberon` / `oberon-cf` 整理
- [ ] `git add` (新規ファイルは flake が見えるよう必須) → commit → push
- [ ] oberon を cloudflared 経由 (tmux 内) で `nixos-rebuild switch`
- [ ] Mac を `darwin-rebuild switch`
- [ ] Mac で Tailscale.app ログイン
- [ ] `ssh oberon` が Tailscale 経由で繋がることを検証
- [ ] (任意) mosh 追加
