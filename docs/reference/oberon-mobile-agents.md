# oberon モバイルエージェントコーディング (iPhone → SSH/mosh → herdr → claude/opencode)

iPhone から oberon に接続し、herdr の永続セッション内で claude (Claude Code) /
opencode を動かすための runbook。構成は以下:

- 経路: **Tailscale SSH** (主) + **mosh** (回線切替・スリープ耐性)。cloudflared は
  Mac からの fallback 専用 (スマホからは使わない)
- セッション永続: **herdr** (agent-aware terminal multiplexer)。SSH が切れても
  herdr サーバーがセッションを保持し、再接続後に `herdr` でアタッチし直す
- 実装: `hosts/oberon/home/` (home-manager プロファイル)、
  `hosts/oberon/tailscale.nix` (mosh)、`hosts/oberon/users.nix` (fish / sops)

## iPhone 初期セットアップ (一度だけ)

1. **Tailscale** アプリを App Store から入れ、Mac と同じ tailnet にログイン。
   VPN を ON にする (以後は必要時に自動接続)
2. **Blink Shell** を入れる (買い切り。mosh 対応がほぼ唯一の選択肢)。
   - Settings → Hosts → 新規: `oberon` / HostName `oberon` / User `thinceller`
   - 認証は **Tailscale SSH がサーバー側で処理**するため、クライアント側の
     SSH 鍵設定は不要 (tailnet 内であることが認証)
3. 接続テスト: Blink で `ssh oberon` → fish プロンプトが出れば成功

## 日常の使い方

```
mosh oberon        # 回線切替・ロック・アプリ kill に耐える接続
herdr              # 既存セッションにアタッチ (無ければ新規)
```

- herdr 内で pane を開いて `claude` や `opencode` を起動。サイドバーに
  blocked / working / done の状態が出る (キーバインドは Mac と同じ
  `configs/.config/herdr/config.toml` を共有: prefix `ctrl+j` 等)
- 電車で回線が切れても mosh が吸収する。mosh 自体が死んでも herdr セッションは
  生きているので、`mosh oberon` → `herdr` でそのまま復帰
- mosh が使えない環境 (UDP 不通) では素の `ssh oberon` でも herdr アタッチは同じ

## 認証

| ツール | 方式 | 備考 |
|---|---|---|
| claude | 初回のみ手動 `/login` | SSH で入って `claude` を起動し OAuth。状態は `~/.claude` に永続化 |
| opencode | `OPENCODE_GO_API_KEY` 環境変数のみ | sops (`secrets/oberon.yaml` の `opencode-go-api-key`) → fish shellInit で自動注入。**hermes と同じトークン**なのでローテーション時は `secrets/hermes.env` と両方更新する |

## 運用上の注意

- **メモリ**: oberon は 2GB RAM (+ zram + 4GiB swapfile)。forgejo / hermes-agent が
  常駐しているため、**claude / opencode の同時起動は 1 本まで**を目安にする。
  詰まったら `btm` で確認
- **herdr の更新規律**: Claude Code hook (`herdr-agent-state.sh`, v7) /
  OpenCode plugin (`herdr-agent-state.js`, v8) は upstream vendor。バージョンを
  bump するときは Mac 側 (brew) だけでなく、`nvfetcher` を実行して oberon 側の
  `herdr-bin` (static musl binary) も同時に更新する
- **herdr config の反映**: oberon の `~/.config/herdr/config.toml` は **store path
  symlink** (Mac の out-of-store と違う)。config を変えたら oberon の再 deploy が
  必要 (方式A: `nixos-rebuild switch --flake .#oberon --target-host oberon
  --build-host oberon`)
- **claude のバイナリ**: `pkgs.edge.claude-code-bin` (edgepkgs) を使用。もし
  NixOS 上で linker エラーが出る場合は、`hosts/oberon/home/claude-code.nix` で
  nixpkgs の `claude-code` にフォールバックする

## 初回デプロイ手順

```bash
# Mac で (herdr-bin の hash を確定させる — 初回必須)
nvfetcher                 # _sources/generated.nix を再生成
git add -A && git commit && git push

# deploy (方式A)
nixos-rebuild switch --flake .#oberon --target-host oberon --build-host oberon --sudo

# opencode トークンを sops に追加 (初回のみ。hermes.env の OPENCODE_GO_API_KEY と同じ値)
sops secrets/oberon.yaml   # opencode-go-api-key: <token> を追加 → 再 deploy

# oberon 上で claude の初回ログイン
ssh oberon
claude    # → /login で OAuth
```

## 検証チェックリスト

- [ ] `mosh oberon` が繋がり、Wi-Fi ↔ モバイル回線の切替でセッションが生存する
- [ ] `herdr --version` が動く (static binary: `ldd` が "not a dynamic executable")
- [ ] herdr で pane 作成 → SSH 切断 → 再接続 → `herdr` で復帰できる
- [ ] `claude --version` が動き、`/login` 後にセッションが開始できる
- [ ] herdr サイドバーに claude / opencode の状態 (working 等) が表示される
- [ ] `echo $OPENCODE_GO_API_KEY | head -c 4` が非空で、`opencode` が
      `opencode-go/glm-5.2` に応答する
