# Obsidian Vault 共有エージェントメモリ導入計画

> **Status**: 設計確定・実装未着手 (2026-06-28、Karpathy LLM Wiki パターン適用でブラッシュアップ)。

## 背景・狙い

private リポジトリで管理している Obsidian vault (`knowledge-base`) に細かい知識メモや
Web クリップを蓄積している。これを Claude Code / OpenCode / Hermes Agent の**共有メモリ**
に据えたい:

- 各エージェントごとにディレクトリを分け、セッションログや知見を貯める
- セッション中に得た汎用的な知識や調査内容を Obsidian の `[[wikilink]]` ネットワークで繋ぐ
- vault に ground された(チャット抽出ではない)長期記憶を全エージェントで共用する

**狙い**: [Karpathy の LLM Wiki パターン](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
に沿った「育つ知識ベース」として運用する。Hermes Agent は当面 vault 未連携のまま残す。

### 2 つのアクセス経路と役割分離

vault へのアクセスは **2 つの経路** に分かれ、それぞれ役割が異なる:

| 経路 | 主用途 | 操作ツール | 使うスキル |
|---|---|---|---|
| **A. vault 内 Claude Code** (`cd vault && claude`) | Ingest・Lint・git 同期（整理作業） | **Grep / Glob / Read / Edit / Write**（標準ツール直接） | `research-note`（既存）・`vault-lint`（新規）・`obsidian-git`（既存） |
| **B. 別プロジェクトからの MCP 経由** | Query・Capture・Session log（作業中の参照と軽量記録） | **enquire-mcp** (`obsidian_search` 等) | `vault-memory`・`vault-capture`・`vault-session-log` |

**方針**: vault 内セッション（経路A）では **enquire-mcp を使わず、直接 Grep/Edit で操作する**。
理由:
- vault が CWD になるため標準ツールがそのまま使える（sandbox で許可済み）
- `research-note` スキルは既に Grep/Glob + WebSearch で動いている（変更不要）
- リテラル検索・ファイル編集は直接ツールの方が正確・高速
- MCP サーバープロセスを起動しなくて済ぶ設定がシンプル
- enquire-mcp は「別プロジェクトからの vault アクセス経路（経路B専用）」と割り切る

> vault 内セッションでも enquire-mcp は `programs.mcp` で有効化されているためツールとして
> 呼べるが、**推奨は Grep/Glob**。概念検索が必要な場面（曖昧な問い・広域探索）でのみ
> 任意併用可。Phase 2 で reranker/HNSW を入れる際に見直す。

### Karpathy LLM Wiki パターンの核心

RAG（stateless・毎回ゼロから再計算）ではなく、**LLM が恒久的な wiki を少しずつ構築・維持
する（compounding・積み上がる）**パターン。知識は一度コンパイルされ、その後は最新に保たれる。

3 層アーキテクチャ:

| 層 | 役割 | ユーザー vault での対応 |
|---|---|---|
| **Layer 1: Raw sources** | 不変・読むだけ。真実の源泉 | `Clippings/` (Web Clipper で保存、編集基本しない) |
| **Layer 2: The wiki** | LLM が全面所有・生成・維持 | `Notes/` (アトミックノート) + `Agents/` + `Shared/` + `log.md`（`index.md` は Dataview 自動生成） |
| **Layer 3: The schema** | 構造・規約・ワークフロー定義 | `CLAUDE.md` (既存) + `.claude/skills/` (既存 + 新規) |

3 つの操作（経路別）:

- **Ingest（取り込む）** [経路A・vault 内]: ソースを読む → 要点確認 → wiki に要約 → log 追記。`research-note` スキル（Grep/Glob + WebSearch）
- **Query（問う）** [経路B・MCP 経由]: wiki に質問 → 出典付き統合回答 → **良い回答は新しいページとして wiki にファイルし直す（複利ループ）**。`vault-memory` スキル（enquire-mcp）
- **Lint（健全性を保つ）** [経路A・vault 内]: 矛盾・古い主張・孤立ページ・未ページ化概念・不足相互参照を検出。`vault-lint` スキル（Grep/Glob）

> **合言葉**: Obsidian is the IDE. The LLM is the programmer. The wiki is the codebase.

### ユーザー vault の現状

vault は既に Karpathy パターンの一部を実装している:

```
~/src/github.com/thinceller/knowledge-base/
├── CLAUDE.md              # Layer 3: schema (既存)
├── .claude/skills/        # Layer 3: workflows (既存)
│   ├── research-note/     # Ingest ワークフロー (高完成度)
│   └── obsidian-git/      # git 運用ルール
├── Notes/                 # Layer 2: atomic notes (既存・フラット)
│   ├── ROI (投資利益率).md
│   ├── リスティング広告.md
│   ├── ハーネスエンジニアリング.md
│   └── ...
├── Clippings/             # Layer 1: raw sources (既存・フラット)
│   ├── AIエージェントの″ハーネス″に関わる混乱と私見.md
│   └── ...
└── README.md
```

既存の `research-note` スキルは Web 調査を伴う本格 Ingest ワークフロー（信頼できる情報源の
優先順位テーブル、複数ソース裏取り、双方向リンク提案、Sources セクション必須）として完成度が高い。
本計画はこれを置き換えず、**不足部分（エージェント共有メモリ・Query・複利ループ・Lint）を追加する**。

## 調査結果サマリー

### エージェントメモリシステムの現状

| ツール | メモリ仕組み | MCP サポート | 現在の設定 |
|---|---|---|---|
| **Claude Code** | CLAUDE.md (手動) + auto memory (Claude 自律、現在無効) + Skills + Rules | stdio MCP (`mcpServers` / `enableMcpIntegration`) | `autoMemoryEnabled=false`, `user-memory.md` で宣言的管理 |
| **OpenCode** | AGENTS.md + Skills + References (外部ディレクトリ/Git リポジトリ参照) | local (stdio) + remote (HTTP) MCP | personal 限定, `opencode.json` の `mcp` / `references` で設定 |
| **Hermes Agent** | MEMORY.md (2200 文字制限) + USER.md (1375 文字) + Session Search (FTS5) + 外部 Memory Provider (Mem0/Honcho 等) | stdio + HTTP MCP | oberon サーバで動作、Slack 連携、今回は未連携 |

### Obsidian × AI エージェント連携の既存事例

GitHub `obsidian-mcp` topic に 11 リポジトリ存在。主要なもの:

| プロジェクト | 特徴 | Star |
|---|---|---|
| **enquire-mcp** | 最も高機能。ハイブリッド検索 (BM25 + 埋め込み + BGE リランカー、RRF 融合)、HNSW、HyDE、GraphRAG-light、wikilink graph-boost、freshness-aware。46 ツール、19 プロンプト。HTTP 公開対応。MIT、ローカルファースト | 14 |
| **MegaMem** | Obsidian プラグイン + Neo4j/FalkorDB temporal knowledge graph (Graphiti)。23 MCP ツール。ただし Neo4j 必須 + Obsidian アプリ依存 | 54 |
| **opencode-obsidian-knowledge-workflow** | OpenCode/Claude Code 向けの 7 つの AKU スキル (inbox-triage, connection-review, weekly-synthesis 等)。enquire-mcp と組み合わせて使用 | 8 |
| **vault-cortex** | Docker ベースの standalone MCP server。plugin-free 検索、link graph。OAuth 2.1 対応 | 4 |

**採用**: enquire-mcp。理由:

1. **Grounded memory アプローチ**: vault に書いた `.md` ノートに基づく検索 (チャット抽出型ではない)。Karpathy パターン・Obsidian vault の使い方と親和性が高い
2. **vault ネットワークを活かす**: wikilink graph-boost、GraphRAG-light、backlinks/outbound links 取得ツールが `[[wikilink]]` ネットワークを検索に活用する
3. **ローカルファースト**: サーブ中のクラウ呼び出しゼロ。private vault に適合
4. **MCP ネイティブ**: Claude Code、OpenCode、Hermes Agent 全てが MCP をサポートする共通ブリッジ
5. **HTTP 公開対応**: 将来 Hermes Agent (oberon) 連携時に `serve-http` で Tailscale 経由アクセス可
6. **Karpathy パターンとの相性**: enquire-mcp の README にも「Karpathy-style LLM Wikis のオープンソースバックエンド」という位置づけがある。`index.md` ベースのナビゲーション（〜100 ソース規模）を補強する検索エンジンとして機能

### `enableMcpIntegration` 削除の経緯 (git log 調査)

2 段階の経緯があった:

**段階 1 (2026-05-12, `726976b`)**: `enableMcpIntegration=true` → `false` へ変更
- home-manager の `programs.claude-code` は `enableMcpIntegration=true` の時、claude バイナリを
  `--plugin-dir <hm-plugin>` 付きの bash wrapper で包む
- この `--plugin-dir` フラグが Claude Code v2.1.139 の Agent View TUI を阻害し、起動時に agent 定義の
  静的フォールバック表示に落ちる
- 回避策: `enableMcpIntegration=false` にしつつ、`home.activation` で jq を使い `~/.claude.json` の
  `mcpServers` に直接マージ

**段階 2 (2026-06-09, `1771912`)**: MCP 設定全体を削除
- ローカル MCP サーバ (context7/Figma) が不要になったため、`mcp-servers-nix` flake input、
  `home-manager/programs/mcp-servers` モジュール、`enableMcpIntegration` 参照、`home.activation` jq マージ、
  CLAUDE.md の MCP セクションを全削除

**今回の再試行**: 現在の Claude Code は v2.1.195 (問題があった v2.1.139 から更新あり)。
home-manager も更新されているため、`enableMcpIntegration=true` で Agent View TUI 問題が解消している
可能性を確認する。再発した場合は `home.activation` jq マージ方式にフォールバックする。

### Claude Code Hooks vs OpenCode Plugins

| 操作 | Skill 向き | Hook 向き | 採用 |
|---|---|---|---|
| vault 検索を促す (質問前に vault を検索) | 行動指示・詳細手順 | `UserPromptSubmit` でリマインド注入可能だが毎回トークン消費 | **Skill + memory rule** |
| vault へノート作成 (知見の記録) | エージェントが判断して実行 | `PostToolUse` で自動記録はノイズが多い | **Skill** |
| セッションログ記録 (セッション終了時) | リッチなサマリーを LLM が生成 | `SessionEnd` / `session.idle` でメタデータのみ自動記録 | **Skill のみで開始** |

**判断**: Skills のみで開始する。自動セッションログ記録 (Hook/Plugin) は複雑さが増すため、
vault-session-log Skill をエージェントが能動的に使う運用で始め、必要になったら後から Hook を追加する。

## 設計判断

| 論点 | 採用 | 理由 |
|---|---|---|
| 知識ベース運用パターン | **Karpathy LLM Wiki パターン** | RAG (stateless) ではなく compounding (積み上がる)。既存の `Notes/` + `Clippings/` + `CLAUDE.md` + `research-note` スキルが既にパターンの一部を実装している |
| Obsidian MCP サーバ | **enquire-mcp** | 最も高機能、ローカルファースト、HTTP 公開対応、wikilink graph-boost で vault ネットワークを活かす。Karpathy パターンの検索エンジン層として機能 |
| MCP 設定の共有化 | **home-manager 本体組み込みの `programs.mcp` オプション** | Claude Code と OpenCode の両 HM モジュールが `enableMcpIntegration` で `programs.mcp.servers` を統合可能。1 箇所で定義して 2 ツールに展開。`mcp-servers-nix` flake 等の外部入力は不要（home-manager 本体に組み込み済み） |
| Claude Code MCP 統合方式 | **`enableMcpIntegration = true` を再試行** (フォールバック: `home.activation` jq マージ) | v2.1.195 で TUI 問題が解消している可能性。再発時は jq マージに切り替え |
| 有効化スコープ | **`isPersonal` のみ** (Claude Code) / 既存 `isPersonal` ゲート (OpenCode) | work マシン (SC-N-843) には private vault が存在しない |
| vault 書き込み権限 | **フル書き込み** (`--enable-write`) | ノート作成・編集・wikilink 追加を全て許可。enquire-mcp の 7 つの write ツールを有効化 |
| auto memory | **無効のまま** (MCP 経由で統合) | エージェントが MCP ツール経由で構造的に vault に書き込む方が制御可能。`autoMemoryEnabled=false` は維持 |
| セッションログ自動記録 | **Skills のみで開始** (Hook/Plugin は追加しない) | シンプルさ優先。書き忘れは運用でカバーし、必要になったら Hook を追加 |
| OpenCode plugin 自作 | **しない** | プラグイン不要。OpenCode 側は Skills と MCP と references のみで対応 |
| Hermes Agent 連携 | **当面しない** | enquire-mcp の `serve-http` + Tailscale 経由で後日拡張可能。Phase 2 で検討 |
| enquire-mcp 検索ティア | **Tier 2** (`--persistent-index` のみ、reranker/HNSW は後日) | 初回セットアップ負荷を抑える。TF-IDF + BM25/FTS5 で即活用可。Phase 2 で `--enable-reranker` + `--use-hnsw` にアップグレード |
| **スキルの管理場所** | **dotfiles 側 + vault 側で分離** | dotfiles: 経路B（MCP 経由）で使う汎用スキル (vault-memory, vault-capture, vault-session-log)。vault: 経路A（vault 内）で使う固有スキル (research-note, obsidian-git, vault-lint) |
| **`vault-capture` と既存 `research-note` の関係** | **役割分担** | `research-note` (既存・vault 内): Web 調査を伴う本格 Ingest、信頼できる情報源の裏取り。`vault-capture` (新規・dotfiles): Web 調査を伴わない軽量記録、セッション中の発見・決定の即記録（複利ループ） |
| **vault の CLAUDE.md と dotfiles の user-memory.md** | **責務分離** | vault の CLAUDE.md: vault 固有のスキーマ（ディレクトリ構造・ingest 手順・lint 手順・リンク規約）。dotfiles の user-memory.md: MCP 経由での vault 利用時の基本ルール（enquire-mcp の使い方・スキルの参照） |
| **ナビゲーションファイル** | **`log.md` のみ追加**（`index.md` は Dataview で自動化） | `log.md` は Karpathy パターンの核（時系列・追記専用）。`index.md` は手動更新が破綻しやすいため Obsidian Dataview プラグインの動的クエリに置換。人間は Obsidian でレンダリング、エージェントは enquire-mcp 検索ツールを使用 |

## Architecture

### Karpathy 3 層アーキテクチャによる再構成

```
┌──────────────────────────────────────────────────────────────────────┐
│  Layer 3: The Schema (設定・規約・ワークフロー定義)                    │
│                                                                      │
│  vault 内 CLAUDE.md (既存・拡張)                                      │
│  ├ ディレクトリ構造・リンク規約 (既存)                                 │
│  ├ エージェント共有メモリ層の規約 (新規)                               │
│  ├ index.md / log.md 運用ルール (新規)                                │
│  │   ※ index.md は Dataview 自動生成・log.md は追記専用               │
│  └ 複利ループ・Lint ワークフロー (新規)                               │
│                                                                      │
│  vault 内 .claude/skills/ (既存 + 新規)                               │
│  ├ research-note/ (既存: 本格 Ingest)                                │
│  ├ obsidian-git/   (既存: git 運用)                                  │
│  └ vault-lint/     (新規: 健全性診断)                                │
│                                                                      │
│  dotfiles 側 ~/.claude/skills/ (新規・OpenCode も自動探索)            │
│  ├ vault-memory/       (Query: enquire-mcp 検索 + 複利ループ指示)     │
│  ├ vault-capture/      (軽量記録: セッション中の発見を即記録)          │
│  └ vault-session-log/  (セッションサマリー記録)                       │
│                                                                      │
│  dotfiles 側 user-memory.md / AGENTS.md (新規追記)                    │
│  └ MCP 経由での vault 利用時の基本ルール                              │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│  Layer 2: The Wiki (LLM が全面所有・生成・維持)                       │
│                                                                      │
│  Notes/          (既存: アトミックノート・概念・用語解説)             │
│  Agents/         (新規: エージェント生成物)                           │
│  ├ Claude-Code/sessions/    ├ OpenCode/sessions/                     │
│  ├ Claude-Code/learnings/   ├ OpenCode/learnings/                    │
│  └ Hermes-Agent/            (将来用・空)                              │
│  Shared/         (新規: エージェント間共有知識)                       │
│  ├ decisions/    (技術的決定事項)                                    │
│  ├ research/     (調査結果・深掘り)                                  │
│  └ patterns/     (コードパターン・解決策)                            │
│  log.md          (新規: 時系列ログ・追記専用)                         │
│                                                                      │
│  ※ index.md は Obsidian Dataview プラグインで動的生成                 │
│    (人間はレンダリング、エージェントは Grep/Glob または enquire-mcp で参照) │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│  Layer 1: Raw Sources (不変・読むだけ・真実の源泉)                    │
│                                                                      │
│  Clippings/      (既存: Web Clipper で保存・参照用・編集基本しない)   │
└──────────────────────────────────────────────────────────────────────┘

  【経路A: vault 内 Claude Code】             【経路B: 別プロジェクトから】
  cd vault && claude                          cd ~/some-project && claude
        │                                          │
        │ 標準ツール直接アクセス                   │ enquire-mcp (MCP server)
        │ (Grep/Glob/Read/Edit/Write)              │  stdio (programs.mcp)
        │                                          │  vault へのハイブリッド検索
        ▼                                          │  (BM25+TF-IDF+埋め込み、
  ┌───────────────────┐                            │  wikilink graph-boost)
  │  vault ディレクトリ │                            ▼
  │  (CWD = vault)     │              ┌─────────────────────────┐
  │                    │              │  obsidian_* MCP ツール    │
  │  research-note    │              │  obsidian_search 等       │
  │  vault-lint       │              └───────────┬─────────────┘
  │  obsidian-git     │                          │
  └───────────────────┘                          ▼
                                   ┌───────────────────┐  ┌───────────────────┐
                                   │  Claude Code       │  │  OpenCode          │
                                   │  (Mac, personal)   │  │  (Mac, personal)   │
                                   │                    │  │                    │
                                   │  enableMcpInteg.   │  │  enableMcpInteg.   │
                                   │  + sandbox 権限    │  │  + references      │
                                   │  + dotfiles skills │  │  + dotfiles skills │
                                   │  + user-memory.md  │  │  + AGENTS.md       │
                                   └───────────────────┘  └───────────────────┘
                                   ※ 経路Bでは vault は CWD 外。MCP 経由のみアクセス可
```

### 操作フロー (Karpathy パターン + 2 経路)

```
【経路A】vault 内 Claude Code (cd vault && claude)
  標準ツール直接: Grep / Glob / Read / Edit / Write

Ingest (取り込む) ── 既存 research-note スキルが担当
  ├ Web Clipper → Clippings/ (Layer 1)
  ├ research-note スキル → Grep/Glob で関連ページ検索 → WebSearch/WebFetch で
  │                       信頼できる情報源から裏取り → Notes/ へアトミックノート作成
  ├ (index.md は Dataview が frontmatter から自動生成・手動更新不要)
  └ log.md 追記 ("## [date] ingest | title")

Lint (健全性を保つ) ── 新規 vault-lint スキルが担当
  ├ 矛盾する主張の検出 (Grep で[[用語]]の定義を横断検索)
  ├ 古い主張の更新候補 (Clippings の新情報で陳腐化した Notes)
  ├ 孤立ページ (orphan: Grep で[[pagename]] の被参照を検索)
  ├ 未ページ化概念 (Clippings/Notes で言及されているがページ化されていない概念)
  ├ 不足相互参照の提案 (Edit で[[wikilink]] を追加)
  └ log.md 追記 ("## [date] lint | findings")

【経路B】別プロジェクトからの MCP 経由
  enquire-mcp ツール: obsidian_search / obsidian_create_note 等

Query (問う) ── 新規 vault-memory スキルが担当
  ├ obsidian_search で vault 検索 (ハイブリッド + graph-boost)
  ├ 関連ページを obsidian_get_backlinks / obsidian_read_note で辿る
  ├ 出典付き統合回答を生成
  └ 複利ループ: 良い回答は vault-capture で wiki にファイルし直す
      ├ 再利用可能な知識 → Notes/ または Shared/research/ へ独立ノート化
      ├ 決定事項 → Shared/decisions/ へ
      └ セッション固有 → vault-session-log で Agents/<agent>/sessions/ へ

Capture (記録) ── 新規 vault-capture スキルが担当
  ├ obsidian_create_note / obsidian_append_to_note でノート作成
  └ log.md 追記 ("## [date] capture | title")
```

### enquire-mcp 検索ティア (Phase 1)

| 設定 | 効果 |
|---|---|
| `serve --vault <path>` | TF-IDF cosine (ゼロセットアップ、即時) |
| `+ --persistent-index` | BM25 / FTS5 (sub-100ms top-10) |
| `+ --enable-write` | 7 つの write ツール有効化 (ノート作成・編集・wikilink 追加) |

Phase 2 で `--enable-reranker` (BGE cross-encoder、+15.5 NDCG@10) と `--use-hnsw` (sub-10ms top-K)
を追加予定。初回はモデル DL が不要な Tier 2 で開始する。

### Grep/Glob と enquire-mcp の使い分け（2 経路対応）

| 経路 | シーン | ツール | 理由 |
|---|---|---|---|
| **A. vault 内** | リテラル検索・被リンク検索・ファイル編集 | **Grep / Glob / Read / Edit / Write** | vault が CWD のため直接アクセス可能。正確・高速 |
| **A. vault 内** | キーワード横断・類似ページ探索 | Grep（複数パターン試行）+ Read | enquire-mcp なしでも現規模（数百ノート）は十分 |
| **A. vault 内** | 曖昧な概念検索・広域テーマ探索 (任意) | enquire-mcp `obsidian_search`（任意併用） | 必要な場面のみ。Phase 2 で reranker/HNSW 後に本格導入検討 |
| **B. MCP 経由** | 別プロジェクトからの全 vault 操作 | **enquire-mcp 専用** | vault が CWD 外のため直接アクセス不可 |
| **B. MCP 経由** | 概念検索 | `obsidian_search` / `obsidian_hyde_search` | ハイブリッド検索 + graph-boost が効く |

### 複利ループ（Karpathy パターンの核）

Query で得た良い回答をチャット履歴に消さず、**新しいページとして wiki にファイルし直す**。
探索そのものが、取り込んだソースと同じように積み上がる。

```
ユーザーの質問
  → vault-memory スキルで vault 検索
  → 統合回答を生成（出典付き）
  → 回答の価値を評価:
      ├ 再利用可能な知識・発見した繋がり
      │   → vault-capture スキルで Notes/ または Shared/research/ へ独立ノート化
      │   → [[wikilink]] で関連ノートに接続
      │   → log.md 追記 (index.md は Dataview 自動生成のため手動更新不要)
      ├ 技術的決定事項
      │   → Shared/decisions/ へ独立ノート化
      └ セッション固有の文脈
          → vault-session-log スキルで Agents/<agent>/sessions/ へ
```

これにより、単なる Q&A ではなく「問うた内容が wiki に蓄積し、次回の検索で再利用できる」
複利効果が生まれる。

## 実装手順

### dotfiles 側（本リポジトリで管理）

#### 手順 1: `home-manager/programs/obsidian-vault/default.nix` (新規)

home-manager 本体組み込みの `programs.mcp` オプションで enquire-mcp サーバを定義。`isPersonal` でゲート。
`mcp-servers-nix` 等の外部 flake 入力は不要（`programs.mcp` は home-manager 本体に組み込まれている）。

```nix
{
  pkgs,
  lib,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.mcp = {
    enable = true;
    servers.obsidian-vault = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@oomkapwn/enquire-mcp"
        "serve"
        "--vault"
        "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base"
        "--persistent-index"
        "--enable-write"
      ];
    };
  };
}
```

#### 手順 2: `home-manager/programs/default.nix` (変更)

`./obsidian-vault` を imports に追加:

```nix
{
  ...
}:
{
  imports = [
    ./bat
    ./bottom
    ./claude-code
    ./clock-rs
    ./codex
    ./delta
    ./direnv
    ./fish
    ./fzf
    ./gh
    ./git
    ./htop
    ./jq
    ./lazygit
    ./lsd
    ./mise
    ./neovim
    ./nix-index
    ./obsidian-vault   # ← 追加
    ./opencode
    ./ripgrep
    ./ssh
    ./starship
    ./tmux
  ];
}
```

#### 手順 3: `home-manager/programs/claude-code/default.nix` (変更)

`isPersonal` 時のみ `enableMcpIntegration = true` を追加し、sandbox filesystem に vault パスを追加。
`enableMcpIntegration` は `lib.optionalAttrs isPersonal` で外側ゲート（既存の codex plugin パターンと同一）。

```nix
{
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  inherit (userConfig) isPersonal;
  # ... (既存の let 省略)
in
{
  programs.claude-code = {
    enable = true;
    package = claudeCodePackage;

    settings = {
      # ... (既存設定省略)
      sandbox = {
        # ... (既存設定省略)
        filesystem = {
          allowRead = [
            "~/.ssh/known_hosts"
          ] ++ lib.optionals isPersonal [
            "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base"
          ];
          allowWrite = [
            "/tmp"
            "~/.claude"
            "~/.npm"
            "~/.bun"
            "~/.cache"
            "~/.config"
            "~/.local"
            "~/.codex"
            "~/Library/pnpm"
            "~/Library/Caches/ms-playwright"
          ] ++ lib.optionals isPersonal [
            "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base"
          ];
        };
      };
      # ... (既存設定省略)
    };

    context = ./user-memory.md;
    skills = ./skills;
  }
  # isPersonal 時のみ programs.mcp.servers を統合。
  # 過去に --plugin-dir wrapper が Agent View TUI を破壊した経緯がある
  # (commit 726976b, Claude Code v2.1.139)。v2.1.195 で再試行し、
  # 再発したら enableMcpIntegration=false + home.activation jq マージに切り替える。
  # lib.optionalAttrs は既存の codex plugin 有効化と同じパターン。
  // lib.optionalAttrs isPersonal {
    programs.claude-code.enableMcpIntegration = true;
  };
}
```

#### 手順 4: `home-manager/programs/opencode/default.nix` (変更)

`enableMcpIntegration = true` と `settings.references.vault` を追加。
**`skills` は設定しない** — OpenCode は `~/.claude/skills/` を Claude-compatible パスとして自動探索するため、Claude Code 側の `skills = ./skills;` で展開されたディレクトリをそのまま共用できる。

```nix
{
  pkgs,
  lib,
  sources,
  userConfig,
  ...
}:
lib.mkIf userConfig.isPersonal {
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;

    # programs.mcp.servers (obsidian-vault) を統合
    enableMcpIntegration = true;

    # ... (既存の extraPackages 省略)

    # settings は free-form jsonFormat (typed option ではない)。
    # references / tui / permission などは OpenCode 本体が opencode.json から
    # 読み取る設定キー。home-manager は型検証せずそのまま JSON へ出力する。
    settings = {
      model = "opencode-go/glm-5.2";
      autoupdate = false;
      share = "manual";
      snapshot = true;

      # ... (既存の compaction, permission, watcher 省略)

      # Obsidian vault を reference として公開。
      # @vault 補完で直接ファイル参照可能。MCP ツール (obsidian_*) は
      # 概念検索向き、references はリテラルパス参照向き。
      references = {
        vault = {
          path = "${userConfig.homeDir}/src/github.com/thinceller/knowledge-base";
          description = "Obsidian knowledge vault (Karpathy LLM Wiki pattern) — Notes/, Clippings/, Agents/, Shared/. Search via obsidian-vault MCP tools for conceptual recall, or use @vault for direct file access.";
        };
      };
    };

    # ... (既存の tui, context 省略)

    # skills は設定しない。OpenCode は ~/.claude/skills/ を自動探索する
    # (Claude-compatible パス)。Claude Code 側の skills = ./skills; で
    # ~/.claude/skills/ に展開された vault-memory / vault-capture /
    # vault-session-log が OpenCode でもそのまま利用可能。
    # 既存の team-task, playwright-cli も同様に共用される。
  };

  # ... (既存の xdg.configFile plugin 省略)
}
```

#### 手順 5: `home-manager/programs/claude-code/user-memory.md` (変更)

末尾に vault 利用ルールを追加。`obsidian_search` ツールが利用可能な場合のみ適用される条件付き表記。
vault 固有の詳細ルールは vault 内の CLAUDE.md に委ねる（二重管理を回避）。

```markdown
## Obsidian Vault (共有メモリ・Karpathy LLM Wiki パターン)

`obsidian_search` ツールが利用可能な場合 (personal machines のみ):

- vault は「育つ知識ベース」(LLM Wiki)。RAG のように毎回ゼロから再計算するのではなく、
  知識が一度コンパイルされ最新に保たれる
- 質問が自分のノート、決定事項、プロジェクト、調査内容に関わる場合、**最初に `obsidian_search` で vault を検索**すること
- 汎用的な知識や調べた内容は `vault-capture` skill を使って vault に記録（複利ループ）
- セッションの重要な知見は `vault-session-log` skill で記録
- 各ノートには `[[wikilink]]` で関連ノートをリンクし、ネットワークを構築
- 引用時はソースノートのパスを明記
- vault に未発見の知識は「見つからなかった」と明言し、推測しない
- vault 内で起動した時は vault の CLAUDE.md と research-note スキルも参照すること
```

#### 手順 6: `home-manager/programs/opencode/AGENTS.md` (変更)

同じ vault 利用ルールを追加。

#### 手順 7: Skills 新規作成 (3 つ、dotfiles 側・Claude Code と OpenCode で共用)

##### `home-manager/programs/claude-code/skills/vault-memory/SKILL.md`

Query ワークフロー。enquire-mcp 経由の vault 検索と複利ループ（良い回答の wiki ファイル化）を担う。

```markdown
---
name: vault-memory
description: Search the Obsidian knowledge vault (Karpathy LLM Wiki pattern) via enquire-mcp before answering questions about personal notes, decisions, projects, people, or research. Only invoke when the `obsidian_search` MCP tool is available (personal machines). Use when the user asks about anything that might be in their notes. Then file good answers back into the wiki (compounding loop).
---

# Vault Memory (Query + Compounding Loop)

**Prerequisite**: This skill requires the `obsidian_search` MCP tool (enquire-mcp).
If `obsidian_search` is not available in your tool list, do not use this skill.

Search the Obsidian vault (long-term memory) before answering questions that might
relate to existing notes, decisions, research, or session logs. Then file valuable
answers back into the wiki so knowledge compounds across sessions.

## When to Use

Use this skill when the user's question touches:

- Past decisions or technical choices
- Research or investigations you (or another agent) previously did
- Project context, architecture, or conventions
- People, tools, or workflows mentioned in notes
- "What did I say about X" / "How did we decide Y" style queries

## How to Search

### 1. Start with `obsidian_search` (umbrella tool, RRF-fused)

Call `obsidian_search` with the key terms of the question. It fuses BM25, TF-IDF,
and ML embeddings automatically. Every hit returns `per_signal` scores so you can
see why each note ranked.

### 2. Use specialized tools when needed

- `obsidian_hyde_search` — for vague or conceptual queries. Pre-rewrites the query
  into a rich hypothetical answer before retrieval.
- `obsidian_get_backlinks` / `obsidian_get_outbound_links` — to explore the
  `[[wikilink]]` neighborhood of a relevant note.
- `obsidian_get_note_neighbors` — one-step graph neighbors.
- `obsidian_get_communities` — topical communities (GraphRAG-light) to discover
  themes in the vault.
- `obsidian_find_path` — find a connection path between two notes.
- `obsidian_frontmatter_search` — filter by frontmatter fields (tags, type, dates).

### 3. Cite sources

Every fact drawn from the vault must cite the source note path:

> "According to `Notes/ROI (投資利益率).md`, ROI is calculated as..."

### 4. When nothing is found

If no relevant note exists, say so explicitly. Do not guess or fabricate. Suggest
creating a new note with `vault-capture` if the information is worth keeping.

## Compounding Loop (Karpathy Pattern Core)

**Good answers are not discarded into chat history. They are filed back into the
wiki as new pages so knowledge compounds.**

After generating an answer, evaluate its value using these **concrete criteria**.
File back only if at least one applies:

- **Integrates 2+ sources**: The answer synthesizes information from multiple vault
  notes or external sources into a unified analysis
- **Contains named facts**: Specific numbers, proper nouns, dates, or code identifiers
  that would be tedious to re-derive
- **Repeatable question**: The user (or another session) is likely to ask the same
  or a similar question in the future
- **Discovered connection**: The answer reveals a non-obvious relationship between
  notes that wasn't previously linked

If none apply (trivial Q&A, one-off context), do NOT file — leave it in chat.

| Answer type | Action | Destination |
|---|---|---|
| Reusable knowledge / discovered connections | Create independent note via `vault-capture` | `Notes/` or `Shared/research/` |
| Technical decision | Create decision note via `vault-capture` | `Shared/decisions/` |
| Session-specific context | Log via `vault-session-log` | `Agents/<agent>/sessions/` |
| Trivial / one-off Q&A | Do not file | (chat only) |

When filing back:
- Connect with `[[wikilink]]` to related notes
- Append to `log.md`: `## [YYYY-MM-DD] query | <short description>`
- (index.md is auto-generated by Dataview — no manual update needed)

This turns exploration itself into a compounding asset, exactly like ingested sources.

## What NOT to Use This Skill For

- Literal string / regex search → use `ripgrep` / `grep` directly (faster, exact)
- Code in the current project → use `Grep` / `Glob` / `Read` tools
- General knowledge not in the vault → use `WebSearch` / `WebFetch`
- Full web research with source verification → use `research-note` skill (vault-internal)
```

##### `home-manager/programs/claude-code/skills/vault-capture/SKILL.md`

軽量記録ワークフロー。Web 調査を伴わない、セッション中の発見・決定の即記録。既存の
`research-note`（本格 Web 調査）と役割分担。

```markdown
---
name: vault-capture
description: Record knowledge into the Obsidian vault without full web research. Only invoke when the `obsidian_search` MCP tool is available (personal machines). Use for session discoveries, decisions, patterns, or insights worth keeping. Lightweight companion to the vault-internal research-note skill (which does full source-verified web research).
---

# Vault Capture (Lightweight Record)

**Prerequisite**: This skill requires the `obsidian_create_note` MCP tool (enquire-mcp).
If MCP tools are not available, do not use this skill.

Record knowledge worth keeping into the Obsidian vault using enquire-mcp write tools.
This is the **lightweight** recording skill — no web research, just filing what you
already know or discovered in this session.

## When to Use

- You discovered a reusable insight during this session (not project-specific)
- A decision was made (technical, architectural, workflow)
- You found a code pattern or solution worth remembering
- The user explicitly asks you to "remember this" or "note this down"
- **Compounding loop**: a `vault-memory` query produced a valuable answer worth filing

## When NOT to Use

- Full web research with source verification → use `research-note` skill (vault-internal)
- Project-specific code changes → those live in the project repo, not the vault
- Ephemeral session context → use `vault-session-log` instead
- Trivial facts easily re-discovered

## Relationship to research-note (vault-internal)

| Aspect | `vault-capture` (this skill, dotfiles) | `research-note` (vault-internal) |
|---|---|---|
| Web research | No | Yes (multi-source, fact verification) |
| Source priority table | No | Yes (official docs > Wikipedia > blogs) |
| Sources section required | No | Yes (minimum 2 sources) |
| Use case | Session discoveries, decisions, quick capture | Deep research, term explanations, concept pages |
| Tools | enquire-mcp write tools (`obsidian_create_note` etc.) | Grep/Glob + WebSearch/WebFetch + file write |

**Boundary rule**: If you start `vault-capture` and realize you need `WebSearch` to
verify facts, **stop immediately** and switch to the `research-note` skill (which
requires running Claude Code inside the vault). `vault-capture` is for filing what
you already know — not for researching new information.

If the user asks for deep research with reliable sources, suggest they run Claude Code
inside the vault and use the `research-note` skill instead.

## Directory Structure

Choose the right location for the note:

| Content type | Path |
|---|---|
| Reusable concept / term (atomic) | `Notes/<topic>.md` |
| Agent-specific learnings | `Agents/<Claude-Code\|OpenCode>/learnings/<topic>.md` |
| Technical decisions | `Shared/decisions/<topic>.md` |
| Research results (session-discovered) | `Shared/research/<topic>.md` |
| Code patterns / solutions | `Shared/patterns/<topic>.md` |

> **Note**: `Notes/` follows the vault's existing atomic note convention (1 page 1 topic,
> flat structure, `[[wikilink]]` links). See the vault's `CLAUDE.md` for details.

