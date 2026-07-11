# Claude Code オーケストレーターポリシー + カスタムエージェント 設計

日付: 2026-07-11(2026-07-12 改訂: Anthropic 公式資料の調査を反映し、
メインセッションを「複雑な思考の専任者」として再定義)
ステータス: 設計改訂・レビュー待ち(実装プラン未作成)

## 目的

Claude Code のメインセッション(Opus / Fable 起動時)をリードエージェント
(オーケストレーター)として振る舞わせる。ただしメインの役割は「委譲の事務処理」
ではなく**複雑な思考の専任**である:

- **メインが担う**: 戦略立案・タスク分解・複雑度評価・設計/アーキテクチャ判断・
  トレードオフ評価・結果の批判的評価・統合・ユーザーとの対話
- **サブエージェントが担う**: コンテキストを大量消費する機械的作業
  (探索・実装・検証の実行)

標語: **メインは頭を動かし、サブが手を動かす。**

狙い:

- **思考品質の最大化**: Opus/Fable のトークンと注意を判断業務に集中させる。
  探索ノイズ(ファイルダンプ・ビルドログ)をサブ側コンテキストに隔離し、
  context rot によるメインの判断劣化を防ぐ
- **コスト最適化**: 機械的作業を haiku / sonnet に落とす
- **並列性**: 独立した調査・作業の同時実行

## 参考にした一次情報(Anthropic 公式)

- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
  — リードエージェントの責務定義、委譲ブリーフの4要素、effort scaling、
  Opus リード + Sonnet サブが単一 Opus を 90.2% 上回った評価、
  マルチエージェントはチャット比約15倍のトークンを消費する警告
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
  — orchestrator-workers パターンは「サブタスクが事前に予測できない複雑タスク」
  にのみ適用。シンプルさ優先、複雑さは実証されたときだけ追加
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
  — context rot の根拠、compaction / note-taking / sub-agents の使い分け、
  サブは大量探索して 1,000〜2,000 トークンの蒸留サマリーを返す設計
