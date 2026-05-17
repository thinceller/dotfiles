# Sakura VPS + NixOS + Forgejo + Cloudflare Tunnel 構築の知見

`oberon` (Sakura VPS) 上に NixOS + Forgejo を構築し、Cloudflare Tunnel 越しに
公開する一連の作業で得た、ハマりやすいポイントと回避策のまとめ。

> 同じ構成を再現する場合は `docs/oberon-setup.html` (手順書) と併読してください。
> このドキュメントは「なぜそうするか」「何にハマるか」を中心に解説します。

## 目次

1. [Sakura VPS の特性](#1-sakura-vps-の特性)
2. [nixos-anywhere の罠](#2-nixos-anywhere-の罠)
3. [nixpkgs バージョン選択 (cache の貧富)](#3-nixpkgs-バージョン選択-cache-の貧富)
4. [sops-nix の使い分け](#4-sops-nix-の使い分け)
5. [Cloudflare Tunnel / Access の挙動](#5-cloudflare-tunnel--access-の挙動)
6. [NixOS deployment 戦略 (switch vs boot)](#6-nixos-deployment-戦略-switch-vs-boot)
7. [ブートローダーと disko](#7-ブートローダーと-disko)
8. [ネットワーク管理 (scripted vs systemd-networkd)](#8-ネットワーク管理-scripted-vs-systemd-networkd)
9. [Cloudflare Access x Git / ghq 連携の非対称性](#9-cloudflare-access-x-git--ghq-連携の非対称性)
10. [機密管理の chicken-and-egg](#10-機密管理の-chicken-and-egg)
11. [cloud-init が Sakura では使えない理由](#11-cloud-init-が-sakura-では使えない理由)
12. [復旧パターン (ブリック時の選択肢)](#12-復旧パターン-ブリック時の選択肢)
13. [プロジェクト workflow 的な教訓](#13-プロジェクト-workflow-的な教訓)
14. [VNC fallback とユーザー password の declarative 管理](#14-vnc-fallback-とユーザー-password-の-declarative-管理)
15. [on-server deploy workflow (経路系の変更用)](#15-on-server-deploy-workflow-経路系の変更用)

---

## 1. Sakura VPS の特性

Sakura VPS 固有の前提を知らずに NixOS の一般論で組むと必ず詰む。`hands-on` で
初めて分かる事項が多い。

### firmware は SeaBIOS (legacy BIOS)

UEFI ではない。`systemd-boot` で `bootctl install` は完走するが、reboot 後に
`Booting from Hard Disk...` でハングする。install ログに次の警告があれば確定:

```
Not booted with EFI or running in a container, skipping EFI variable modifications.
```

対処: **GRUB を BIOS モード** で使い、disko で **EF02 BIOS boot partition (1MiB)**
+ ext4 root を切る。詳細は [§7 ブートローダーと disko](#7-ブートローダーと-disko) を参照。

### DHCP 提供なし、静的 IP 構成

OS 側で IP / gateway / netmask / DNS を設定する運用。Sakura の Ubuntu イメージは
installer 時に値を直接書き込んでいるだけで、動的取得経路はない。

### cloud-init datasource が一切 attach されていない

検証コマンドで切り分けた結果:

| データソース | 状態 |
|---|---|
| ConfigDrive ISO (`/dev/sr0`) | 中身空 |
| HTTP IMDS (`169.254.169.254`) | timeout |
| NoCloud seed (`/var/lib/cloud/`) | 存在せず |
| DMI signature | `SAKURA internet Inc.` 程度で cloud-init が認識しない |

つまり Sakura では cloud-init は **原理的に使えない**。詳細は
[§11 cloud-init が Sakura では使えない理由](#11-cloud-init-が-sakura-では使えない理由) を参照。

### 2GB プランの tmpfs 制約

kexec installer は tmpfs ベースで `/tmp` も RAM 上にある。Go modules を展開する
ようなビルドが走ると即枯渇:

```
write /build/go/pkg/mod/.../*.go: no space left on device
```

回避: install フェーズに入る前に installer 上で `/mnt` (= 新規フォーマット済み
の実 disk) を `/tmp` に bind mount しておく:

```bash
ssh root@<VPS_IP>
mkdir -p /mnt/tmp
mount --bind /mnt/tmp /tmp
```

---

## 2. nixos-anywhere の罠

### `--build-on-remote` は deprecated

```
WARNING: --build-on-remote is deprecated, use --build-on remote instead
```

### 現行版は disko を必須化している

`config.system.build.diskoScript` を要求する。`--generate-hardware-config` だけ
では足りず、`hosts/<host>/disko.nix` で disko module を取り込んで disk layout を
宣言する必要がある。

```
error: flake '...' does not provide attribute '...diskoScript'
```

### Mac (aarch64-darwin) からはクロスビルド不可

`x86_64-linux` のクロージャを Mac で組もうとして詰まる:

```
error: Cannot build '...drv'.
       Reason: required system or feature not available
       Required system: 'x86_64-linux' with features {}
       Current system: 'aarch64-darwin' with features {...}
```

対処: `--build-on remote` で VPS 上でビルド。Mac は eval だけ担当。

### 失敗時の再走は `--phases` で省略可能

kexec が済んでいる installer に接続できるなら:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#<host> \
  --generate-hardware-config nixos-generate-config \
    ./hosts/<host>/hardware-configuration.nix \
  --build-on remote \
  --phases install,reboot \
  --target-host root@<VPS_IP>
```

`--phases install,reboot` で disko と kexec を skip。

### kexec 後は SSH ホスト鍵が変わる

```bash
ssh-keygen -R <VPS_IP>
```

を再走前に必ず実行。`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` で詰まる
ことを避ける。

---

## 3. nixpkgs バージョン選択 (cache の貧富)

### unstable は Hydra のキャッシュ追従が遅れることがある

`nixpkgs-unstable` の bleeding-edge コミットに対して、`glibc-locales` などの
common な derivation すらまだビルドされていない瞬間がある。その時に install を
始めると VPS 側で source build → 2GB RAM で OOM (`xz: Killed` / `tar: Unexpected EOF`):

```
> /nix/store/.../setup: line 1278:    12 Killed   XZ_OPT="--threads=$NIX_BUILD_CORES" xz -d < "$fn"
> tar: Unexpected EOF in archive
> tar: Error is not recoverable: exiting now
```

### 鉄則: VPS は stable channel を使う

flake.nix に Mac 用の unstable とは別の input を立てる:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";   # Mac 用
  nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11"; # VPS 用
};
```

NixOS host 側では `nixpkgs-stable` を `nixpkgs` としてエイリアス:

```nix
# hosts/<host>/default.nix
nixpkgs = inputs.nixpkgs-stable;
```

### `i18n.defaultLocale = "ja_JP.UTF-8"` も罠

`i18n.supportedLocales` のデフォルトは `defaultLocale` 派生 (C + en_US + defaultLocale)。
独自 default を入れると Hydra が build した glibc-locales (en_US 想定) とキャッシュキーが
ズレて必ず source build。**サーバ用途は `en_US.UTF-8` のまま**にして
timezone だけ `Asia/Tokyo` を当てるのが正解。

---

## 4. sops-nix の使い分け

### `format` の選択を間違えるとデコード不能

| format | 用途 | 中身 |
|---|---|---|
| `yaml` (default) | YAML 内の特定キーを取り出す | `sops.secrets."foo".sopsFile = ./bar.yaml` → bar.yaml の `foo` キー値 |
| `json` | 同上の JSON 版 | JSON 内の `<key>` を取り出す |
| `binary` | **ファイル全体を unwrap して書く** | sops エンベロープを剥がして元のバイト列を出力 |
| `ini` / `env` | ini/env 形式の特定キー | |

Cloudflare Tunnel credentials のような「JSON ファイル全体を service に渡したい」
ケースで `format = "json"` にすると、`the key 'cloudflared' cannot be found` 系の
エラーになる。**ファイル全体が欲しい時は `format = "binary"`**。

### `services.cloudflared` は NixOS 25.11 で DynamicUser 化

`services.cloudflared.user` / `services.cloudflared.group` は廃止オプション:

```
error: The option `services.cloudflared.group` can no longer be used since it's been removed.
       Cloudflared now uses a dynamic user, and this option no longer has any effect.
```

sops.secrets に owner/group を渡そうとすると上記エラー。systemd の `LoadCredential` が
root として読んで DynamicUser 側へ渡す機構が動いているので、**root:root 0400 で
そのまま OK**:

```nix
sops.secrets."cloudflared" = {
  sopsFile = ../../secrets/cloudflared.json;
  format = "binary";
  mode = "0400";
};
```

### systemd-networkd が読むファイルは権限が違う

`systemd-networkd` は `systemd-network` ユーザで動く。デフォルトの root:root 0400
で sops template を書くと:

```
systemd-networkd[xxx]: Failed to open /etc/systemd/network/10-host.network: Permission denied
```

→ 網絡 dead → cloudflared tunnel DOWN。**`systemd-network:systemd-network 0440`**:

```nix
sops.templates."10-host.network" = {
  content = ''...'';
  owner = "systemd-network";
  group = "systemd-network";
  mode = "0440";
};
```

### age 鍵は SSH ホスト鍵から on-the-fly に派生する

`sops.age.keyFile = "/var/lib/sops-nix/key.txt"` を明示すると実体ファイルが要求
されて activation が失敗する:

```
sops-install-secrets: cannot read keyfile '/var/lib/sops-nix/key.txt': open ... no such file or directory
```

**`sops.age.sshKeyPaths` のデフォルト `[/etc/ssh/ssh_host_ed25519_key]` で
on-the-fly 派生** するのが正常運用。共通モジュール側で sops 関連の Nix 設定は
**書かない (空) のが正解**。利用側 module (cloudflared.nix 等) が
`sops.secrets.<name>` を宣言するだけで動く。

### 再インストール後は age 鍵の再登録 + 全 secret 再暗号化

VPS を OS 再インストールすると SSH ホスト鍵が新規生成される → 派生する age
公開鍵が変わる → 既存の暗号化 secret は復号不能。手順:

```bash
# 新 age 公開鍵を取得
ssh-keyscan <VPS_IP> 2>/dev/null | nix run nixpkgs#ssh-to-age

# .sops.yaml の `&<host>` を更新

# 全 secret を再暗号化
sops updatekeys -y secrets/default.yaml
sops updatekeys -y secrets/cloudflared.json
sops updatekeys -y secrets/<host>-network.yaml
```

---

## 5. Cloudflare Tunnel / Access の挙動

### 「Tunnel HEALTHY」と「ingress が通る」は別レイヤ

`curl -sI https://forgejo.example.com` で `HTTP/2 302` が返っても、それは
**Cloudflare Access のログイン画面へのリダイレクト**で、origin (cloudflared
on VPS) に届いていない可能性がある。デバッグ時に騙されやすい。

切り分け:

- Cloudflare ダッシュボード → Networks → Tunnels → 該当 tunnel の Status が
  `HEALTHY` か `DOWN` か
- 個別 ingress (SSH と HTTPS) のうち片方だけ落ちることもある

### Access の Allow と Service Auth は別物

- **Allow**: 人間ユーザ向け。Identity Provider (メール OTP 等) で認証フロー
- **Service Auth**: 自動化用。`CF-Access-Client-Id` / `CF-Access-Client-Secret`
  HTTP ヘッダだけで通る

1 つの Self-hosted application に **両方の policy を別個に作って併設**するのが
「ブラウザは OTP、CLI は Service Token」のデュアル運用パターン。

### `cloudflared access login` の引数は positional URL

`--hostname` フラグは存在しない:

```bash
# 誤
cloudflared access login --hostname forgejo.example.com

# 正
cloudflared access login https://forgejo.example.com
```

### Service Token の Client Secret は発行直後しか見られない

Cloudflare ダッシュボードで発行画面を閉じたら二度と見られない。1Password 等に
即保存すること。万一漏れたら rotate (再発行) する。

### ダッシュボードの Public Hostname が local YAML config をオーバーライドする

`services.cloudflared.tunnels.<id>.ingress = {...}` を Nix で書いて
local YAML を生成しても、cloudflared は起動直後に **edge (Cloudflare ダッシュ
ボード) から remote configuration を pull して local YAML を上書きする**。
ダッシュボード側 Public Hostnames で routing 設定があるトンネルでは、Nix 側
ingress block は **dead code** となり一切反映されない。

journalctl で次のログが出る:

```
cloudflared[xxxx]: INF Updated to new configuration config="{...}" version=N
```

この config の中身 (JSON) が「ダッシュボードに登録された ingress」で、Nix YAML
の内容ではない。

#### 対処方針 (本 repo 採用)

Cloudflare 側 (DNS / Access policy / Public Hostname) は **すべてダッシュボード
で管理し、Nix では tunnel daemon の systemd 統合と credentialsFile のみ責任を
持つ**。一貫性のため `services.cloudflared.tunnels.<id>.ingress` は空にし、
`default = "http_status:404"` の catch-all のみ残す。

```nix
services.cloudflared.tunnels."<id>" = {
  credentialsFile = config.sops.secrets."cloudflared".path;
  # ingress は Cloudflare ダッシュボード (Networks → Tunnels → Public Hostnames)
  # で管理。Nix で書いても remote config に上書きされる。
  default = "http_status:404";  # cloudflared 必須の catch-all
};
```

ingress を残しておくと「ダッシュボードと Nix のどちらが正なのか」が後から
不明瞭になるので、明確に削除してコメントで意図を示す方が事故が少ない。

---

## 6. NixOS deployment 戦略 (switch vs boot)

### `nixos-rebuild switch` の落とし穴

在線で activation を当てるため、network / sshd / firewall のような「経路自身
を構成するサービス」を変更する場合に **SSH controlmaster が落ちて activation
が中断され、回復不能になる**ことがある。例:

```
nixos-rebuild ... --target-host oberon --build-host oberon --sudo
...
stopping the following units: network-addresses-ens3.service, ...
error: while running command with remote sudo, did you forget to use --ask-sudo-password?
Command 'ssh ... returned non-zero exit status 255.
```

その後 VPS に SSH/cloudflared で繋がらなくなる。

### `nixos-rebuild boot` + 手動 reboot が安全策

`boot` は **GRUB の次回 boot エントリのみ更新** し、在線で activation を当てない。

```bash
nixos-rebuild boot \
  --flake .#<host> \
  --target-host <host> \
  --build-host <host> \
  --sudo

ssh <host> sudo reboot
```

reboot 後に新世代がフレッシュに立ち上がる。在線の SSH セッションが切れる心配なし。
**network / sshd / firewall を触る deploy はこちら一択**。

### `--use-remote-sudo` は deprecated

```
nixos-rebuild: warning: --use-remote-sudo is deprecated, use --sudo instead
```

### remote sudo に password を要求される場合は `--ask-sudo-password`

`--sudo` だけだと systemd-run が非対話モードで sudo を呼ぶため、
`wheelNeedsPassword = true` 環境では即座に失敗:

```
error: while running command with remote sudo, did you forget to use --ask-sudo-password?
Command 'ssh ... returned non-zero exit status 255.
```

`--ask-sudo-password` を付けるとローカル端末で password 入力プロンプトが出る。
ただし password を毎回入れたくない場合は `security.sudo.wheelNeedsPassword = false`
を NixOS 側で設定する手も (oberon は採用済み)。

### switch-to-configuration が経路サービス restart で死ぬ根本メカニズム

cloudflared / sshd を restart する変更で `--target-host` deploy が exit 255
で落ちる原因の本質:

1. nixos-rebuild が SSH 経由で `sudo systemd-run --collect --pipe --service-type=exec ... switch-to-configuration switch` を起動
2. `--pipe` で systemd-run の stdin/stdout が SSH session と接続される
3. switch-to-configuration が cloudflared を stop → SSH 経路が切れる
4. SSH 切断で pipe が close → systemd-run の child (switch-to-configuration) に
   SIGPIPE が飛んで **新サービス起動前に死ぬ**
5. 結果: cloudflared / forgejo / その他停止したまま、新世代 activate 未完、
   `/run/current-system` symlink も未更新

`--collect` は unit metadata を保持するだけで child を生存させない。`--pipe` を
外せれば抑止できる可能性があるが、nixos-rebuild の内部実装なので外せない。

**現実的な対処**: 経路系の変更は (a) **`boot` + reboot** か (b) **on-server
deploy ([§15](#15-on-server-deploy-workflow-経路系の変更用))** を使う。`switch`
で `--target-host` は避ける。

---

## 7. ブートローダーと disko

SeaBIOS なので systemd-boot は使えない。GRUB + BIOS boot partition (EF02) の構成:

```nix
# hosts/<host>/disko.nix
disko.devices = {
  disk.vda = {
    device = "/dev/vda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          priority = 1;
          size = "1M";
          type = "EF02"; # BIOS boot partition
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
};
```

```nix
# hosts/<host>/configuration.nix
boot.loader.grub.enable = true;
# `boot.loader.grub.device` は disko が EF02 から自動設定する。
# こちらで device = "..." を書くと "mirroredBoots 重複" エラーになる。
```

### よくあるエラー

| エラー | 原因 |
|---|---|
| `You cannot have duplicated devices in mirroredBoots` | `boot.loader.grub.device` を手動指定したのに disko も同じ device を設定 |
| `Boot failed: Could not read from CDROM` → `Booting from Hard Disk...` でハング | systemd-boot で組んだが firmware が BIOS |

---

## 8. ネットワーク管理 (scripted vs systemd-networkd)

NixOS の networking は **scripted (デフォルト) と systemd-networkd が排他**。
両者を混在させると壊れる。

### scripted networking (`networking.useNetworkd = false`, デフォルト)

```nix
networking.interfaces.ens3.ipv4.addresses = [
  { address = "..."; prefixLength = 23; }
];
networking.defaultGateway = "...";
```

NixOS が `network-addresses-ens3.service` 等のスクリプト型 systemd unit を生成し、
`ip addr add` 系のコマンドで NIC を設定する。

### systemd-networkd (`networking.useNetworkd = true`)

```nix
networking.useNetworkd = true;
networking.useDHCP = false;

systemd.network.networks."10-host" = {
  matchConfig.Name = "ens3";
  address = [ "..." ];
  routes = [ { Gateway = "..."; } ];
  dns = [ "..." ];
};
```

NixOS は `/etc/systemd/network/10-host.network` を生成し、systemd-networkd が
読む。

### 在線で scripted → networkd 切替は危険

`nixos-rebuild switch` で切り替えると `network-addresses-ens3.service` を stop
した瞬間に NIC IP が剥がれ、networkd が立ち上がるまで網絡 dead。Mac 側 SSH
controlmaster が die して activation 中断 → bricked。

**[§6](#6-nixos-deployment-戦略-switch-vs-boot) の通り `boot` + 手動 reboot で
atomic 切替** すること。

### sops 暗号化された IP を networking.interfaces に渡せない

`networking.interfaces.X.ipv4.addresses` は eval 時に文字列が必要。sops は
boot 時 decrypt なので不可能。**systemd-networkd の `.network` ファイルを
sops.templates で生成し、`environment.etc."systemd/network/X".source` で
/etc/systemd/network/ に symlink** という構造が必須。

```nix
sops.templates."10-host.network" = {
  content = ''
    [Match]
    Name=ens3
    [Network]
    Address=${config.sops.placeholder.ipv4_address}/${config.sops.placeholder.ipv4_prefix}
    Gateway=${config.sops.placeholder.ipv4_gateway}
    DNS=${config.sops.placeholder.dns_v4_1}
  '';
  owner = "systemd-network";
  group = "systemd-network";
  mode = "0440";
};

environment.etc."systemd/network/10-host.network".source =
  config.sops.templates."10-host.network".path;
```

---

## 9. Cloudflare Access x Git / ghq 連携の非対称性

### git clone は extraHeader で通る

`http.<url>.extraHeader` を 2 行追加すれば git の HTTP transport が
`CF-Access-Client-Id` / `CF-Access-Client-Secret` ヘッダを毎回送る:

```ini
[http "https://forgejo.example.com/"]
  extraHeader = CF-Access-Client-Id: <CLIENT_ID>
  extraHeader = CF-Access-Client-Secret: <CLIENT_SECRET>
```

home-manager で `~/.gitconfig` を管理している場合、機密の Client Secret は
sops 暗号化された別ファイルに置いて `includeIf` で読ませる:

```nix
sops.secrets."cloudflare-access.gitconfig" = {
  sopsFile = ../../secrets/cloudflare-access.gitconfig;
  format = "binary";
  path = "${config.home.homeDirectory}/.config/git/cloudflare-access.gitconfig";
};

programs.git.settings.includeIf
  ."hasconfig:remote.*.url:https://forgejo.example.com/**".path =
  "${config.home.homeDirectory}/.config/git/cloudflare-access.gitconfig";
```

### ghq は素直に通らない

`ghq get` は VCS 自動検出のために **自前で HTTP GET → `<meta name="go-import">`
を見る** が、ここに extraHeader は乗らない。Cloudflare Access は認証なしの
リクエストにログイン画面 HTML を返し、ghq は go-import meta を見つけられず:

```
error failed to get "https://forgejo.example.com/foo/bar.git": unsupported VCS,
url=https://forgejo.example.com/foo/bar.git: no go-import meta tags detected
```

対処: ghq に「このドメインは検出スキップで git 固定」と教える:

```nix
programs.git.settings.ghq."https://forgejo.example.com".vcs = "git";
```

生成される `~/.config/git/config`:

```ini
[ghq "https://forgejo.example.com"]
  vcs = git
```

これで `ghq get URL` が直接 `git clone` を叩き、extraHeader が効く。1-shot で
回避するなら `ghq get --vcs=git URL`。

### `ssh-keygen -lf` で公開鍵ファイルの破損検知

Sakura パネルに登録する公開鍵が壊れていると認証永久失敗する。事前に検証:

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
# → "256 SHA256:... ED25519" が返れば OK
# → "is not a public key file" が返れば破損
```

破損していたら秘密鍵から再生成:

```bash
chmod 600 ~/.ssh/id_ed25519  # 0644 だと ssh-keygen が拒否する
ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
```

---

## 10. 機密管理の chicken-and-egg

VPS の SSH ホスト鍵から派生する age 鍵で暗号化された secret は、**その VPS が
boot 完了する前 = 初回 install 中はまだ host key が存在しないので decrypt 不能**。

特に network 設定を sops 化していると、初回 boot で /etc/systemd/network/X.network
が生成できず IP が当たらない → 詰む。

### 二段階 install パターン

1. **初回**: `hosts/<host>/network.nix` を **ハードコード値** で書く
   (sops を使わない `systemd.network.networks.<host>` 直書き)。
   ファイルは `.gitignore` した上で `git add -fN` で flake にだけ見せる
2. **install 完了 → SSH 接続 → 新 age 鍵を取得 → `.sops.yaml` 更新 →
   `sops updatekeys` で全 secret 再暗号化**
3. **network.nix を sops.templates 版に書き換え → `nixos-rebuild boot` +
   `ssh <host> sudo reboot`** で atomic 切替

### sops を使うかどうかの判断基準

- **origin IP / tunnel credentials / Service Token** などは secrets として
  扱うべき (sops 化)
- **interface 名 (`ens3`) / IPv6 link-local gateway (`fe80::1`)** は機密ではない
  ので Nix 直書き
- secrets/<host>-network.yaml は **そのホストの age 鍵だけ recipient** にする
  (他ホストでは復号不能にする) と最小権限。`.sops.yaml` で per-host
  `creation_rules` を分けて書く

---

## 11. cloud-init が Sakura では使えない理由

cloud-init は「VPS provider が提供する metadata source」を読んで網絡や SSH 鍵
を自動設定する仕組み。Sakura はこの datasource を一切提供していない。

検証用ワンライナー (VPS 上で):

```bash
echo "=== ConfigDrive ===" && lsblk -f | grep -E 'sr0|cidata|CONFIG-2'
echo "=== HTTP IMDS ==="
for ep in http://169.254.169.254/latest/meta-data/ \
          http://metadata.sakura.ad.jp/ \
          http://metadata/; do
  curl -m 3 -sS -o /dev/null -w "$ep: %{http_code}\n" "$ep" 2>&1
done
echo "=== NoCloud seed ===" && ls /var/lib/cloud/seed/ 2>/dev/null
echo "=== DMI ==="
sudo nix-shell -p dmidecode --run "dmidecode -s system-manufacturer; dmidecode -s bios-vendor"
echo "=== kernel cmdline ===" && cat /proc/cmdline
```

Sakura では全部 negative (ConfigDrive 空、HTTP IMDS timeout、NoCloud 不在、
DMI が `SAKURA internet Inc.` 程度で cloud-init recognize 不可、kernel cmdline
に `ds=...` 等のヒントなし)。

**結論**: Sakura では cloud-init 不可。**sops.templates 路線** が現実解。
他クラウド (AWS / GCP / Hetzner / Vultr / DigitalOcean) は IMDS が標準なので
cloud-init で network / hostname / SSH key 自動投入が効く。

---

## 12. 復旧パターン (ブリック時の選択肢)

### 1. cloudflared 経由 SSH が落ちただけ

```bash
# Access セッションを温め直し
cloudflared access login https://<host>.example.com

ssh <host> hostname
```

### 2. cloudflared そのものが落ちた / 設定 mismatch

- Cloudflare ダッシュボードで tunnel `DOWN` を確認
- VNC + 復旧モードでデバッグ ([§12.5](#5-vnc--init=binsh-経由) 参照)

### 3. 前世代に rollback

GRUB の **"NixOS - All configurations"** サブメニューに過去世代が並んでいる。
失敗 deploy 直後はここから前世代を選択して boot するのが一番安全。

> 注意: `nixos-rebuild boot` だけしてまだ reboot していない場合は、
> 単に次回 boot を最新世代にしただけで前世代は GRUB 上でまだ default。

### 4. 完全ブリック → Sakura OS 再インストール

Sakura パネルから Ubuntu 24.04 を再インストール → nixos-anywhere 再走。
30〜60 分で完全に元に戻せる。今回構成では age 鍵が変わるので、
[§4 sops-nix](#4-sops-nix-の使い分け) の「再インストール後の手順」を参照。

### 5. VNC + init=/bin/sh 経由

最終手段。Sakura パネルから VNC コンソールを開く → 強制再起動 → GRUB メニューで
`e` キー → kernel cmdline の `linux ...` 行末に半角スペース + `init=/bin/sh`
を追加 → Ctrl+X で boot。

ただし NixOS の stage-1 では PATH が `/no-such-path` で busybox / mount / passwd
すら見えないことが多い。bash builtin だけは生きているので:

```sh
# kernel sysrq で即時 reboot
echo b > /proc/sysrq-trigger
```

chroot で実 root に入って作業する場合:

```sh
# /mnt-root が実 root
mount -t proc proc /mnt-root/proc 2>/dev/null
mount --rbind /dev /mnt-root/dev 2>/dev/null
chroot /mnt-root /run/current-system/sw/bin/bash
# ここで PATH が通った root shell。passwd 等が使える
```

それも面倒なら **OS 再インストール (§12.4) が一番手っ取り早い**。

---

## 13. プロジェクト workflow 的な教訓

### 動作確認は段階的に

最初から「全部 declarative + 全部 sops + 全部 lockdown」を一気に通そうとすると、
どのレイヤで何が壊れたか切り分け不能になる。

**順序**:

1. **bootstrap モード (port 22 開放、scripted networking ハードコード値)** で
   install → 動作確認
2. age 鍵更新 + secrets 再暗号化 + cloudflared を起動 → 動作確認
3. network を sops.templates 化 → `nixos-rebuild boot` + reboot → 動作確認
4. 最後に `bootstrap = false` で lockdown → `boot` + reboot → 動作確認

### `bootstrap` toggle パターン

ロックダウン (sshd 127.0.0.1 + firewall 全閉) を Nix で declarative に書きつつ、
初期 provisioning 中は緩める仕組みとして:

```nix
{ lib, ... }:
let
  # 初回 install / 再構築時は true。動作確認後に false に切替えて再 deploy。
  bootstrap = true;
in
{
  networking.firewall.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = bootstrap;
    listenAddresses = lib.optionals (!bootstrap) [
      { addr = "127.0.0.1"; port = 22; }
    ];
  };
}
```

bootstrap=true / false の往復で迷子にならないよう、common module の冒頭に
**「切り替えタイミングのシーケンス」をコメントで書いておく** と未来の自分が助かる。

### deploy は最小単位・atomic で

複数のレイヤ (network + sshd + firewall) を 1 回の `switch` で変えると事故率が
高い。`boot` + `reboot` の atomic 切替で十分。time-to-recovery は短い。

### 検証の三点セット

- `nix flake check` (eval)
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run`
  (build 内容と cache hit/miss 確認)
- `nix eval --raw .#<config-path>` (実値の確認、特に sops.templates の path や
  systemd unit の serviceConfig)

これらをこまめに挟むと「思ってた挙動と違う」を早期に潰せる。

### コードレビューで漏れを拾う

origin IP の commit リスクのような、本人が気づきにくいセキュリティ漏れは
セルフレビューだと見落としやすい。LLM ベースのレビューでも、機械的にチェックして
くれる項目は素直に拾った方が良い。

### git 経由でなく VNC で復旧する場合のリアリティ

NixOS は declarative なので、ブリックしたら手元の dotfiles を編集して再 deploy
する流れになる。VNC で内部状態を見てもログとして読み取れる情報は限られ、
**結局再インストールが最速**ということもよくある。VNC 経由の作業は最小限に。

---

## 14. VNC fallback とユーザー password の declarative 管理

cloudflared tunnel が落ちると SSH (≒ 唯一の管理経路) も塞がる。lockdown 構成
では VPS provider の VNC コンソールが最後の救命路になるが、**VNC は password
入力 UI なので SSH 公開鍵では login できない**。

### 前提: declarative にユーザー password を持たせる必要がある

`users.users.<name>.openssh.authorizedKeys.keys` だけ設定して password 系を
何も書かないと、`/etc/shadow` のパスワード欄が `!` (locked) になり、SSH 鍵
ログインは可能だが **コンソール login は完全に拒否される**。VNC fallback として
無価値。

### `hashedPasswordFile` + sops + `neededForUsers = true` パターン

```nix
# hosts/<host>/users.nix
{ config, userConfig, ... }:
let
  secretName = "${userConfig.username}_hashed_password";
in
{
  sops.secrets.${secretName} = {
    sopsFile = ../../secrets/<host>.yaml;
    neededForUsers = true;  # ← 必須
  };

  users.users.${userConfig.username}.hashedPasswordFile =
    config.sops.secrets.${secretName}.path;

  users.mutableUsers = false;  # ← 既存ユーザーへ反映するため必須
}
```

- **`neededForUsers = true`**: sops-nix が users 作成タイミングより前に
  `/run/secrets-for-users/<name>` に展開する特例。これが無いと
  `hashedPasswordFile` を参照したタイミングでファイルが存在せず activation
  失敗する。
- **`users.mutableUsers = false` が肝**: 後述。

### `users.mutableUsers = true` だと既存ユーザーへ hashedPasswordFile が無視される

nixpkgs `nixos/modules/config/update-users-groups.pl` の shadow 書き込み分岐
(`# FIXME` 付き):

```perl
$sp_pwdp = "!" if !$spec->{mutableUsers};
$sp_pwdp = $u->{hashedPassword} if defined $u->{hashedPassword} && !$spec->{mutableUsers}; # FIXME
```

`mutableUsers = true` (default) では **既存ユーザーの shadow 行は activation
中に一切変更されない** (= 「手動 passwd を尊重する」設計)。`hashedPasswordFile`
はファイルから読まれるが shadow 反映の条件に `!$spec->{mutableUsers}` がある
ため利用されない。**新規ユーザー**には initial password として適用されるので
bootstrap 時は気付かない。

`mutableUsers = false` にすると毎 activation で `hashedPasswordFile` から
shadow を書き換える。これが declarative password 管理の正しい姿。

### password hash の生成

```bash
nix run nixpkgs#mkpasswd -- -m sha-512 -s
# プロンプトに同じ password を 2 回入力 → $6$xxx... の SHA-512 hash 出力
# 平文 password は 1Password 等に保管 (VNC で打ち込む用)
```

これを sops file の YAML key (`<username>_hashed_password` 等) に保存。

### 注意: `nixos-rebuild test` は使わない

[Issue #161072](https://github.com/NixOS/nixpkgs/issues/161072) (open, stale):
`mutableUsers = false` で `nixos-rebuild test` を走らせると root と user の
credentials が永続消失するバグあり。**必ず `switch` を使う**。

### root password は declarative には設定しない

`users.users.root.hashedPasswordFile = ...` を sops 経由で入れても、sops 復号
が壊れたら root も thinceller も同時に死ぬので fallback としての意味がない。
`security.sudo.wheelNeedsPassword = false` で wheel user (thinceller) が
`sudo -i` で root に上がれるので、それで足りる。

### 段階的フリップ手順 (`mutableUsers = true → false`)

既存稼働中の host で `mutableUsers = false` に切替えるときは事前確認重要:

1. ✅ VNC ログイン疎通 (= 既に shadow に valid hash がある)
2. ✅ 平文 password を 1Password 保管
3. ✅ `hashedPasswordFile` が sops eval で正しいパスに解決
4. ✅ `nix eval --raw .#nixosConfigurations.<host>.config.users.users.<username>.hashedPasswordFile`
5. ✅ GRUB に前世代が残っている (rollback 用)
6. ✅ `nixos-rebuild switch` で deploy (test ではない)

deploy 後 `sudo getent shadow <username> | cut -d: -f2 | head -c 4` で `$6$`
が表示されること、再度 `switch-to-configuration switch` を流して idempotent
であることを確認。

---

## 15. on-server deploy workflow (経路系の変更用)

[§6 deploy 戦略](#6-nixos-deployment-戦略-switch-vs-boot) で述べた通り、Mac
からの `nixos-rebuild --target-host` は cloudflared / sshd を含む変更で構造的
に失敗する (SSH 切断 → SIGPIPE → switch-to-configuration 中断)。

対策として **oberon 上で local に nixos-rebuild する** ワークフローを併用する。
Mac deploy と用途で使い分け:

| シナリオ | 推奨 deploy 方式 |
|---|---|
| forgejo, postgres, アプリ層の変更 | Mac から `--target-host` で `switch` (高速、SSH 切れない) |
| network, sshd, cloudflared, firewall の変更 | on-server `nixos-rebuild switch` (本セクション) または `--target-host` で `boot` + reboot |
| 初回 deploy / 復旧時 | nixos-anywhere もしくは on-server |

### 初回セットアップ (on-server)

```bash
# Mac → push to GitHub
git push origin master

# Oberon (SSH or VNC で)
git clone https://github.com/<user>/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
# sops 復号できることを確認 (oberon の age 鍵で復号可能なファイル)
sops -d secrets/oberon.yaml | head -5
```

### 通常 deploy フロー

```bash
# Mac で commit + push
git push origin master

# Oberon に SSH (or VNC) で入って
ssh oberon
cd ~/.dotfiles
git pull
sudo nixos-rebuild switch --flake .#oberon
```

local deploy なので switch-to-configuration の親プロセスが local shell。
cloudflared restart で SSH 経路が瞬断しても **switch-to-configuration 自体は
local 完結**で死なない。SSH session は瞬断後に reconnect (`ServerAliveInterval`
の挙動次第) されるか、再 ssh すればよい。

### Build キャッシュとパフォーマンス

oberon は 2GB RAM プランで大きな build は OOM 懸念。incremental な変更
(forgejo.nix の 1 行変更等) なら問題なく完走するが、major package upgrade
や glibc rebuild が走るような変更はキャッシュが効かないと厳しい。

対策:
- **cachix を購読** (本 repo は `thinceller-dotfiles.cachix.org` 経由で済む)
- 大規模 build は **Mac で build → oberon に copy → on-server activate**
  ```bash
  # Mac
  nixos-rebuild build --flake .#oberon --target-host oberon --build-host oberon
  # → oberon の nix store に system path が copy される
  # Oberon (or SSH 経由)
  sudo /nix/var/nix/profiles/system-NEW-link/bin/switch-to-configuration switch
  ```

### git remote の選択

dotfiles repo を Forgejo (= oberon 自身が host する) に置くと chicken-and-egg
になる (Forgejo が落ちたら on-server から pull できない)。**外部 (GitHub 等)
に remote を持つ** のが正解。本 repo は `git@github.com:thinceller/dotfiles.git`
を `origin` としている。

---

## まとめ

「Nix で declarative に全部書く」理想と、「provider 固有の制約 + 機密の
chicken-and-egg + 在線 deploy の中断リスク」現実をどう折り合わせるか、が
今回の中心テーマだった。

- **`bootstrap` toggle** で初期 provisioning と lockdown を 1 つの Nix flag で
  切り替える
- **sops.templates** で eval 時にはプレースホルダ、boot 時に decrypt → file
  生成、というレイジーな機密展開
- **`nixos-rebuild boot` + 手動 reboot** で network 変更を atomic に切替
- **ハードコードと sops 化の二段階移行** で chicken-and-egg を回避
- **stable channel + デフォルトロケール** でビルドキャッシュをフル活用
- **declarative ではない領域 (Cloudflare ダッシュボード / VNC password)** との
  境界線を明示し、混在による事故を避ける
- **on-server deploy** を経路系変更用の現実解として併用する

このパターンを次に Sakura VPS を追加する時、あるいは他の VPS provider に
適用する時に参照できるよう、本ドキュメントを残す。