## Frontmatter

Every new note must include frontmatter. **Get the current timestamp by running
`date -Iseconds` in Bash** (LLM does not have a built-in clock):

```bash
$ date -Iseconds
2026-06-28T14:30:00+09:00
```

```yaml
---
created: <output of `date -Iseconds`>
tags:
  - <relevant-tag>
type: <learning|decision|research|pattern|session-log>
agent: <Claude-Code|OpenCode|Hermes-Agent>
---
```

## Creating a Note

Use `obsidian_create_note`:

```
obsidian_create_note(
  path: "Shared/decisions/postgres-vs-mongo.md",
  content: "---\ncreated: 2026-06-28T...\ntags: [database, decision]\ntype: decision\nagent: Claude-Code\n---\n\n# PostgreSQL vs MongoDB\n\n<content with [[wikilinks]]>"
)
```

## Appending to a Note

Use `obsidian_append_to_note` when adding to an existing note.

## Wikilinks

Connect the new note to related notes using `[[wikilink]]` syntax in the body:

```markdown
We chose PostgreSQL for this project. See [[Notes/ROI (投資利益率)]] for the
cost analysis, and [[Shared/patterns/db-migration]] for the rollout pattern.
```

This builds the vault's knowledge graph. enquire-mcp's wikilink graph-boost will
surface well-connected notes in future searches.

