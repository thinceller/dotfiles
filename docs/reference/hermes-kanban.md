# Hermes kanban 自動実装パイプライン

Slack から要件を投げると、Planner が設計・チケット分割を行い、kanban へ積み、
worker プロファイルが実装して Draft PR まで作る仕組み。

## 全体の流れ

```
Slack (要件)
  │
  ▼
Planner (default profile, hermes-documents/SOUL.md)
  │  1. grill-with-docs … 要件・制約・設計判断を対話で確定
  │  2. to-spec         … 合意内容を docs/specs/ の仕様書へ整理
  │  3. to-tickets      … 仕様書を .scratch/<feature>/issues/*.md の
  │                        チケット (依存順・**Blocked by:** 付き) へ分割
  │  4. to-kanban       … チケットを board 上のタスクに変換し、
  │                        依存順に --parent を張りながら作成
  ▼
kanban board (hermes kanban.db, board ごとに default-workdir を持つ)
  │  タスクは assignee=worker, workspace=dir:<repo-path> で作成される
  ▼
dispatcher (hermes-agent 本体、kanban.max_in_progress_per_profile = 1)
  │  ready なタスクを worker profile へ順に spawn (approvals.mode = off, stdin=DEVNULL)
  ▼
worker (worker profile, hermes-profiles/worker/SOUL.md)
  │  workspace の repo で branch を切り、実装・検証・commit・push
  ▼
Draft PR (gh pr create --draft)
  │
  ▼
kanban_complete (タスクを done にし、summary に PR URL 等を記録)
```

## なぜ設計工程を人格ではなく skill に置くか

Slack ゲートウェイは常に default profile で動き、会話からプロファイルを切り替える機構は無い
(`gateway/platforms/slack.py`)。つまり default profile は、vault への記録・検索も、質問への回答も、
開発依頼の設計も、すべて 1 つの人格で引き受けることになる。

一方 `SOUL.md` は Hermes の identity slot で、system prompt の先頭にラッパー無しで置かれ、
全ターンに無条件で載る (`agent/prompt_builder.py` の `load_soul_md`、
`system_prompt.py` の stable tier)。ここに「設計工程は必ずこの順番」「作成できるのはこの4ファイルだけ」
と書くと、その制約が vault へのメモや記事のクリップにも等しく掛かってしまう。
実際、AGENTS.md が定める Inbox capture の書き込み先は SOUL.md 側の allowlist に含まれておらず、
どちらが優先かを示す指示は Hermes のベースプロンプトに存在しない。

そこで、性質で置き場を分けている。

- **常に効いていてほしいもの** (人格、言語とトーン、安全上の一線) → `SOUL.md`
- **常に効いていてほしい設定値** (issue tracker、board slug など) → `AGENTS.md`
  `/to-spec` や `/to-tickets` を単独で呼んだときにも効く必要があるため、skill の中には置かない
- **設計依頼のときだけ効けばいいもの** (工程の順序、承認ゲート、設計中のファイル制限)
  → `design-pipeline` skill

トレードオフとして、skill はモデルが読み込むと判断して初めて文脈に入るため、
設計依頼を設計依頼と認識し損ねると工程が適用されない。skill の description に
トリガ語と否定境界を書いて発見性を確保している。

## dotfiles で管理しているもの

