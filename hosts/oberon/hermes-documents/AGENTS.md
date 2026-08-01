# Hermes Agent on oberon (NixOS)

Hermes Agent は oberon 上で NixOS モジュール管理されています。
この AGENTS.md は workingDirectory である `/var/lib/hermes/workspace/` に配置され、
Hermes の system prompt に自動で注入されます。

## ワークスペース

- workingDirectory: `/var/lib/hermes/workspace`
- この配下にあるリポジトリ:
  - `thinceller.net/`
  - `dotfiles/`
  - `knowledge-base/`
- 各プロジェクトに対する実装作業の前には、そのプロジェクトルートの `AGENTS.md` または `CLAUDE.md` を読みます。

## プロファイル

- default: Planner / dispatcher 用
- worker: 実装専用 (`hermes -p worker`)

## プロジェクト別の規約

- `thinceller.net/AGENTS.md`: ブランチ名、コミットメッセージ、品質チェック、PR 手順
- `dotfiles/CLAUDE.md`: dotfiles リポジトリ作業中の一般的な規約、後わりに「Hermes Implementation Worker」セクションがある

## 注意

- `~/.hermes/` 以下の設定ファイルはできる限り dotfiles リポジトリによって NixOS / home-manager 管理されています。
- `.env` などの秘密情報は sops-nix によって管理されます。