## After Creating

1. Confirm the note path to the user
2. Append to `log.md`: `## [YYYY-MM-DD] capture | <short description>`
3. Update `index.md` if the note is a significant new entry
```

##### `home-manager/programs/claude-code/skills/vault-session-log/SKILL.md`

セッションサマリー記録ワークフロー。

```markdown
---
name: vault-session-log
description: Record a session summary into the Obsidian vault at the end of a productive session. Only invoke when the `obsidian_create_note` MCP tool is available (personal machines). Use when the session produced meaningful changes, decisions, or learnings worth referencing later.
---

# Vault Session Log

**Prerequisite**: This skill requires the `obsidian_create_note` MCP tool (enquire-mcp).
If MCP tools are not available, do not use this skill.

Write a structured session summary to the vault at session end (or when the user
asks you to "log this session").

## When to Use

- The session produced non-trivial code changes or architectural decisions
- Research or investigation worth referencing in future sessions
- The user explicitly requests a session log
- You learned something about the user's environment or preferences

## When NOT to Use

- Trivial sessions (quick Q&A, single-file edits)
- Sessions where nothing reusable was learned
- The user did not ask for a log and nothing significant happened

## File Path

```
Agents/<Claude-Code|OpenCode>/sessions/YYYY-MM-DD_HH-MM_<short-description>.md
```

