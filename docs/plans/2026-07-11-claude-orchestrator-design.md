# Claude Code リードエージェント方式(オーケストレーター)設計

日付: 2026-07-11(2026-07-12 v3: 4観点のサブエージェントレビューを反映)
ステータス: 設計改訂・レビュー待ち(実装プラン未作成)

## 目的

Claude Code のメインセッション(Opus / Fable 起動時)をリードエージェントとして
振る舞わせる。メインの役割は「委譲の事務処理」ではなく**複雑な思考の専任**:

- **メインが担う**: 戦略立案・タスク分解・設計/アーキテクチャ判断・トレードオフ
  評価・結果の批判的評価・統合・ユーザーとの対話。
  **設計判断に関わるファイルはメイン自身が読む**(後述のキャッシュ経済)
- **サブエージェントが担う**: 大量のコンテキストを消費する使い捨ての機械的作業
  (広域探索・ログ解析・決定済み仕様の実装)

標語: **メインは頭を動かし、サブが手を動かす。**

## 参考にした一次情報(Anthropic 公式)

- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
  — リードの責務、委譲ブリーフ4要素、effort scaling、約15倍トークンの警告
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
  — orchestrator-workers は「サブタスクが予測不能な複雑タスク」のみ。シンプルさ優先
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
  — context rot、サブは蒸留サマリー(1,000〜2,000 トークン)を返す
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)
  — frontmatter 仕様(`model`/`tools`/`hooks`)、description 駆動の自動委譲、
  SendMessage による resume(agent teams 不要)、サブも user memory を読み込む仕様
