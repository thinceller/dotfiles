# mac-mini Deploy Methods

kohei-m4-mac-mini も oberon ([`oberon-deploy.md`](oberon-deploy.md)) と同じく
**comin による pull 型 GitOps** で deploy する。master へ push するだけで、
手元での操作は一切不要。

設定は [`hosts/kohei-m4-mac-mini/comin.nix`](../../hosts/kohei-m4-mac-mini/comin.nix)。

## 仕組み

1. master へ push
2. kohei-m4-mac-mini 上の comin (root の launchd daemon) が GitHub の master を
   60 秒間隔で polling し、新しい commit を検知
3. ローカルで `darwinConfigurations.kohei-m4-mac-mini` をビルド
   (CI が cachix `thinceller-dotfiles` に push した closure から substitute される)
4. `activate-user` → `activate` を直接呼んで適用 (root daemon なので sudo 不要)

`testing-kohei-m4-mac-mini` ブランチへの push は switch ではなく test (再起動で
消える一時適用) になる (comin のデフォルト挙動)。

## 状態確認

```bash
sudo launchctl list | grep comin
tail -f /var/log/comin.log
```

## 注意点

- nix-darwin の `activate-user` 削除 PR
  ([nix-darwin/nix-darwin#1825](https://github.com/nix-darwin/nix-darwin/pull/1825))
  がマージされた rev に flake.lock を上げると comin の darwin deploy が壊れる。
  nix-darwin を bump する PR ではここを確認する。
- home-manager の activation は `launchctl asuser` 経由なので、対象ユーザーが
  ログインしている前提 (常時ログインの Mac mini なら実質問題なし)。
- macOS の再起動要否は comin が検知しないので自分で判断する。
- macOS 再起動直後に `/nix/store` マウント前に daemon が起動して失敗する既知問題
  (comin PR [#121](https://github.com/nlewo/comin/pull/121) の修正は lock rev
  c32a4e4 に未収録) は launchd の KeepAlive で再起動されるので放置でよい。

## 手動 fallback

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles#kohei-m4-mac-mini
```

## 初回有効化

この変更を master に merge した後、一度だけ手動で `sudo darwin-rebuild switch`
して daemon を登録する (以後は自動)。