Example: `Agents/Claude-Code/sessions/2026-06-28_14-30_obsidian-vault-mcp-setup.md`

Use 24-hour JST timestamp. Keep the description short (kebab-case, 3-5 words).
**Get the current timestamp by running `date -Iseconds` in Bash** (LLM does not
have a built-in clock):

```bash
$ date -Iseconds
2026-06-28T14:30:00+09:00
```

## Frontmatter

```yaml
---
created: <output of `date -Iseconds`>
tags:
  - session-log
type: session-log
agent: Claude-Code
---
```

## Content Structure

```markdown
# <Session Title>

## Summary
<2-3 sentence overview of what was accomplished>

## Changes
- <file or system changed, with brief context>

## Decisions
- [[<decision-note>]]: <one-line decision rationale>
  (create a separate decision note in Shared/decisions/ if the decision is reusable)

## Learnings
- [[<learning-note>]]: <one-line insight>
  (create a separate learning note in Agents/<agent>/learnings/ if reusable)

## Follow-ups
- [ ] <action item for a future session>
```

## Workflow

1. Create the session log note with `obsidian_create_note`
2. For each Decision and Learning, if it's reusable beyond this session, create a
   separate note in the appropriate directory and link to it with `[[wikilink]]`
   (use `vault-capture` skill for the independent notes)