- [How and when to use subagents in Claude Code](https://claude.com/blog/subagents-in-claude-code)
  — 委譲シグナルとアンチパターン、description はトリガー条件を明示
- [Best practices for Claude Opus 4.7 with Claude Code](https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code)
  — 「直接実行できる作業にはサブエージェントを起動しない」。
  Opus 4.7+/Fable はデフォルトでサブエージェント起動が保守的
- [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams)
  — agent teams の現仕様(v2.1.178 で TeamCreate/TeamDelete 削除、暗黙の
  セッションチーム化)、subagents との使い分け指針
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
  — 状態の外部化、インクリメンタル実行

## 設計原則

1. **Think-first**: 委譲の前にメインが extended thinking で計画する。
   委譲は思考の出力であり、思考の代替ではない
2. **判断は委譲しない**: 設計判断・アーキテクチャ選択・トレードオフ評価・
   「十分か」の判断はメイン専任
3. **遵守メカニズムは description 駆動(主)+ CLAUDE.md ポリシー(従)**:
   自動委譲はハーネスがエージェント定義の `description` を読んで判断する。
   ハーネスの spawn 抑制文も「available agent types の名指し」を例外として
   許容する。したがってトリガー条件はエージェント定義側に書き込み、
   CLAUDE.md には要点数行だけを置く(注意予算の節約を兼ねる)
4. **キャッシュ経済を踏まえた委譲閾値**: サブスクプラン + 1M コンテキスト +
   プロンプトキャッシュ(再送 ~0.1x)の下では「メインが自分で読む」方が
   トークン的に安いことが多い。委譲の損益分岐は
   **「探索量が大きく(目安: 数万トークン超)、かつ結果を今後二度と参照しない
   使い捨てコンテンツ」**の場合のみ。設計判断の材料になるファイルはメインが
   読んでキャッシュに乗せる。マルチエージェントの約15倍トークンは
   サブスクではレート制限の早食いとして跳ね返る
5. **委譲ブリーフの4要素**: objective / 出力形式 / ツール・情報源の指針 /
   タスク境界。曖昧な指示は重複作業と誤解釈を生む
6. **出力契約はエージェント定義に置く**: 蒸留サマリーのみ・ダンプ禁止等の
   行動規範はサブの system prompt に書けば常駐コストゼロ
7. **適応ループ**: メインはサブの報告を批判的に評価し、ギャップがあれば
   `SendMessage` で同一エージェントに追加指示する(再 spawn しない)
8. **複雑さは実証されてから追加**: エージェントは最小構成(2体)で開始し、
   問題が観測されてから追加する

## コンポーネント1: カスタムエージェント定義(遵守メカニズムの主役)

`home-manager/programs/claude-code/agents/` を新設し、`default.nix` の
コメントアウトされている `agentsDir = ./agents;` を有効化する
(home-manager モジュールに実在することを確認済み: `claude-code.nix` の
`agentsDir` オプション → `~/.claude/agents/` へ再帰 symlink)。

初期構成は **2体**(verifier は初版から削除。理由: メイン自身の適応的評価と
既存 code-review 系で評価は三重化しており YAGNI。ビルドログ隔離は worker 内で
完結する):

### explorer.md(model: haiku)

- **役割**: コードベース探索・広域検索・ログ解析。結論と参照だけ返す
- **description**(自動委譲のトリガー、prescriptive に書く):
  「未知領域の調査で3ファイル以上を読む必要があるとき、ビルドログ・大量の
  grep 結果など使い捨ての大規模テキストを解析するとき、独立した調査を
  並列実行したいときに proactive に使う」
- **tools**: Read, Glob, Grep, Bash
- **read-only の強制**: frontmatter の `tools` では Bash の引数パターン制限は
  不可能(仕様確認済み)。公式ドキュメントの「Conditional rules with hooks」
  パターンに従い、**frontmatter 内 `hooks:` の PreToolUse フック**で書き込み系
  コマンドをブロックする(exit code 2)。これは agent-scoped であり
  「やらないこと」の毎ターン注入 hook とは別物
- **出力契約**(system prompt): 蒸留サマリー 1,000〜2,000 トークンのみ。
  **結論ごとに逐語引用 + `path:line` を必須**とする(haiku の自信過剰な
  誤報告への防御。メインは判断に使う引用を最低1箇所スポットチェックする)。
  「広く始めて絞る」探索戦略
- **注記**: 組み込み Explore は one-shot で SendMessage resume 不可のため、
  適応ループを回すにはカスタム定義が必須(仕様確認済み)

### worker.md(model: sonnet)

- **役割**: メインが決定した実装仕様に従う実装・修正・テスト作成、
  および実装後のビルド・テスト実行と合否報告
- **description**: 「実装方針が確定した複数ファイルにわたる実装・修正を
  任せるときに使う。設計判断が未確定のタスクには使わない」
- **tools**: 制限なし(全ツール継承)。ただし `disallowedTools: Agent` で
  ネスト spawn を禁止
- **乖離報告プロトコル**(system prompt): 仕様と実コードの乖離を発見したら、
  自分で設計判断せず「乖離内容 + 推奨案」を添えて**1回で**差し戻す
  (ピンポン往復の防止)
- **検証手順**(system prompt): 実装後、**新規ファイルを `git add` してから**
  ビルド・テストを実行し(Nix Flakes は git 追跡ファイルしか見ない —
  偽陽性防止)、合否と証拠(コマンド・出力要旨)を報告する
- **出力契約**: 変更ファイル一覧 + 検証結果の蒸留サマリー。生ログ禁止

### 共通事項

- description はトリガー条件を具体的に書く(能力の説明だけにしない)
- メインは spawn 時に Agent tool の `model` パラメータを渡さない
  (per-invocation 指定は frontmatter の model を上書きしてしまう。仕様確認済み)
- **副作用への対処(必須機構)**: カスタムサブエージェントも user memory
  (CLAUDE.md)を読み込む仕様のため、Lead Agent Policy はサブのコンテキスト
  にも載る。ポリシー冒頭の「Opus/Fable のときのみ適用」のモデルゲートは、
  sonnet/haiku サブが再帰的にオーケストレーションを始めるのを防ぐ
  **正しさに必須の機構**である(あれば良い、ではない)

### verifier の扱い(繰り延べ)

worker の自己検証で不十分な事象(自己採点の甘さ、環境差異の見落とし)が
実際に観測されてから、独立した verifier(sonnet, Bash/Read 中心)を追加する。

## コンポーネント2: リードエージェントポリシー(CLAUDE.md、要点のみ)

`home-manager/programs/claude-code/user-memory.md` に「Lead Agent Policy」
セクションを追加する。既存メモリの注意予算を守るため**10行程度**に抑える:

1. **適用条件**: 自分のモデルが Opus または Fable の場合のみ
   (システムプロンプトの自己申告で判定)。それ以外は通常通り自分で作業
2. **恒常的な委譲許可**: explorer / worker への委譲はユーザーの恒常的指示
3. **委譲シグナル(if-then 形式)**:
   - 使い捨ての大規模探索(数万トークン級)・ログ解析 → explorer
   - 設計確定済みの複数ファイル実装 → worker
   - それ以外(小変更・単発質問・設計判断・対話的デバッグ)→ 自分でやる。
     設計判断の材料になるファイルは自分で読む
4. **委譲時の規律**: ブリーフに objective / 出力形式 / 情報源 / 境界を含める。
   結果は批判的に評価し、不足は SendMessage で追加指示。
   spawn 時に model パラメータは渡さない
5. **実装後の Code Improvement**(既存ルールとの接続): worker の成果物にも
   既存の Code Improvement 基準(code-simplifier / code-review)を適用する。
   実行主体はメイン

effort scaling の詳細テーブル・アンチパターン列挙は CLAUDE.md には置かず、
本設計ドキュメントとエージェント定義に分散させる(常駐コスト削減)。

## データフロー(適応ループ)

```
ユーザー依頼
  → メイン (Opus/Fable): extended thinking で計画・複雑度評価
      ├─ 既にやり方が分かる/小規模/設計判断そのもの → メインが直接作業
      └─ 使い捨て大規模探索 → ブリーフ(4要素) → explorer (並列可)
            → メイン: 報告を批判的評価(引用をスポットチェック)
                ├─ ギャップあり → SendMessage で追加指示 (ループ)
                └─ 十分 → メインが設計判断・実装仕様を決定
                      (必要なファイルはメイン自身が読む)
                      → worker に委譲(実装 + git add + ビルド/テスト + 報告)
                      → メイン: code-simplifier / code-review(既存ルール)
                      → メイン: 統合・ユーザーへ報告
```

## agent teams の立ち位置と team-task スキルの削除

調査結果(2026-07-12):

- agent teams は依然 experimental(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)。
  **v2.1.178 で大幅再構築され、TeamCreate / TeamDelete ツールは削除済み**。
  セッションは暗黙の単一チームを持ち、teammate は Agent tool の `name` で
  直接 spawn する。`team_name` は無視される
- 公式の使い分け: 「結果だけ欲しい focused task → subagents。teammate 同士の
  議論・相互検証が必要 → teams」。逐次タスク・同一ファイル編集は teams 非推奨
- **自作 team-task スキルは削除する**。理由:
  1. 中核手順(Phase 4 の TeamCreate、Phase 7 の TeamDelete)が存在しない
     ツールを指示しており、発動すると誤動作の元になる
  2. 有用だった指針(file ownership、タスク分解、レビュー必須化)の大半は
     現行公式ドキュメントの best practices に吸収済み
  3. 本設計が subagents の適用領域(focused work のリード集中管理)を
     カバーし、teams が真に勝る「相互対話型の調査・競合仮説デバッグ」は
     スキルなしで自然言語のプロンプト一文から起動できる
- env フラグ自体は残し、teams は「複数エージェントに議論・相互検証させたい
  とき、ユーザーまたはメインが自然言語で都度依頼する」軽量運用に切り替える。
  ポリシーからの機械的なエスカレーション先としては扱わない
  (旧設計の「3タスク以上 → team-task」ルールは撤廃)

## 検証

1. `nix fmt`
2. 新規ファイルを `git add`
3. 両ホストのビルド確認:
   - `nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link`
   - `nix build .#darwinConfigurations.SC-N-843.system --no-link`
4. `darwin-rebuild switch` 適用後、`~/.claude/agents/` への symlink を確認
5. 新セッションで Agent tool の利用可能タイプに explorer / worker が載ることを
   確認し、実際の委譲挙動を観察する

## 観測と改善ループ(適用後の後続フェーズ)

ポリシー遵守率は定量観測できる。必要になったら以下を導入する:

- **観測専用 hook**: PreToolUse(matcher: Agent)で委譲イベントを JSONL に
  記録(毎ターン注入 hook とは別物でノイズゼロ)
- **過剰委譲シグナル**: 単純タスク層での spawn、数百トークン未満/30秒未満で
  完了する spawn
- **過小委譲シグナル**: 大量の Read/Bash 出力によるメインのコンテキスト膨張・
  compaction 発生にもかかわらず spawn ゼロ
- **固定タスクセット評価**: 代表タスク(単純2/中規模2/大規模1)で
  委譲挙動を適用直後と設定変更時に確認
- これらの計測結果が「UserPromptSubmit hook 注入(案C)へ進むか」の判断材料

## やらないこと

- UserPromptSubmit hook による毎ターン注入 — 上記の観測で遵守率の問題が
  実証されてから(agent-scoped PreToolUse hook はこれに該当しない)
- verifier / reviewer エージェントの初期投入 — 必要性が観測されてから
- 4体目以降のスペシャリスト追加 — 自動委譲の信頼性低下を招く
- 既存の Code Improvement / Verification ルールの変更 — 接続の明文化のみ

## 検討済みの代替案

- **案A: プロンプトポリシーのみ** — 委譲先のモデル指定ができない。
  また組み込み Explore は resume 不可で適応ループが回らない
- **案C: 案B + UserPromptSubmit hook 注入** — 観測で必要性が実証されてから
- **explorer を sonnet にする** — 委譲閾値を引き上げた結果、explorer の用途は
  使い捨ての大規模探索に限定され、設計判断の材料はメインが直接読む分業に
  なったため、haiku で開始する。誤報告対策は逐語引用の義務化とメインの
  スポットチェックで担保し、それでも誤誘導が観測されたら引き上げる
- **verifier を含む3体構成** — 評価者の三重化(メインの適応的評価 +
  code-review 系 + verifier)で YAGNI。worker の自己検証への統合で開始

## 改訂履歴

- 2026-07-11: 初版(案B: ポリシー + カスタムエージェント)
- 2026-07-12 v2: Anthropic 公式資料の調査を反映。メインを複雑思考の専任者として
  再定義、effort scaling・ブリーフ4要素・出力契約・アンチパターンを追加
- 2026-07-12 v3: 4観点サブエージェントレビュー(仕様・シンプルさ・運用コスト・
  agent teams 調査)を反映:
  - 遵守メカニズムを description 主・CLAUDE.md 従に逆転、CLAUDE.md は要点10行に圧縮
  - サブスク+1M+キャッシュ前提で委譲閾値を引き上げ(設計材料はメインが読む)
  - verifier を初期構成から外し2体構成に(worker に検証統合、git add 偽陽性対策)
  - explorer の read-only を agent-scoped PreToolUse hook で強制(公式パターン)、
    逐語引用義務化
  - model パラメータ非指定・disallowedTools: Agent・モデルゲート必須化など
    仕様確認に基づく修正
  - team-task スキル削除を決定(TeamCreate/TeamDelete が v2.1.178 で削除済み)、
    agent teams は自然言語での都度利用に位置づけ直し
  - 観測と改善ループ(観測専用 hook・過剰/過小委譲シグナル)を追加
