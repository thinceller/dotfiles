#!/usr/bin/env bash
# Claude Code on the web のクラウド環境 (Ubuntu, root) に Nix をインストールする。
# 環境設定の Setup script と SessionStart hook の両方から呼ばれる (冪等)。
# 詳細: docs/reference/CLAUDE_CODE_WEB.md
set -euo pipefail

if command -v nix >/dev/null 2>&1 || [ -x "$HOME/.nix-profile/bin/nix" ]; then
  echo "Nix is already installed; skipping"
  exit 0
fi

# releases.nixos.org は Trusted ネットワーク allowlist (*.nixos.org) に含まれる
NIX_VERSION=2.28.3

installer=$(mktemp)
trap 'rm -f "$installer"' EXIT
curl -fsSL "https://releases.nixos.org/nix/nix-${NIX_VERSION}/install" -o "$installer"
# クラウド VM に systemd daemon は期待できないため single-user インストール
sh "$installer" --no-daemon --yes --no-channel-add

# flakes を有効化
mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