3. Append to `log.md`: `## [YYYY-MM-DD] session | <short description>`
4. Confirm the session log path to the user
```

#### 手順 8: `configs/.config/cage/presets.yaml` (変更)

vault パスを cage の allow リストに追加。
**Claude Code は `cage claude`（cage 経由）と素の `claude`（組み込み sandbox 経由）の 2 つの起動ルートがあるため、両方の filesystem 権限設定を更新する必要がある**（手順 3 で組み込み sandbox 側、ここで cage 側）。

```yaml
presets:
  claude-code:
    allow:
      # ... (既存リスト省略)
      # Obsidian Vault (enquire-mcp + agent file access)
      - "$HOME/src/github.com/thinceller/knowledge-base"
```

### vault 側（knowledge-base リポジトリ・ユーザー手動作業）

以下は dotfiles の管理外。knowledge-base リポジトリでユーザーが手動で実施する。

#### 手順 V1: ディレクトリ構造作成

```bash
cd ~/src/github.com/thinceller/knowledge-base
mkdir -p Agents/Claude-Code/sessions Agents/Claude-Code/learnings
mkdir -p Agents/OpenCode/sessions Agents/OpenCode/learnings
mkdir -p Agents/Hermes-Agent
mkdir -p Shared/decisions Shared/research Shared/patterns
# 空ディレクトリを git 管理対象にするため .gitkeep を配置
touch Agents/Hermes-Agent/.gitkeep
```

#### 手順 V2: `index.md` 作成 (ルート・新規・Dataview ベース)

内容カタログ。**Obsidian Dataview プラグインの動的クエリで自動生成**する。
frontmatter の `created` / `type` / `tags` / `agent` フィールドから自動的に表が生成されるため、
手動更新は不要（ingest / capture 時に frontmatter を正しく書くだけでカタログが最新に保たれる）。

> **前提**: Obsidian Dataview プラグインがインストール済みであること。
> エージェントは Dataview のレンダリング結果ではなく enquire-mcp 検索ツール
> (`obsidian_search` / `obsidian_list_notes` / `obsidian_stats`) でカタログ情報を取得する。

```markdown
# Vault Index

