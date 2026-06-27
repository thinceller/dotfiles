# Forgejo バックアップ計画 (oberon)

> **Status**: 設計確定・実装未着手 (2026-06-27)。実装後に oberon-deploy.md からリンクする。

## 背景・狙い

`hosts/oberon/forgejo.nix` で動かしている Forgejo (PostgreSQL backend) のバックアップが
無い。oberon はさくらの VPS 1 台運用で、ディスク故障・誤操作・nixos-rebuild の事故などで
データが消えると復旧手段が無い。

**狙い**: Forgejo の repo / DB / 設定を定期的に取得し、oberon の外 (Cloudflare R2) に
暗号化して退避する。

要件:

- repo / LFS / attachments / app.ini / users / issues / PR をすべて含めて復元できること
- R2 が漏洩しても平文が出ないこと (クライアント側暗号化)
- 個人運用なので運用負荷は最小限。可能な限り NixOS 標準モジュールだけで構成する
- 失敗は通知で気づける。restore drill は定期化しない (必要時に手順を実行)

## 設計判断

| 論点 | 採用 | 理由 |
|---|---|---|
| バックアップ方式 | `services.forgejo.dump` + `services.postgresqlBackup` の 2 系統 | `forgejo dump` の DB ダンプには公式が言及している既知バグがある (再 inject 時の不整合)。PostgreSQL backend では `pg_dump` を別途取って「DB の正本」とするのが Forgejo 公式の推奨 ("belt-and-braces") |
| オフサイト先 | **Cloudflare R2 単独** | egress 無料で復元時の通信費が読める。`thinceller.dev` が既に Cloudflare 上にあり親和性高い。10GB 無料枠で当面まかなえる見込み |
| 転送ツール | restic (S3 backend) | 重複排除・クライアント側暗号化・宣言的な保持ポリシー (`--keep-*`) が揃う。NixOS は `services.restic.backups.<name>` で宣言可能 |
| 暗号化境界 | restic クライアント側 | R2 を信頼境界の外に置く。R2 token と restic password を別 secret にして片方漏洩でも被害を限定 |
| Forgejo 停止 | **しない (無停止 dump)** | 個人運用では point-in-time 完全整合性は過剰。dump 中の git push 競合は実害ほぼ無し。必要になれば後から `ExecStartPre=systemctl stop forgejo` を追加できる |
| 2 段階構成 | dump 生成と R2 送信を別 timer | 送信が落ちてもローカル dump は残る。oberon 内に dump があれば R2 を経由せず即時復元できる |
| 失敗監視 | `OnFailure=` で Slack 通知 (hermes-agent 既存経路) のみ | dead-man check や snapshot 内容検証は個人運用では過剰。restic は中身が空の snapshot を作らないので、unit 成功 = データあり、で実用上十分 |
| Restore drill | 定期化しない | 必要になった時に手順を実行する。自動化すると手順自体の劣化に気づけない |

## Architecture

```
oberon (NixOS)
│
├─ Stage 1: ローカル dump (2 系統を別 timer で取得)
│   ├─ services.forgejo.dump            ← repo + LFS + attachments + app.ini + DB(参考用)
│   │     /var/lib/forgejo/dump/forgejo-dump-<ts>.tar.zst  (age=4w)
│   └─ services.postgresqlBackup         ← DB の正本 (forgejo dump の DB バグ回避)
│         /var/backup/postgresql/forgejo.sql.zst
│
├─ Stage 2: オフサイト送信
│   └─ services.restic.backups.forgejo-r2
│         入力: /var/lib/forgejo/dump + /var/backup/postgresql
│         出力: s3:<r2-endpoint>/oberon-forgejo-backup
│         保持: --keep-daily 7 --keep-weekly 4 --keep-monthly 6
│
└─ Stage 3: 失敗通知
    └─ systemd OnFailure= Slack (hermes-agent 既存経路を流用)

Cloudflare R2
└─ bucket: oberon-forgejo-backup    ← R2 console で 1 回手動作成
   ├─ 認証: S3 互換 API token (このバケットへの read+write のみ)
   └─ 暗号化: restic 側でクライアント側暗号化 (R2 は復号鍵を持たない)
```

### スケジュール (oberon の TZ = JST)

| 時刻 | timer | 内容 | 出力先 |
|---|---|---|---|
| 03:00 | `forgejo-dump.timer` | `forgejo dump --type tar.zst` (無停止)。age=4w を超えた dump を自動削除 | `/var/lib/forgejo/dump/` |
| 03:30 | `postgresqlBackup-forgejo.timer` | `pg_dump forgejo` を zstd 圧縮 | `/var/backup/postgresql/forgejo.sql.zst` |
| 04:00 (+ random ≤15m) | `restic-backups-forgejo-r2.timer` | restic backup → R2、続けて `forget --prune` | R2 bucket |

順序の根拠:

