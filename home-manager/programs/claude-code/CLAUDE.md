# Claude Code User Memory

This file contains personal preferences and settings for Claude Code across all projects.

## Git Worktree Rules

**IMPORTANT**: When a session is started within a git worktree, all file exploration, reading, and editing MUST be performed within the worktree directory.

- Always use the CWD (current working directory) at session start as the project root
- If the CWD is under `.claude/worktrees/`, that path is the project root
- NEVER directly read or write files in the git root (the original repository path)
- CLAUDE.md and other configuration files MUST be referenced and edited within the worktree

## Personal Code Style Preferences

## 設計原則の優先順位

リファクタリングやコード設計において、以下の優先順位を常に念頭に置いてください：

1. **単純性 > 複雑性**
   - シンプルで理解しやすい解決策を選ぶ
   - 過度な抽象化や設計パターンの適用を避ける

2. **明確性 > 抽象性**
   - コードの意図が明確に伝わることを重視
   - 汎用性のための複雑さよりも、具体的で分かりやすい実装を優先

3. **実用性 > 理論性**
   - 実際の問題解決に焦点を当てる
   - 理論的に完璧でも実用的でない設計は避ける

## リファクタリング時の確認事項

コードの改善を行う際は、以下の観点で必ず確認してください：

- **ファイル間の呼び出し階層が適切か**: 3層以上の深い階層は見直し対象
- **各ファイルが明確な責任を持っているか**: 単一責任の原則に従っている
- **テスタビリティが確保されているか**: 依存性注入やモック可能な設計
- **冗長な中間層がないか**: 薄いラッパーや意味のない中継層は統合を検討

## コード改善

**重要**: コードの実装が完了したら、code-simplifier:code-simplifier subagentを使用してコードの改善を行ってください。

### 実行タイミング
- 実装コードの編集が完了した後、動作確認の前
- Planモードで実装計画を立てる際は、code-simplifier:code-simplifier実行ステップを必ず計画に含める
- Todoリストを作成する際は、code-simplifier:code-simplifierによる改善タスクを必ず追加する

### 実行方法
- Task toolを使用してcode-simplifier:code-simplifier subagentを起動する（subagent_type: "code-simplifier:code-simplifier"）
- 対象は直近で変更したコードファイル

## 動作確認

**重要**: コードの変更後は、変更の大小に関わらず必ず動作確認を行ってください。

### 確認タイミング
- コード変更を実装した直後
- Planモードで実装計画を立てる際は、動作確認ステップを必ず計画に含める
- Todoリストを作成する際は、動作確認タスクを必ず追加する

### 確認方法
- 変更内容に応じた適切な動作確認を実施する（ビルド、テスト、リント、実際の動作など）
- プロジェクトにテストやCI設定がある場合は必ず実行する
- 動作確認なしにタスクを「完了」としない