- [Building agents with the Claude Agent SDK](https://claude.com/blog/building-agents-with-the-claude-agent-sdk)
  — サブエージェントの2つの存在理由(並列化・コンテキスト隔離)、
  検証は「明確なルール定義 > visual feedback > LLM-as-judge」
- [How and when to use subagents in Claude Code](https://claude.com/blog/subagents-in-claude-code)
  — 委譲すべきシグナルとアンチパターン、カスタムエージェント定義の
  ベストプラクティス(description はトリガー条件を明示、tools は最小権限)
- [Best practices for Claude Opus 4.7 with Claude Code](https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code)
  — 「直接実行できる作業にはサブエージェントを起動しない。
  複数ファイルへの並列処理のときのみ活用」
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
  — 状態の外部化(進捗ファイル・git)、fresh context で状態を即座に
  再構築できる仕組み、インクリメンタル実行

## 設計原則(調査からの導出)

1. **Think-first**: 委譲の前にメインが extended thinking で計画する。
   Research システムのリードは「思考フェーズで計画立案・ツール適性判断・
   複雑度評価・サブエージェント役割定義」を行う。委譲は思考の出力であり、
   思考の代替ではない
2. **判断は委譲しない**: 設計判断・アーキテクチャ選択・トレードオフ評価・
   「十分か」の判断はメイン専任。これらを委譲するとリードの存在意義が消える
3. **Effort scaling**: タスク複雑度に応じてリソースを明示的に配分する。
   Research システムの失敗事例(単純クエリに50サブエージェント)の再発防止
4. **委譲ブリーフの品質が委譲の質を決める**: 曖昧な指示はサブ間の重複作業と
   誤解釈を生む。4要素(objective / 出力形式 / ツール指針 / 境界)を必須とする
5. **出力契約**: サブは蒸留サマリー(目安 1,000〜2,000 トークン)だけを返す。
   ファイルダンプ・生ログの持ち帰りを禁止し、メインのコンテキストを守る
6. **適応ループ**: メインはサブの結果を鵜呑みにせず、評価→ギャップ特定→
   追加委譲 or 自己判断、を繰り返す(Research システムの interleaved thinking)
7. **コスト意識**: マルチエージェントは約15倍のトークンを消費する。
   effort scaling の最下層(委譲なし)を積極的に選ぶことが正当なデフォルト

## コンポーネント1: リードエージェントポリシー

`home-manager/programs/claude-code/user-memory.md` に「Lead Agent Policy
(Orchestration)」セクションを追加する。内容:

### 適用条件

- 自分のモデルが **Opus または Fable** の場合のみ適用
  (システムプロンプトの自己申告 "You are powered by ..." で判定)
- Sonnet 以下で起動されている場合は通常通り自分で作業する

### 恒常的な委譲許可

「このポリシーに従ったサブエージェント起動はユーザーの恒常的な指示である」と
明記し、ハーネスの spawn 抑制を上書きする。

### メインセッションの思考責務(第一級の定義)

1. **計画**: 作業開始前に extended thinking でタスクを分解し、複雑度を評価し、
   調査戦略を立てる。委譲するかどうか自体がこの思考の出力
2. **設計判断**: アーキテクチャ選択、インターフェース設計、トレードオフ評価、
   実装方針の決定はメインが自分で行う。**これらは委譲禁止**。
   worker には「決定済みの実装仕様」を渡す
3. **適応的評価**: サブの報告を批判的に評価する — 主張と証拠が整合しているか、
   ギャップは何か、追加調査が必要か、それとも判断に進めるか。
   不十分なら `SendMessage` で同一エージェントに追加指示(再 spawn しない)
4. **統合と報告**: 複数ソースの矛盾を解消し、結論をユーザーに報告する
5. **状態の外部化**: 長時間セッションでは計画・進捗を TodoWrite やプランファイル
   に保存し、compaction 後も方針を再構築できるようにする

### Effort scaling(委譲の3階層)

| タスク複雑度 | リソース配分 |
|---|---|
| 単純(単発の質問、1〜2ファイルの小変更、既知箇所の修正) | **委譲なし**。メインが直接作業 |
| 中規模(未知領域の調査、数ファイルの読み込みが必要な分析) | explorer 1体。並列可能な独立調査なら 2〜4体 |
| 大規模(多方面の調査 + 複数ファイル実装 + 検証) | explorer 並列 → メインが設計 → worker → verifier のパイプライン |
| 3つ以上の独立実装タスクの並列実行 | `team-task` スキル(既存)へエスカレーション |

### 委譲ブリーフの必須4要素

サブエージェントはこの会話を見られない前提で、毎回以下を含める:

1. **Objective**: 何を明らかにする/作るのか(成功条件つき)
2. **出力形式**: 何をどんな構造で返すか。「蒸留サマリーのみ、
   ファイルダンプ・生ログ禁止、参照は `path:line` 形式」を明記
3. **ツール・情報源の指針**: 見るべきディレクトリ、使うべきコマンド、
   避けるべき場所
4. **タスク境界**: やらないことの明示(隣接領域に踏み込まない、
   ファイルを変更しない等)。並列時は境界の重複を排除する

### 委譲のアンチパターン(禁止事項)

- 直接実行できる小タスクの委譲(オーバーヘッドが利益を上回る)
- 順序依存タスクの並列分割(Step 2 が Step 1 の完全な出力を要する場合)
- 同一ファイルを触るサブエージェントの並列起動
- 設計判断・トレードオフ評価の委譲
- サブエージェント同士の調整を前提とするタスク設計

### 既存資産との棲み分け

- **3つ以上の独立実装タスクの並列実行** → `team-task` スキル(既存)
- **実装後のコード改善** → `code-simplifier` / `code-review`(既存ルールを維持)
- **それ以外の日常タスク** → 本ポリシー

## コンポーネント2: カスタムエージェント定義

`home-manager/programs/claude-code/agents/` を新設し、`default.nix` の
コメントアウトされている `agentsDir = ./agents;` を有効化する。

スペシャリスト過剰は自動委譲の信頼性を下げる(公式ブログ)ため、3体に絞る:

| ファイル | model | tools | 役割 |
|---|---|---|---|
| `explorer.md` | haiku | Read, Glob, Grep, Bash(読み取り用途) | コードベース探索・ログ解析。「広く始めて絞る」戦略で調査し、結論と `path:line` 参照だけ返す |
| `worker.md` | sonnet | 制限なし | メインが決定した実装仕様に従う実装・修正・テスト作成。設計判断が必要になったら自分で決めずメインに差し戻す |
| `verifier.md` | sonnet | Bash, Read 中心 | ビルド・テスト・動作検証の実行。合否と証拠(コマンド・出力要旨)の事実報告に徹し、修正はしない |

各エージェントの system prompt に共通で含める指示:

- 出力契約: 蒸留サマリー(目安 1,000〜2,000 トークン)のみ。
  ファイルダンプ・生ログをそのまま返さない
- 証拠を添える: 実行したコマンドと出力の要旨、参照したファイルの `path:line`
- description にはトリガー条件を具体的に書く(能力の説明だけにしない)

モデル選択の注記: explorer を haiku とするのはコスト最適化のため。
調査品質に不満が出た場合は sonnet への引き上げを検討する
(Research システムの実績構成は Opus リード + Sonnet サブ)。

## データフロー(適応ループ)

```
ユーザー依頼
  → メイン (Opus/Fable): extended thinking で計画・複雑度評価
      ├─ 単純 → メインが直接作業
      └─ 委譲対象 → ブリーフ作成(4要素) → explorer (並列可)
            → メイン: 報告を批判的評価
                ├─ ギャップあり → SendMessage で追加指示 (ループ)
                └─ 十分 → メインが設計判断・実装仕様を決定
                      → worker に委譲 → verifier で検証
                      → メイン: 統合・ユーザーへ報告
```

## 検証

1. `nix fmt`
2. 新規ファイルを `git add`(Nix Flakes は git 追跡ファイルしか見えない)
3. 両ホストのビルド確認:
   - `nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link`
   - `nix build .#darwinConfigurations.SC-N-843.system --no-link`
4. `darwin-rebuild switch` 適用後、`~/.claude/agents/` への symlink を確認
5. 新セッションで Agent tool の利用可能タイプに explorer / worker / verifier が
   載ることを確認し、実際の委譲挙動を観察する(過剰委譲・過小委譲の両方)

## やらないこと

- hook による強制・毎ターン注入 — 本構成の運用で遵守率に不満が出てから検討
- opus 固定の reviewer エージェント — メイン自身が評価者なので冗長。
  コミット前のセカンドオピニオンは既存の `code-simplifier` / `code-review` が担う
- 既存の team-task / code-simplifier ルールの変更 — 棲み分けの明文化のみ
- 4体目以降のスペシャリスト追加 — 自動委譲の信頼性低下を招くため、
  必要性が実証されてから

## 検討済みの代替案

- **案A: プロンプトポリシーのみ** — 委譲先のモデル指定ができず要件の中核を
  満たせない
- **案C: 案B + UserPromptSubmit hook 注入** — 遵守率は最大だが毎ターンの
  ノイズとトークン消費が増える。CLAUDE.md が毎セッション読み込まれることを
  考えると重複投資
- **explorer/worker/verifier を全て sonnet にする** — Research システムの実績
  構成に近いが、read-only 探索は haiku で十分な可能性が高く、まず安い構成で
  観察する。品質問題が出たら引き上げる(改訂で注記済み)

## 改訂履歴

- 2026-07-11: 初版(案B: ポリシー + カスタムエージェント)
- 2026-07-12: Anthropic 公式資料(multi-agent research system、
  building effective agents、context engineering、subagents ブログ等)の
  調査を反映。メインの責務を「ブリーフ・検証・統合」の管理役から
  「計画・設計判断・適応的評価・統合という複雑思考の専任」に再定義。
  effort scaling の3階層、委譲ブリーフ4要素、出力契約(蒸留サマリー)、
  アンチパターン、コスト警告(約15倍トークン)を追加