- oberon は 2GB RAM。dump と pg_dump を 30 分ずらして IO/CPU 山を重ねない
- restic は dump 完了後に走る。仮に dump が 30 分超でも、restic は前回 dump も snapshot に含むので「1 日の差分が抜ける」だけで連続欠損はしない
- `RandomizedDelaySec=15m` で同時刻ジョブの集中を回避

### ボリューム見積もり (初期)

- repo 実体 + LFS + attachments: 100MB-1GB (個人用 git host の初期値)
- PostgreSQL: 数十 MB
- 初回 restic 転送 (圧縮・dedup 後): 100-500MB
- 1 日あたり差分: 数 MB-数十 MB
- R2 月額: ストレージ < 1GB × $0.015 ≒ **2-3 円/月** (10GB 無料枠の範囲内になる可能性が高い)
- snapshot 数の上限: 7 + 4 + 6 = **17 個** (重複排除済なので容量増分は微小)

## 事前準備 (手動・一度きり)

NixOS では宣言できない部分。

### 1. R2 bucket と API token

1. Cloudflare ダッシュボード → R2 → bucket 作成
   - 名前: `oberon-forgejo-backup`
   - 場所のヒント: APAC
2. R2 → Manage R2 API Tokens → Create API token
   - 権限: **Object Read & Write**
   - 対象 bucket: `oberon-forgejo-backup` のみ (全 bucket には絶対にしない)
   - 生成された `Access Key ID` / `Secret Access Key` / `endpoint URL` を控える
3. endpoint URL は `https://<account-id>.r2.cloudflarestorage.com` の形

### 2. restic password を生成

```bash
openssl rand -base64 48
```

生成された文字列を **1Password に必ず保管** (これを失うと R2 上のデータは復号不能)。

### 3. SOPS に secret を追加

```bash
sops secrets/oberon.yaml
```

エディタで以下を追記:

```yaml
restic-forgejo-password: <openssl で生成した文字列>
restic-forgejo-r2-env: |
  AWS_ACCESS_KEY_ID=<R2 token の Access Key ID>
  AWS_SECRET_ACCESS_KEY=<R2 token の Secret Access Key>
```

> 変数名が `AWS_*` なのは AWS への通信ではなく、restic の S3 backend (AWS SDK 流用) が
> 環境変数名を決め打ちで読むため。R2 が S3 互換 API を出していて、Cloudflare が「既存の
> S3 ツールをそのまま使えるよう」AWS と同じ変数名で受けることを意図している。

## 実装

### 新規ファイル: `hosts/oberon/forgejo-backup.nix`

```nix
{ config, pkgs, ... }:
{
  sops.secrets."restic-forgejo-password" = {
    sopsFile = ../../secrets/oberon.yaml;
    owner = "root";
    mode = "0400";
  };
  sops.secrets."restic-forgejo-r2-env" = {
    sopsFile = ../../secrets/oberon.yaml;
    owner = "root";
    mode = "0400";
  };

  # Stage 1a: forgejo dump (無停止)
  services.forgejo.dump = {
    enable = true;
    interval = "*-*-* 03:00:00";
    type = "tar.zst";
    backupDir = "/var/lib/forgejo/dump";
    # age はデフォルト 4w
  };

  # Stage 1b: PostgreSQL dump (DB の正本)
  services.postgresqlBackup = {
    enable = true;
    databases = [ "forgejo" ];
    location = "/var/backup/postgresql";
    startAt = "*-*-* 03:30:00";
    compression = "zstd";
  };

  # Stage 2: restic で R2 へ送信
  services.restic.backups.forgejo-r2 = {
    repository = "s3:https://<account-id>.r2.cloudflarestorage.com/oberon-forgejo-backup";
    passwordFile = config.sops.secrets."restic-forgejo-password".path;
    environmentFile = config.sops.secrets."restic-forgejo-r2-env".path;
    initialize = true;
    paths = [
      "/var/lib/forgejo/dump"
      "/var/backup/postgresql"
    ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };

  # Stage 3: 失敗通知 (具体実装は実装時に hermes-agent の経路を確認して埋める)
  # systemd.services."forgejo-dump".unitConfig.OnFailure = [ "..." ];
  # systemd.services."postgresqlBackup-forgejo".unitConfig.OnFailure = [ "..." ];
  # systemd.services."restic-backups-forgejo-r2".unitConfig.OnFailure = [ "..." ];
}
```

### `hosts/oberon/configuration.nix` の imports に追加

```nix
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./users.nix
    ./forgejo.nix
    ./forgejo-backup.nix      # ← 追加
    ./cloudflared.nix
    ./hermes-agent.nix
    ./tailscale.nix
    ../../nixos/modules/common.nix
  ];
```

## デプロイ手順

forgejo / postgres / sops のみを触る「アプリ層」変更 ([`oberon-deploy.md`](../reference/oberon-deploy.md) 方式 A 相当)。