> 自動生成カタログ（Dataview）。手動編集不要。
> Query 時は enquire-mcp `obsidian_search` で概念検索するか、以下を Obsidian で参照。

## Notes (アトミックノート・概念・用語)

```dataview
TABLE created, type, tags FROM "Notes" SORT created DESC
```

## Clippings (Web Clip・参照用)

```dataview
TABLE created, tags FROM "Clippings" SORT created DESC
```

## Shared/decisions (技術的決定事項)

```dataview
TABLE created, agent, tags FROM "Shared/decisions" SORT created DESC
```

## Shared/research (調査結果)

```dataview
TABLE created, agent, tags FROM "Shared/research" SORT created DESC
```

## Shared/patterns (コードパターン)

```dataview
TABLE created, agent, tags FROM "Shared/patterns" SORT created DESC
```

## Agents (エージェント生成物)

### Claude-Code learnings

```dataview
TABLE created, tags FROM "Agents/Claude-Code/learnings" SORT created DESC
```

### Claude-Code sessions

```dataview
TABLE created, tags FROM "Agents/Claude-Code/sessions" SORT created DESC
```

### OpenCode learnings

```dataview
TABLE created, tags FROM "Agents/OpenCode/learnings" SORT created DESC
```

### OpenCode sessions

```dataview
TABLE created, tags FROM "Agents/OpenCode/sessions" SORT created DESC
```
```

#### 手順 V3: `log.md` 作成 (ルート・新規)

時系列ログ。追記専用。`## [YYYY-MM-DD] type | title` 形式。

```markdown
# Vault Log

> 時系列ログ。ingest / query / capture / lint / session を追記専用で記録。
> unix ツールで解析可能: `grep "^## \[" log.md | tail -5`

## [2026-06-28] setup | Obsidian Vault 共有エージェントメモリ初期化
```

#### 手順 V4: vault 内 `CLAUDE.md` 拡張

既存の CLAUDE.md に以下のセクションを追加:

