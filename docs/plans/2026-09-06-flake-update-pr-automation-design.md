# flake input / nvfetcher 更新 PR 自動化 設計

> **Status**: 設計承認済み・実装済み (2026-09-06)。Fable サブエージェントによる
> 設計レビューの指摘を反映済み。残りはユーザーの手作業: GitHub App の作成と登録
> (実装ステップ 1)、ruleset の required status checks 追加 (6)、E2E 確認 (8)。

**Goal:** `nix run .#update` → 手元で適用 → `update` commit を master に直 push、という
1〜2 日おきの手作業をやめ、更新対象 (flake input / nvfetcher source) ごとに独立した PR を
自動で作成・更新し続ける。CI (`build.yml`) で検証し、merge は人が行う。merge 後は comin が
各ホストへ deploy する。

## 決定事項

| 論点 | 決定 |
|------|------|
| PR の粒度 | 対象 (flake input 1 つ / nvfetcher source 1 つ) ごとに 1 PR。一括更新 PR は作らない |
| PR の重複 | 対象ごとにブランチ名を固定 (`update/<target>`)。open PR があれば更新、無ければ作成、差分が消えたら自動 close |
| 実装手段 | GitHub Actions の自作 workflow (`.github/workflows/update.yml`) + `peter-evans/create-pull-request` |
| Renovate | nix manager と lockFileMaintenance を無効化し、`github-actions` manager のみ残す。PR #34 / #37 は close |
| 手動編集の保護 | v1 では無し (後述)。手直しは bot PR を close して自分のブランチで行う |
| merge | 人が行う。自動 merge はしない |
| cadence | 毎日 (JST 朝) + master push トリガ + 手動起動。現状の手動更新 (1〜2 日おき) と同等の鮮度を保つ |
| PR 作成トークン | GitHub App (Contents: write, Pull requests: write のみ)。owner の PAT は ruleset の bypass 権限を持ち、漏洩すると master 直 push → comin が 60 秒で deploy する。App の installation token は 1 時間で失効し bypass できない。PR author が bot になるので owner が自分で approve できる |
| Renovate app | 存続。`enabledManagers: ["github-actions"]` に限定し、actions の version bump だけを任せる |

## 背景

### 現状の手動フロー

- `nix run .#update` = `nix flake update` + `nvfetcher`
- 手元の Mac で `darwin-rebuild switch` して動作確認
- `update` commit (flake.lock のみ) を master へ直 push。頻度は 1〜2 日おき
- CI は push / PR で darwin 2 台 + oberon をビルドし、closure を cachix `thinceller-dotfiles` に push。PR には nix-diff-action が差分をコメント

### Renovate で要件を満たせない理由 (調査済み)

Renovate (Mend hosted) は既に `nix` manager + daily `lockFileMaintenance` で有効だが、
2026-03 以降は実質機能していない (#34 は "PR Edited (Blocked)"、#37 は意図的に pin した
nix-darwin の digest 更新でノイズ)。ソース `lib/modules/manager/nix/extract.ts` の挙動:

- flake.nix の URL に commit rev がある input → digest 依存として **input 単位の PR** を出す
- rev が無い input (`github:owner/repo` / `github:owner/repo/<branch>`) → `lockedVersion` のみ記録され、
  **全 input 一括の lockFileMaintenance でしか更新されない**。`packageRules` で変える手段は無い
- 全 input を sha 固定にすれば個別 PR にできるが、nix の `github:` スキームは ref と rev の同時指定を
  拒否するため、ブランチ追従の nixpkgs / nixpkgs-stable / home-manager-stable は固定できない。
  また sha 固定すると手元の `nix flake update` がその input を動かさなくなる
- nvfetcher (`_sources/generated.nix`) は対象外。`postUpgradeTasks` は self-hosted 限定

### 要件

1. input ごとに独立した PR。壊れた input の PR が他の merge を妨げない
2. 対象ごとに open PR は常に 1 本。既存 PR があれば更新する
3. 特定の input だけをオンデマンドで更新できる (例: hermes-agent だけ)

## 全体像