| 対象 | ファイル | 配置先 |
|---|---|---|
| default profile の SOUL.md | `hosts/oberon/hermes-documents/SOUL.md` | `${stateDir}/.hermes/SOUL.md` (default profile の HERMES_HOME 直下)。内容は汎用アシスタントの人格・言語とトーン・安全上の一線であって、設計工程はここには置かない |
| design-pipeline skill | `hosts/oberon/hermes-skills/design-pipeline/` | `sharedSettings.skills.external_dirs` 経由で default profile の system prompt に読み込み専用ディレクトリとして注入。分解が必要な開発依頼のときだけ、設計工程 (grill-with-docs → to-spec → to-tickets → to-kanban) の順序と承認ゲートを効かせる |
| default profile への AGENTS.md 注入 | `hosts/oberon/hermes-documents/AGENTS.md` | `services.hermes-agent.documents."AGENTS.md"` 経由で workingDirectory (`/var/lib/hermes/workspace/AGENTS.md`) に配置。cwd がそこになる default profile にのみ届く (worker は dispatcher が cwd を各リポジトリへ移すため届かない)。issue tracker / spec 置き場 / triage ラベル語彙 / kanban board slug などの設計時の設定値もここに載る (`/to-spec` や `/to-tickets` を単独で呼んだときにも効く必要があるため) |
| worker profile の SOUL.md | `hosts/oberon/hermes-profiles/worker/SOUL.md` | `${stateDir}/.hermes/profiles/worker/SOUL.md` (`hermes-worker-profile` activation script が配置) |
| worker profile の config.yaml | `hermes-agent.nix` の `workerSettings` (`sharedSettings` を `approvals.mode = "off"`, `skills.external_dirs = [ ]` で上書き) | `${stateDir}/.hermes/profiles/worker/config.yaml` (`hermes-worker-profile` activation script が生成・配置) |
| to-kanban 変換スクリプトと skill | `hosts/oberon/hermes-scripts/to-kanban.py` / `hosts/oberon/hermes-skills/to-kanban/SKILL.md` | スクリプトは `extraPackages` で `to-kanban` コマンドとして PATH に、skill は `sharedSettings.skills.external_dirs` 経由で Planner の system prompt に読み込み専用ディレクトリとして注入 |
| mattpocock/skills の pin | `nvfetcher.toml` (`matt-pocock-skills` エントリ) → `_sources/generated.nix` | `hermes-agent.nix` の `plannerSkills` が必要な skill だけ抜き出し、`sharedSettings.skills.external_dirs` に載せる (Planner のみ。worker は `external_dirs = [ ]` で受け取らない) |
| kanban board の作成 | `hermes-agent.nix` の `systemd.services.hermes-kanban-boards` (`boards` リスト) | `hermes-agent.service` の前に oneshot で `hermes kanban boards create` を冪等実行 |

## 手動で用意するもの

kanban のタスクは `--workspace dir:<repo-path>` で、`/var/lib/hermes/workspace/` 配下の
リポジトリチェックアウトをそのまま使う。対象リポジトリは増減するため clone は自動化していない。
新しいホストにセットアップするとき、あるいは対象リポジトリを増やすときは、hermes ユーザーで
手動 clone する。

```bash
sudo -u hermes GIT_SSH_COMMAND="ssh -i /run/secrets/hermes-github-ssh-key -o IdentitiesOnly=yes" \
  git clone git@github.com:thinceller/thinceller.net.git /var/lib/hermes/workspace/thinceller.net

sudo -u hermes GIT_SSH_COMMAND="ssh -i /run/secrets/hermes-github-ssh-key -o IdentitiesOnly=yes" \
  git clone git@github.com:thinceller/dotfiles.git /var/lib/hermes/workspace/dotfiles

sudo -u hermes GIT_SSH_COMMAND="ssh -i /run/secrets/hermes-github-ssh-key -o IdentitiesOnly=yes" \
  git clone git@github.com:thinceller/knowledge-base.git /var/lib/hermes/workspace/knowledge-base
```

鍵のパスは `hosts/oberon/hermes-agent.nix` の `GIT_SSH_COMMAND` の定義
(`config.sops.secrets."hermes-github-ssh-key".path`) が指す sops secret の実体で、
sops-nix が復号後に配置する `/run/secrets/hermes-github-ssh-key` を指す。

workspace が無い状態でタスクを dispatch すると、worker は `kanban_block` して停止する
(誤ったディレクトリでの作業を避けるため、worker の SOUL.md がそう指示している)。

## 新しい対象リポジトリを増やすとき

1. `/var/lib/hermes/workspace/<repo>` に clone する
2. `hosts/oberon/hermes-agent.nix` の `hermes-kanban-boards` の `boards` に board を追加する
3. `hosts/oberon/hermes-documents/SOUL.md` の board slug 表に行を追加する
4. 対象リポジトリの `CLAUDE.md` / `AGENTS.md` に検証コマンドが書かれていることを確認する

worker の SOUL.md にはプロジェクト固有の手順を書かない。検証コマンドもブランチ規約も
各リポジトリの `CLAUDE.md` / `AGENTS.md` が正で、worker はそれを読んで従う。
検証コマンドが書かれていないリポジトリのタスクは、worker が `kanban_block` して止まる。