```markdown
## エージェント共有メモリ (Karpathy LLM Wiki パターン)

この vault は Claude Code / OpenCode / Hermes Agent の共有メモリとしても運用する。
Karpathy の LLM Wiki パターン（RAG ではなく、LLM が恒久的な wiki を構築・維持する）
に沿って、知識が積み上がる構造にする。

### 3 層構造

| 層 | ディレクトリ | 役割 |
|---|---|---|
| Layer 1: Raw sources | `Clippings/` | 不変・読むだけ・真実の源泉 |
| Layer 2: The wiki | `Notes/`, `Agents/`, `Shared/`, `log.md` | LLM が全面所有・生成・維持（`index.md` は Dataview 自動生成） |
| Layer 3: The schema | `CLAUDE.md`, `.claude/skills/` | 構造・規約・ワークフロー定義 |

### エージェント生成物のディレクトリ

- `Agents/<agent>/sessions/` — セッションログ (YYYY-MM-DD_HH-MM_<desc>.md)
- `Agents/<agent>/learnings/` — エージェント固有の汎用知見
- `Shared/decisions/` — 技術的決定事項
- `Shared/research/` — 調査結果・深掘り
- `Shared/patterns/` — コードパターン・解決策

### ナビゲーションファイル

- `index.md` — 内容カタログ（**Dataview プラグインで frontmatter から自動生成**）。
  手動更新不要。人間は Obsidian でレンダリング、エージェントは enquire-mcp 検索ツールを使用。
- `log.md` — 時系列ログ（**追記専用・手動**）。`## [YYYY-MM-DD] type | title` 形式。
  unix ツールで解析可能: `grep "^## \[" log.md | tail -5`

### 3 つの操作

#### Ingest（取り込む）
新ソースを `Clippings/` に置き、`research-note` スキルで `Notes/` へアトミックノート化。
`log.md` に追記（`index.md` は Dataview が frontmatter から自動生成するため手動更新不要）。

#### Query（問う）
vault に質問する。`vault-memory` スキル (enquire-mcp) または Grep/Glob で関連ページを探し、
出典付きで統合回答する。**良い回答は新しいページとして wiki にファイルし直す（複利ループ）**。
`vault-capture` スキルで `Notes/` または `Shared/` へ独立ノート化。

#### Lint（健全性を保つ）
`vault-lint` スキルで定期診断。矛盾・古い主張・孤立ページ・未ページ化概念・不足相互参照を検出。
`log.md` に追記。

### 経路Aの場合（vault 内 Claude Code・推奨: Grep/Glob 直接）

- **Grep / Glob / Read / Edit / Write**: vault が CWD のため直接アクセス可能。
  リテラル検索・被リンク検索・ファイル編集全てこちらで対応。
- **enquire-mcp** (`obsidian_search` 等): **任意併用**。概念検索が必要な場面のみ。
  Phase 2 で reranker/HNSW を入れた後に本格導入検討。

### 経路Bの場合（別プロジェクトからの MCP 経由・enquire-mcp 専用）

- **enquire-mcp 专用**: vault が CWD 外のため直接アクセス不可。
  `obsidian_search` / `obsidian_create_note` 等 で全操作を実行。
```

#### 手順 V5: `.claude/skills/vault-lint/SKILL.md` 作成 (vault 内・新規)

健全性診断ワークフロー。vault 内で Claude Code を起動した時に使用。

```markdown
---
name: vault-lint
description: Diagnose the health of the Obsidian vault (Karpathy LLM Wiki pattern). Detect contradictions, stale claims, orphan pages, un-paged concepts, and missing cross-references. Use when asked to "lint", "check vault health", "find orphans", or periodically maintain wiki quality.
---

# Vault Lint (Health Diagnosis)

Diagnose the vault's health as a compounding knowledge base. Detect issues that
degrade the wiki over time and propose fixes.

## When to Use

- User asks to "lint", "check vault health", "find orphans", "clean up"
- Periodic maintenance (e.g. weekly / after major ingest batches)
- Before a major research session to ensure the wiki is clean

## What to Detect

### 1. Contradictions
Find notes that make conflicting claims about the same topic.
- Search for notes on the same concept (Grep + enquire-mcp `obsidian_search`)
- Compare definitions, numbers, recommendations
- Report: `[[noteA]] says X, [[noteB]] says Y — contradiction?`

### 2. Stale claims
Notes whose claims may have been superseded by newer Clippings or Notes.
- Check `Clippings/` for newer sources on topics covered in `Notes/`
- Check `last_modified` via enquire-mcp `obsidian_stale_notes`
- Report: `[[note]] may be stale — [[clipping]] has newer info on this topic`

### 3. Orphan pages (被リンクなし)
Notes with no incoming links. These are disconnected from the knowledge graph.
- Use enquire-mcp `obsidian_get_backlinks` for each note, or Grep for `[[note name]]`
- Report: `[[note]] has 0 backlinks — consider linking from related pages`
- Fix: propose which related pages should link to it

### 4. Un-paged concepts (未ページ化概念)
Concepts mentioned in Clippings/Notes but not yet given their own page.
- Extract frequently-mentioned terms (Grep for term frequency, or enquire-mcp
  `obsidian_get_communities` for topical clusters)
- Cross-reference with existing `Notes/` filenames
- Report: `"X" is mentioned in N notes/clippings but has no dedicated page`

### 5. Missing cross-references
Related notes that should link to each other but don't.
- For each note, find semantically related notes (enquire-mcp `obsidian_find_similar`)
- Check if `[[wikilink]]` exists between them
- Report: `[[noteA]] and [[noteB]] are related but not linked`

### 6. Data gaps (Web で埋められる空白)
Topics in the wiki that have incomplete coverage.
- Identify notes with thin content or "TODO" markers
- Suggest web searches that could fill the gaps
- Report: `[[note]] is thin — suggest researching X, Y, Z`

## Workflow

1. Run all 6 checks above
2. Summarize findings in a report (markdown table or list)
3. For each finding, propose a concrete fix:
   - Contradiction → which note to update / flag for user review
   - Stale → propose update based on newer source
   - Orphan → propose which pages should link to it
   - Un-paged → propose new note creation (use `research-note` skill)
   - Missing cross-ref → propose editing both notes to add `[[wikilink]]`
4. **Confirm with user before making changes** (per CLAUDE.md operation policy)
5. After fixes, append to `log.md`:
   `## [YYYY-MM-DD] lint | <findings summary>`

## Tools

基本（経路A・vault 内・標準ツール直接）:
- **Grep / Glob**: `[[wikilink]]` 被参照検索、用語出現頻度、ファイル名検索
- **Read**: ノート内容の比較（矛盾検出用）
- **Edit**: 不足相互参照の追加（ユーザー確認後）

任意併用（概念検索が必要な場面のみ・enquire-mcp が programs.mcp で有効化済み）:
- **enquire-mcp**: `obsidian_search`, `obsidian_get_backlinks`,
  `obsidian_stale_notes`, `obsidian_get_communities`, `obsidian_find_similar`
```

#### 手順 V6: 既存 `research-note` スキルの微調整（オプション）

既存の `research-note` スキルは Grep/Glob ベースで本方針と完全合致。変更は以下のみ:

```markdown
### 2. 既存の関連ページを先に探す

（既存の Grep/Glob 手順そのまま使用。リテラル検索には Grep/Glob が高速・正確）

**任意併用（概念検索が必要な場面のみ・enquire-mcp が有効化済みの場合）**:
- `obsidian_search` で概念検索（ハイブリッド + graph-boost）
- Grep/Glob の補完として使用。メインは Grep/Glob のまま
```

さらに、`research-note` スキルのステップ終了時に `log.md` の更新を追加:

```markdown
### 8. log.md を更新する（新規）

