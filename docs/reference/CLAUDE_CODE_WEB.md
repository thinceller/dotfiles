# Claude Code on the web (クラウドセッション) マニュアル

このドキュメントでは、Claude Code on the web のクラウドセッションでこのリポジトリを検証する方法について説明します。

## 概要

Claude Code on the web のクラウドセッションは Ubuntu 24.04 (x86_64-linux) の VM 上で root として実行され、Nix がインストールされていません。このリポジトリでは、`.claude/settings.json` の SessionStart hook (`scripts/claude-cloud-session-start.sh`) が環境変数 `CLAUDE_CODE_REMOTE=true` を検知したときに `scripts/setup-claude-cloud.sh` を実行し、Nix (single-user インストール、flakes 有効) を自動でインストールします。初回セットアップは数分かかります。

## 推奨: 環境設定の Setup script で高速化

毎セッションのインストール待ちを避けるには、claude.ai/code の環境設定 (環境セレクタ → 設定アイコン) にある Setup script フィールドに以下を設定してください。初回セッションで filesystem スナップショットがキャッシュされ、以後のセッション開始が速くなります。

```bash
#!/bin/bash
curl -fsSL https://raw.githubusercontent.com/thinceller/dotfiles/master/scripts/setup-claude-cloud.sh | bash
```

キャッシュは約7日で失効するほか、Setup script や許可ドメインを変更した場合も再実行されます。

## ネットワークアクセス

デフォルトの Trusted ネットワークアクセスで動作します (`*.nixos.org`, github.com が allowlist に含まれるため)。Cachix (nix-community.cachix.org, thinceller-dotfiles.cachix.org) は allowlist 外のため使われず、cache.nixos.org からの取得とローカルビルドになります。必要であれば Custom ネットワークアクセスで `*.cachix.org` を追加してください。

## できること / できないこと

- darwin configuration のビルドは不可 (Linux VM のため)。`nix eval --raw .#darwinConfigurations.<host>.system.drvPath` での評価検証を使ってください
- `nixosConfigurations.oberon` (x86_64-linux) はビルド可能です (VM は 4 vCPU / 16 GB RAM / 30 GB disk)
- `nix fmt` は動作します (flake.nix の systems に x86_64-linux を追加済み)
- sops secrets の復号は不可です (age 鍵が無いため)。eval には影響しません