```bash
# Mac 側 (.dotfiles)
git add hosts/oberon/forgejo-backup.nix hosts/oberon/configuration.nix secrets/oberon.yaml
git commit -m "feat(oberon): add Forgejo backup pipeline to Cloudflare R2"
git push origin master

# Tailscale 経由で deploy
nixos-rebuild switch \
  --flake .#oberon \
  --target-host oberon \
  --build-host oberon \
  --sudo --ask-sudo-password
```

## 受け入れテスト (デプロイ直後 1 回だけ)

```bash
# unit が登録されている
ssh oberon systemctl list-timers | grep -E 'forgejo-dump|postgresqlBackup|restic-backups-forgejo-r2'

# 各 backup を手動で 1 回回す
ssh oberon sudo systemctl start forgejo-dump.service
ssh oberon sudo systemctl start postgresqlBackup-forgejo.service
ssh oberon sudo systemctl start restic-backups-forgejo-r2.service

# ローカル dump の確認
ssh oberon ls -lh /var/lib/forgejo/dump /var/backup/postgresql

# R2 上の snapshot 確認 (1 件以上出れば OK)
ssh oberon sudo restic -r 's3:https://<account-id>.r2.cloudflarestorage.com/oberon-forgejo-backup' snapshots
```

## Restore 手順 (必要になった時に使う)

定期実行はしない。oberon が消し飛んだ場合も、特定リポジトリの巻き戻しも同じ手順。

```bash
# 1. R2 から最新 snapshot を取り出す
mkdir -p /tmp/forgejo-restore
sudo restic -r 's3:https://<account-id>.r2.cloudflarestorage.com/oberon-forgejo-backup' \
  --password-file /run/secrets/restic-forgejo-password \
  restore latest --target /tmp/forgejo-restore

# 2. forgejo を止めて、PostgreSQL に正本 dump を流す
sudo systemctl stop forgejo
sudo -u postgres dropdb forgejo
sudo -u postgres createdb -O forgejo forgejo
sudo -u postgres bash -c \
  'zstdcat /tmp/forgejo-restore/var/backup/postgresql/forgejo.sql.zst | psql forgejo'

# 3. repo / LFS / attachments を forgejo dump から展開
cd /var/lib/forgejo
sudo -u forgejo tar -xf /tmp/forgejo-restore/var/lib/forgejo/dump/forgejo-dump-*.tar.zst \
  --strip-components=1 repositories data custom

# 4. 起動して https://forgejo.thinceller.dev で確認
sudo systemctl start forgejo
```

oberon 全損 → 新 host への完全復旧の場合は、1 の前に nixos-anywhere で空の oberon を立てて
`nixos-rebuild switch` まで終わらせる。それ以降の手順は同じ。

`restic restore latest` の代わりに `--snapshot <id>` を指定すれば特定時点に戻せる。

## 障害時の挙動

| 障害 | 挙動 |
|---|---|
| R2 一時障害 | restic timer が failed → Slack 通知 → 翌日再試行。ローカル dump は最低 4 週間残るので当面復元可 |
| oberon ディスク満杯 | dump 失敗 → 通知。forget で自動掃除しているので恒常化は稀 |
| oberon 全損 | R2 から restore (上記 Restore 手順) |
| restic password 紛失 | **R2 上のデータは復号不能。1Password に必ず保管しておく** |
| R2 token 漏洩 | Cloudflare console で revoke → 新 token を SOPS に再 sync して `nixos-rebuild switch` |

## ロールバック

実装後に問題があれば、`hosts/oberon/configuration.nix` の imports から
`./forgejo-backup.nix` を外して再 deploy。timer が消えるだけで forgejo 本体には影響無し。
R2 bucket は手動で残るので、必要なら Cloudflare console から削除。

## チェックリスト

- [ ] Cloudflare R2 で `oberon-forgejo-backup` bucket を作成
- [ ] R2 API token (このバケットのみ Object Read & Write) を発行
- [ ] `openssl rand -base64 48` で restic password 生成、**1Password に保管**
- [ ] `sops secrets/oberon.yaml` に `restic-forgejo-password` / `restic-forgejo-r2-env` を追加
- [ ] `hosts/oberon/forgejo-backup.nix` 作成 (endpoint URL を埋める)
- [ ] `hosts/oberon/configuration.nix` の imports に追加
- [ ] `git add` (新規ファイルは flake が見えるよう必須) → commit → push
- [ ] `nixos-rebuild switch --target-host oberon`
- [ ] 受け入れテスト (各 unit を手動 start、R2 snapshot 確認)
- [ ] hermes-agent の Slack 通知経路を確認、`OnFailure=` の具体実装を埋めて再 deploy
- [ ] `docs/reference/oberon-deploy.md` に backup 経路の節を追記してリンクを張る