```
schedule (毎日) / workflow_dispatch (target 指定可) / push: master (paths: flake.lock, _sources/**)
  │  concurrency: group=update, cancel-in-progress=false (直列化)
  ├─ job enumerate (ubuntu)
  │     flake.lock の root inputs から pin 済みを除外 + nvfetcher.toml の source 名 → matrix
  │     dispatch の target は列挙結果と突合し、無ければ fail
  └─ job update (ubuntu, matrix per target, fail-fast: false, max-parallel: 4)
        1. master を checkout、Nix install (DeterminateSystems/nix-installer-action)、cachix (pull)
        2. `nix flake update <input>` または `nvfetcher -f '^<name>$'`
        3. 変更ファイルが期待通り (flake.lock のみ / _sources/** + 対象 .nix のみ) か assert
        4. (tcmux のみ) `nix build .#tcmux` → hash mismatch なら stderr の `got:` を vendorHash に書き戻す
        5. `nix flake update` の "Updated input" 行を PR 本文に載せる
        6. create-pull-request: branch=update/<target>, delete-branch=true, App token,
           commit "chore(deps): update <target>"
             ↓
build.yml が PR で起動 (darwin × 2 build + oberon build + nix-diff コメント)
             ↓
owner が diff を確認して merge → comin が oberon (将来 Mac も) へ deploy
```

### create-pull-request の固定ブランチ挙動 (要件 2 の根拠)

README "Action behaviour" より:

- 差分があれば `branch` に push して PR 作成
- 差分が無ければ何もせず終了
- PR が既にあれば必要に応じて更新 (workspace の変更・base の変更で更新される)
- base が追いついて差分が消えたら PR を自動 close。`delete-branch: true` でブランチも削除

毎回 master から作り直して force push するため、PR は常に「master + その対象の最新化」1 commit になる。

### 対象の列挙

- flake input: `flake.lock` の `.nodes.root.inputs | keys`。commit / tag 固定の input
  (nix-darwin, nixpkgs-codex, nixpkgs-gh, hermes-agent) は `nix flake update` しても差分ゼロで
  job を無駄に消費するので除外リストで弾く。短縮 rev は lock 上 `ref` として入るため、
  `original.rev` の有無だけでは判定できない (除外は手書きで持つ)
- nvfetcher: `nvfetcher.toml` の `[name]` セクション
- flake.nix から input を消しても既存 PR は自動 close されない (列挙されなくなるだけ)。手動 close する
- pin を外したときは `update.yml` の `pinned` リストからも外す必要がある (名前で除外しているため、
  外し忘れるとその input の PR が永久に出ない)

### 手動編集の保護を v1 で入れない理由

「open PR に bot 以外の author の commit があれば skip」を検討したが、create-pull-request の
`author` 既定値は `github.actor` (= workflow を最後に触った owner) で、schedule 実行でも owner が
author になるため全 PR が手動編集扱いになる。`author` を明示しても "Update branch" ボタンの
merge commit が owner author になり永久 skip する罠が残る。

代わりに以下の運用とする。

- 手直しが必要なら bot PR を close し、自分のブランチで直して PR を出す
- 特定の更新を拒否したいなら flake.nix で pin する (→ 以後は差分ゼロで PR が出ない)。
  close しただけでは次回再作成される
- 凍結が必要になったら `hold` ラベルを見て skip する 1 行を足す

### conflict 戦略

全 PR が flake.lock を触るため、1 本 merge すると残りは conflict で Merge ボタンが無効になる。
schedule だけだと最大 3〜4 日 merge 不能になるので、`push: master` (paths: flake.lock, `_sources/**`)
でも起動して master から作り直す。create-pull-request は差分が変わったブランチだけ push するので、
再ビルドは open PR 分のみ。macOS runner は public repo で無料だが同時実行 5 枠のため、
open PR 5 本で 10 job ≈ 30〜40 分 queue する。許容範囲。

nvfetcher PR と flake PR は conflict しないため「両方 green でも合成 tree は未ビルド」が起きるが、
実害は小さいので strict status check (最新 base 必須) は要求しない。

## GitHub 側のガードレール

- ruleset `protect-default-branch` に **required status checks** (build × 2 host + build-nixos) を追加する。
  現状は CI 未完了でも merge でき、merge = deploy なので安全装置が無い
- App token は `contents: write` + `pull_requests: write` のみ。workflow の `permissions` は
  `contents: read` に落とし、App token は create-pull-request と `gh` 呼び出しにだけ渡す
- commit 署名 / comin の `gpgPublicKeyPaths` / `sshAllowedSignersPath` は現時点では不要。
  信頼境界は「誰が master に commit を載せられるか」= ruleset + owner で足りる
- nvfetcher の GitHub API rate limit 用 keyfile (`[keys] github = "..."`) は read のみなので `GITHUB_TOKEN` で足りる。
  Determinate installer が nix.conf に `access-tokens` を入れる設定も維持する (無いと `github:` の解決が 60 req/h で落ちる)
- App bot の commit author には `<id>+<slug>[bot]@users.noreply.github.com` を使う (実行時に
  `gh api /users/<slug>[bot]` で id を引く)。これで commit が App に紐付き、owner の commit として扱われない

## 実装前に直す前提

1. **`_sources/generated.json` の不整合**: gh-pr-graph が generated.nix にだけあり json に無い。
   CI はクリーン環境で shake DB が無く、json に無い source は新規扱いで latest に bump されるため
   「tcmux の PR に gh-pr-graph の更新が混ざる」= 要件 1 違反になる。先に `nvfetcher` を回して同期を commit する
2. **tcmux の flake output 露出**: tcmux は home-manager 内で `import` されるだけで flake output が無く、
   Linux で `nix build` する attribute が存在しない。`perSystem.packages.tcmux` (gh-pr-graph も) を数行で露出させる。
   vendorHash 以外の理由でビルドが失敗した場合も PR は開く (CI 側で赤くする)

## 受容するリスク (明示)

- nixpkgs / opencode / herdr が毎日動き、schedule も毎日なので、常時 5〜8 本の PR が open になる。
  merge しない PR も毎日更新され、そのたびに macOS CI が走る
- pin 解除のように flake.nix の編集を伴う更新は自動化の対象外 (手作業のまま)
- 手動編集の保護が無いので、bot PR ブランチに直接 push した commit は次回実行で消える
- 更新対象を追加・削除したときの PR 整理 (close) は手動

## 実装ステップ (概要)

1. (手作業) GitHub App を作成 (permissions: Contents: Read and write, Pull requests: Read and
   write。このリポジトリにのみ install) し、App ID を repository variable
   `DEPS_UPDATE_APP_ID`、private key を secret `DEPS_UPDATE_APP_PRIVATE_KEY` に登録
2. `nvfetcher` を回して `_sources/generated.json` を同期 (別 commit)
3. `flake.nix` に `perSystem.packages.tcmux` / `gh-pr-graph` を露出
4. `.github/workflows/update.yml` を追加
5. `renovate.json` を `enabledManagers: ["github-actions"]` に変更 (nix manager /
   lockFileMaintenance を削除)。この branch が merge されたら #34 / #37 を close する
   (旧設定のままだと Renovate が lock-file の PR を作り直し続ける)
6. (手作業) ruleset に required status checks を追加
7. `CLAUDE.md` に運用ルール (拒否は pin、手直しは close して自分のブランチ) を 1 行追記
8. `workflow_dispatch` で 1 対象を手動起動して E2E 確認 (PR 作成 → CI → 再実行で更新 → merge → 自動 close)

## 検討して採用しなかった代替案

| 案 | 不採用理由 |
|----|-----------|
| Renovate のまま (全 input を sha 固定) | ブランチ追従 input が固定できず二本立てになる。手元の `nix flake update` が効かなくなる。nvfetcher は対象外 |
| 一括更新 PR (`nix run .#update` を cron で回す) | 壊れた input が 1 つあると全体が merge できない。個別更新ができない |
| DeterminateSystems/update-flake-lock を matrix で回す | 内部は create-pull-request で、nvfetcher を扱えず二経路になる |
| 単一 job + `scripts/update-pr.sh <target>` ループ | Nix install が 1 回で済み、手元からも同じスクリプトを叩ける利点はある。create-pull-request が吸収する細部 (本文更新、no-diff close、author) を自前で書く必要があり、可動部品の少なさと job 単位の可視性を天秤にかけて現設計を維持。要件は両案とも満たすので将来の置換は可 |
| Claude Code routine / oberon の Hermes worker に任せる | 機械的な更新は Actions の方が安定。oberon は 2GB RAM でビルドに向かない。CI が赤くなった PR の修正だけをエージェントに投げる形なら後から足せる |
