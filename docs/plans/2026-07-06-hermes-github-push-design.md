# Hermes への thinceller リポジトリ push 権限付与 設計

> **Status**: 設計承認済み (2026-07-06)。実装プランは
> `docs/plans/2026-07-06-hermes-github-push-plan.md` を参照。

**Goal:** oberon 上の Hermes Agent に、vault (knowledge-base) 以外の thinceller 個人
リポジトリへ安全に push / PR 作成できる権限を与える。会社 org へのアクセスは構造上
不可能に保つ。

## 決定事項

| 論点 | 決定 |
|------|------|
| 認証方式 | GitHub machine account (`thinceller-hermes`) + SSH 鍵 |
| push 先制約 | repo で使い分け (実行系は PR 必須、コンテンツ系は直 push 許可) |
| PR 作成 | 自動化する (machine user の PAT + gh) |

## 全体像

machine account `thinceller-hermes` を作成し、push を許可したいリポジトリにだけ
**Write collaborator** として招待する。許可リスト = 招待リストであり、GitHub UI で
一覧・剥奪が一目でできる。会社 org には招待しない限り構造上アクセス不能。

```
[GitHub]
  thinceller/knowledge-base   ← Write 招待 (deploy key は廃止して統合)
  thinceller/<許可した repo>  ← Write 招待
  会社 org/*                  ← 招待なし = アクセス不能
        ▲
  thinceller-hermes (machine user, 2FA 有効)
        ▲ SSH 鍵 (push 用) / PAT (PR 作成用)
[oberon] hermes-agent
```

GitHub ToS 上 machine account 1つの運用は許容されている。commit / PR author が
`thinceller-hermes` として本人と区別されるため監査性も上がる。git identity の
email は既に commit に使っている `hermes@thinceller.dev` を machine account で
検証する。

## クレデンシャル (2本、いずれも sops 管理)

### 1. SSH 鍵 (git push 用)

- 新規 ed25519 鍵を machine user に登録し、`secrets/oberon.yaml` に追加
- 既存の `GIT_SSH_COMMAND` の鍵パスを差し替えるだけで、vault を含む招待済み
  全 repo に届く
- **現行の knowledge-base deploy key は、machine user での push 動作確認後に廃止**
  (鍵が1本に統合され、vault フロー自体は無変更)

### 2. PAT (gh での PR 作成用)

- machine user の classic PAT (`repo` スコープ、90日期限でローテーション)
- fine-grained PAT は「他ユーザー所有 repo の collaborator アクセス」への対応が
  不確実なため classic を採用。実装時にサポート状況を確認し、可能なら
  fine-grained に切り替える
- スコープが広くても、アカウント自体が招待済み repo にしか届かないため
  blast radius は同じ
- PAT は systemd の環境変数に直接載せず、`GH_TOKEN="$(cat <sops path>)" exec gh`
  する薄い wrapper スクリプト (Nix 生成) を `gh` として PATH に置く。deploy key と
  同じ「秘密がエージェントのコンテキストに乗らない」方針の維持

## GitHub 側のガードレール (rulesets)

- **実行系 repo (`.dotfiles` など、push 内容が機械で実行されるもの)**:
  default branch に ruleset で「PR 必須 + force push 禁止」を設定、bypass は本人のみ。
  hermes は `hermes/<slug>` ブランチに push して PR を作るところまで。マージは人間が
  レビューして行う。プロンプトインジェクションで悪性コードを注入されても、
  自動実行に至る経路が人間のレビューで遮断される
- **コンテンツ repo (knowledge-base 等)**: force push 禁止のみ設定し、直 push は
  現状どおり許可。Inbox capture フローは無変更

## hermes 側の運用ルール

`AGENTS.md` に追記する:

- 扱ってよい repo の明示リスト
- 作業は `/var/lib/hermes/workspace/<repo>` に clone
- ブランチ名は `hermes/<slug>`
- force push 禁止
- PR 作成は `gh pr create`

## 受容するリスク (明示)

hermes ユーザーが読めるファイルは、インジェクションされたエージェントが理論上
持ち出せる (現行 deploy key と同じ性質)。緩和策:

- 招待の最小化 (必要な repo にだけ Write)
- PAT の 90 日ローテーション
- GitHub 側の SSH key / PAT last-used 監視
- 漏洩時は machine user の鍵と PAT を失効し、招待を剥奪すれば即遮断できる

## 実装ステップ (概要)

1. **GitHub 手作業**: machine account 作成 (email `hermes@thinceller.dev` を検証) →
   SSH 鍵・PAT 登録 → 対象 repo へ Write 招待 → rulesets 設定
2. **Nix**: sops に鍵と PAT を追加、`GIT_SSH_COMMAND` の鍵差し替え、gh wrapper を
   `extraPackages` に追加、AGENTS.md 追記
3. **検証**: hermes にブランチ push + PR 作成を実際にやらせる / 実行系 repo の
   master 直 push が**拒否される**ことを確認 → 確認後に knowledge-base の
   deploy key を削除

## 検討して採用しなかった代替案

- **Deploy key を repo ごとに追加**: 最小権限だが、repo が増えるたびに
  鍵生成 + sops + Nix + GitHub 登録が必要でスケールしない
- **GitHub App + 短命 installation token**: 漏洩時の影響が最小 (1時間で失効) で
  最も堅牢だが、JWT 生成・token 更新の仕組みを自前実装する必要があり
  構築コストが高い。将来クレデンシャル漏洩リスクを下げたくなったときの
  移行先候補
- **本人の fine-grained PAT**: 構築は最も手軽だが、hermes が「本人として」
  push するため監査上の区別がなく、漏洩時は本人権限で悪用される