ノート作成・加筆後:
- `log.md` に追記: `## [YYYY-MM-DD] ingest | <title>`
- (index.md は Dataview が frontmatter から自動生成するため手動更新不要)
```

## リスクとフォールバック

| リスク | 確率 | フォールバック |
|---|---|---|
| `enableMcpIntegration=true` で Agent View TUI 破壊 | 中 (v2.1.139→v2.1.195 で改善の可能性) | `enableMcpIntegration=false` + `home.activation` jq マージ方式に切り替え (下記参照) |
| enquire-mcp 初回起動失敗 (npx ダウンロード) | 低 | ユーザーが手動で `npx -y @oomkapwn/enquire-mcp setup --vault <path>` を実行 |
| vault パスが work マシンに存在しない | なし | `lib.mkIf isPersonal` で完全ゲート済み |
| OpenCode で `team-task` / `playwright-cli` スキルが不要 | 低 | `skills` オプションを vault 系 3 つのみに絞る (個別指定) |
| `vault-capture` と `research-note` の役割境界が曖昧 | 低 | 両スキルの description に「Web 調査あり/なし」を明記済み。運用で調整 |
| enquire-mcp の `obsidian_search` 精度が低い (Tier 2) | 中 | Phase 2 で `--enable-reranker` + `--use-hnsw` にアップグレード。それまでは Grep/Glob 併用 |

### フォールバック: `home.activation` jq マージ方式

`enableMcpIntegration=true` で TUI 問題が再発した場合、以下に切り替える:

```nix
# home-manager/programs/claude-code/default.nix
{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  inherit (userConfig) isPersonal;
in
{
  programs.claude-code = {
    # ...
    enableMcpIntegration = false;  # ← false に戻す
    # ...
  };

  # programs.mcp.servers を user スコープ (~/.claude.json mcpServers) に jq マージ。
  # Claude Code は ~/.claude.json を稼働中の状態ファイルとして書き換えるため、
  # 全置換は不可。jq でキー単位に merge する。
  home.activation.claudeCodeMcpUserScope = lib.mkIf isPersonal (
    let
      mcpJson = builtins.toJSON (config.programs.mcp.servers or { });
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CLAUDE_JSON="$HOME/.claude.json"
      if [ ! -f "$CLAUDE_JSON" ]; then
        echo '{}' > "$CLAUDE_JSON"
      fi
      TMP="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.jq}/bin/jq \
        --argjson new ${lib.escapeShellArg mcpJson} \
        '.mcpServers = ((.mcpServers // {}) * $new)' \
        "$CLAUDE_JSON" > "$TMP"
      ${pkgs.coreutils}/bin/mv "$TMP" "$CLAUDE_JSON"
    ''
  );
}
```

## 検証手順

### 1. ビルド検証

```bash
# personal ホスト
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link

# work ホスト (obsidian-vault モジュールがスキップされることを確認)
nix build .#darwinConfigurations.SC-N-843.system --no-link
```

### 2. フォーマット

```bash
nix fmt
```

### 3. 適用

```bash
sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
```

### 4. Agent View TUI 動作確認 (リスク確認)

```bash
claude agents
# TUI が正常に開くか確認。静的フォールバック表示に落ちたら
# enableMcpIntegration=true が原因。フォールバック (jq マージ) に切り替え。
```

### 5. Claude Code MCP ツール認識確認

```bash
claude --print "List available MCP tools" 2>&1 | grep -i obsidian
# obsidian_search, obsidian_create_note 等が表示されることを確認
```

### 6. OpenCode MCP 認識確認

```bash
opencode
# 起動後、settings.mcp に obsidian-vault が表示されることを確認
# @vault 補完が効くことを確認
```

### 7. enquire-mcp 初回セットアップ (ユーザー手動)

```bash
# モデル DL + インデックス構築 (初回のみ)
# 所要時間は vault 規模による: ~100 ノートなら数秒、50k ノートなら ~30s
# (FTS5 構築 5s/1k notes、埋め込み生成 30ms/chunk on M1)
npx -y @oomkapwn/enquire-mcp setup --vault ~/src/github.com/thinceller/knowledge-base

# ヘルスチェック
npx -y @oomkapwn/enquire-mcp doctor --vault ~/src/github.com/thinceller/knowledge-base
```

### 8. Skills 認識確認

```bash
# Claude Code
claude
# /skills または skill tool で vault-memory, vault-capture, vault-session-log が表示されることを確認

# OpenCode
opencode
# skill tool で同じ 3 つのスキルが表示されることを確認

# vault 内で Claude Code 起動時
cd ~/src/github.com/thinceller/knowledge-base && claude
# /skills で vault-lint (vault 内) + vault-memory/capture/session-log (dotfiles) +
# research-note, obsidian-git (vault 内) が全て表示されることを確認
```

### 9. 複利ループ動作確認

```bash
# 別プロジェクトで Claude Code 起動
cd ~/some-project && claude
# 「ROI について私のノートに何かある？」と質問
# → vault-memory スキルが obsidian_search で検索
# → 出典付き回答
# → 回答が再利用可能なら vault-capture で Notes/ または Shared/ へ記録提案
```

## ユーザー手動作業 (適用後)

### dotfiles 適用

1. `sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini`
2. `npx -y @oomkapwn/enquire-mcp setup --vault ~/src/github.com/thinceller/knowledge-base`
   (初回のみ、モデル DL + インデックス構築)
3. `claude agents` で TUI 動作確認 → 問題あればフォールバックへ

### vault 側セットアップ (knowledge-base リポジトリ)

4. ディレクトリ構造作成:
   ```bash
   cd ~/src/github.com/thinceller/knowledge-base
   mkdir -p Agents/Claude-Code/sessions Agents/Claude-Code/learnings
   mkdir -p Agents/OpenCode/sessions Agents/OpenCode/learnings
   mkdir -p Agents/Hermes-Agent
   mkdir -p Shared/decisions Shared/research Shared/patterns
   ```
5. `index.md`, `log.md` 作成（手順 V2, V3 参照）
6. `CLAUDE.md` 拡張（手順 V4 参照）
7. `.claude/skills/vault-lint/SKILL.md` 作成（手順 V5 参照）
8. (オプション) 既存 `research-note` スキルに enquire-mcp 追加（手順 V6 参照）
9. knowledge-base リポジトリの README にディレクトリ構造の説明を追加
10. git commit & push

## Phase 2 拡張 (将来)

| 項目 | 内容 |
|---|---|
| enquire-mcp 検索ティア 4-5 | `--enable-reranker` (BGE cross-encoder、+15.5 NDCG@10) + `--use-hnsw` (sub-10ms top-K)。モデル DL 必要 |
| Hermes Agent 連携 | enquire-mcp `serve-http` + Tailscale Funnel / Cloudflare Tunnel 経由で oberon からアクセス。`Agents/Hermes-Agent/` ディレクトリ本格利用。enquire-mcp 公式ドキュメント（`docs/http-transport.md`）に Tailscale Funnel / Cloudflare Tunnel での HTTPS 公開例が明示されている |
| 自動セッションログ | `SessionEnd` hook (Claude Code) / `session.idle` plugin (OpenCode) でセッション終了時の自動メタデータ記録。書き忘れ防止のセーフティネット |
| AKU ワークフロースキル | `opencode-obsidian-knowledge-workflow` の 7 スキル (inbox-triage, connection-review, weekly-synthesis, context-maintenance, vault-health-feedback, note-promotion) を導入。vault 運用の自動化 |
| Obsidian Git plugin 自動同期 | vault の自動同期 + エージェントからの git push。Mac ↔ oberon 間で vault を共有する場合に有効 |
| 複利ループの自動化 | `Stop` hook でセッション終了時に「このセッションで再利用可能な知見はあるか？」を LLM に評価させ、あれば自動で vault-capture をトリガー |
| Dataview 活用 | frontmatter の tags/type/agent/dates を使って Obsidian 内で動的なインデックス・ダッシュボードを生成。`index.md` の手動更新を補完 |
