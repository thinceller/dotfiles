# herdr プロジェクトランチャー 実装プラン

> **Status**: 実装完了 (2026-07-18)。nix build 両ホスト + nix fmt + fish -n +
> code-simplifier パス、ユーザーが適用・動作確認済み。pr-review モードには実装後に
> 「自分宛てレビュー依頼 (`review-requested:@me`) 優先 + 0 件なら全 PR フォールバック」を追加。
> 実装時の確認事項 1〜4 は解決済み (下記に追記)。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ghq 管理下のリポジトリを fzf で選択し、herdr workspace として定型レイアウト (agent タブ + editor タブ) で開くランチャーを 1 keybind で起動できるようにする。「新規 worktree で claude 作業」「他エンジニアの PR ブランチを worktree で開いてレビュー」の 2 つの頻出フローをカバーする。

**Architecture:**

- **エントリポイント**: herdr の popup keybind (`prefix+ctrl+o`) からランチャースクリプトを起動。popup は session-modal でスクリプト終了時に自動で閉じる
- **ランチャー**: `configs/bin/herdr-launch` (fish script)。out-of-store symlink で `~/.local/bin` に配置し、rebuild なしで編集可能にする
- **フロー**: `ghq list | fzf` でリポジトリ選択 → fzf でモード選択 (`open` / `worktree` / `pr-review`)
  - `open`: `herdr workspace create --cwd <repo>` でリポジトリ本体を開く
  - `worktree`: ブランチ名を入力 → `herdr worktree create` (herdr ネイティブ機能。親 workspace とのグルーピング・checkout 先 `~/.herdr/worktrees/<repo>/<branch-slug>` の管理は herdr に任せる)
  - `pr-review`: `gh pr list | fzf` で PR 選択 → detached worktree を作って `gh pr checkout` (fork PR にも対応) → `herdr worktree open --path`
- **共通レイアウト**: 初期タブを `agent` にリネームして `claude` を起動 (pr-review では `claude "/code-review xhigh <デフォルトブランチ>"`)、`editor` タブで `nvim` を起動。pr-review ではさらに `review` タブでデフォルトブランチとの `hunk diff` を開く
- **デフォルトブランチ検出**: `git symbolic-ref --short refs/remotes/origin/HEAD` で検出し、未設定なら `gh repo view --json defaultBranchRef` にフォールバック
- **プロジェクト固有セットアップ**: リポジトリルートに実行可能な `.herdr-setup.fish` があればレイアウト構築後に実行する。`HERDR_LAUNCH_WORKSPACE_ID` / `HERDR_LAUNCH_MODE` を環境変数で渡し、スクリプト内から herdr CLI を直接叩ける (server タブで `mise run dev` を起動する等)。宣言的 TOML 案はパース実装が増える割に表現力が劣るため見送り
- **claude 起動**: 素の `claude` (cage なし)

**Tech Stack:** herdr CLI (workspace / worktree / tab / pane), fish, ghq, fzf, gh, hunk, home-manager (out-of-store symlink)

**実装時の確認事項** (実装前に実機・ソースで確認し、すべて解決済み):

1. `herdr workspace create` は JSON を stdout に返す (`.result.workspace.workspace_id`) — 解決。`worktree create/open` は `--json` フラグが必要
2. 初期タブ / 初期ペインも同じレスポンスに含まれる (`.result.tab.tab_id` / `.result.root_pane.pane_id` / checkout パスは `.result.root_pane.cwd`) — `tab list` / `pane list` での解決は不要
3. `hunk diff <target>` は working tree と target の直接比較 — デフォルトブランチ側の先行コミットを混ぜないよう `git merge-base origin/<default> HEAD` の結果を渡す方式にした
4. popup command は `/bin/sh -c` (非 login) で実行される (herdr ソース `src/platform/macos.rs` で確認) — keybind は `fish -l -c herdr-launch` 経由にして PATH を保証

**実装時の追加判断**: PR の checkout は `gh pr checkout <N> --detach` にした。ローカルブランチを作らないためブランチ名衝突がなく、既存 worktree を使い回す再実行にも強い。

---

### Task 1: ランチャースクリプト `configs/bin/herdr-launch` の作成

**Files:**
- Create: `configs/bin/herdr-launch` (実行可能 fish script)

- [ ] **Step 1: スクリプトの骨格を作成**

以下をベースに作成する (herdr CLI の出力形式は実装時の確認事項 1・2 を反映して調整):

```fish
#!/usr/bin/env fish
# herdr-launch — ghq リポジトリを herdr workspace として定型レイアウトで開く。
# herdr の popup keybind (prefix+ctrl+o) から起動する前提。
#
# モード:
#   open      リポジトリ本体を workspace として開く
#   worktree  新規ブランチの git worktree を作って開く (自分の作業用)
#   pr-review PR ブランチの worktree を作り、hunk レビュー + claude /code-review
#
# リポジトリルートに実行可能な .herdr-setup.fish があれば、レイアウト構築後に
# HERDR_LAUNCH_WORKSPACE_ID / HERDR_LAUNCH_MODE を渡して実行する。

# --- リポジトリ選択 ---
set -l ghq_root (ghq root); or exit 1
set -l repo (ghq list | fzf --prompt='repo> '); or exit 0
set -l repo_path $ghq_root/$repo
set -l repo_name (basename $repo)

# --- モード選択 ---
set -l mode (printf '%s\n' open worktree pr-review | fzf --prompt='mode> '); or exit 0
```

- [ ] **Step 2: モード別の workspace 作成処理を実装**

```fish
switch $mode
    case open
        herdr workspace create --cwd $repo_path --label $repo_name --focus
        # workspace id を解決 (確認事項 1)

    case worktree
        read -l -P 'branch> ' branch; or exit 0
        test -n "$branch"; or exit 0
        herdr worktree create --cwd $repo_path --branch $branch --focus --json
        # → .workspace_id 等を jq で取得

    case pr-review
        cd $repo_path  # gh はカレントディレクトリのリポジトリを対象にする
        # 自分宛てにレビュー依頼された PR (--search 'review-requested:@me') を優先表示し、
        # 0 件なら全 open PR にフォールバック (fzf プロンプトで区別)
        set -l pr_number (gh pr list --limit 50 --search 'review-requested:@me' \
            --json number,title,author \
            --jq '.[] | "\(.number)\t\(.title)\t\(.author.login)"' \
            | fzf --prompt='pr (review-requested)> ' | cut -f1)
        test -n "$pr_number"; or exit 0

        # デフォルトブランチを検出 (/code-review の引数と hunk diff のターゲットに使う)
        set -l default_branch (git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null \
            | string replace 'origin/' '')
        if test -z "$default_branch"
            set default_branch (gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
        end

        # detached worktree に gh pr checkout する (fork PR でも動く)
        set -l wt_path ~/.herdr/worktrees/$repo_name/pr-$pr_number
        git -C $repo_path worktree add --detach $wt_path; or exit 1
        fish -c "cd $wt_path; and gh pr checkout $pr_number"; or exit 1
        herdr worktree open --cwd $repo_path --path $wt_path --label pr-$pr_number --focus --json
end
```

`gh pr list` / `gh pr view` はカレントディレクトリのリポジトリを対象にするため、pr-review モードの冒頭で `cd $repo_path` する (`git -C` 相当のオプションが gh にはない。popup 内スクリプトなので cd してよい)。

- [ ] **Step 3: 共通レイアウト構築を実装**

workspace id (`$ws`) と作業ディレクトリ (`$work_path`: open は repo 本体、worktree/pr-review は worktree のパス) を使って:

```fish
# 初期タブ = agent タブ
set -l first_tab (herdr tab list --workspace $ws --json | jq -r '.[0].id')
set -l first_pane (herdr pane list --workspace $ws --json | jq -r '.[0].id')
herdr tab rename $first_tab agent
if test $mode = pr-review
    herdr pane run $first_pane "claude \"/code-review xhigh $default_branch\""
else
    herdr pane run $first_pane claude
end

# editor タブ
herdr tab create --workspace $ws --cwd $work_path --label editor --no-focus
# → 作成したタブのペインに nvim を起動 (pane id の解決は確認事項 2 と同じ方法)

# pr-review: デフォルトブランチとの diff を hunk で開く review タブ
if test $mode = pr-review
    herdr tab create --workspace $ws --cwd $work_path --label review --no-focus
    # → ペインで hunk diff $default_branch を起動 (構文は確認事項 3)
end

# フォーカスを agent タブへ
herdr tab focus $first_tab
```

- [ ] **Step 4: 規約ファイル実行を実装**

```fish
if test -x $work_path/.herdr-setup.fish
    env HERDR_LAUNCH_WORKSPACE_ID=$ws HERDR_LAUNCH_MODE=$mode \
        fish -c "cd $work_path; and $work_path/.herdr-setup.fish"
end
```

- [ ] **Step 5: 実行権限を付与して git add**

```bash
chmod +x configs/bin/herdr-launch
git add configs/bin/herdr-launch
```

### Task 2: home-manager での配置 (files.nix)

**Files:**
- Modify: `home-manager/files.nix`

- [ ] **Step 1: `~/.local/bin/herdr-launch` への out-of-store symlink を追加**

`home.file` ブロックに追加 (`~/.local/bin` は fish の `fish_add_path` で PATH 済み):

```nix
    # herdr プロジェクトランチャー (configs/bin/herdr-launch)。
    # out-of-store symlink なので rebuild なしで編集できる。
    ".local/bin/herdr-launch" = {
      source = symlink /${rootDir}/bin/herdr-launch;
    };
```

`rootDir` は `configs/` を指すため、リンク先は `configs/bin/herdr-launch` になる。

### Task 3: herdr keybind の追加

**Files:**
- Modify: `configs/.config/herdr/config.toml`

- [ ] **Step 1: popup keybind を追加**

既存の popup 群 (lazygit / hunk / btm / gh dash / scratch shell) の並びに追加:

```toml
# プロジェクトランチャー — ghq+fzf でリポジトリを選び、定型レイアウト
# (claude / editor タブ) の workspace を開く。configs/bin/herdr-launch 参照。
[[keys.command]]
key = "prefix+ctrl+o"
type = "popup"
command = "herdr-launch"
description = "open project launcher (ghq + fzf)"
width = "80%"
height = "60%"
```

確認事項 4 で PATH に `~/.local/bin` が乗っていなければ `command` を絶対パス (`/Users/.../.local/bin/herdr-launch`) にするか `fish -lc herdr-launch` にする。

- [ ] **Step 2: config 再読み込み**

```bash
herdr server reload-config
```

### Task 4: ビルド検証とコード改善

- [ ] **Step 1: nix build 検証**

```bash
cd ~/.dotfiles
git add configs/bin/herdr-launch home-manager/files.nix configs/.config/herdr/config.toml
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
nix build .#darwinConfigurations.SC-N-843.system --no-link
nix fmt
```

Expected: 両ホストともエラーなく完了

- [ ] **Step 2: code-simplifier で改善**

変更は 3 ファイル・100 行未満なので `code-simplifier:code-simplifier` subagent を起動し、`configs/bin/herdr-launch` を中心にレビューさせる。

- [ ] **Step 3: darwin-rebuild switch で適用**

```bash
sudo darwin-rebuild switch --flake .#SC-N-843   # 作業マシンに応じて
```

### Task 5: E2E 検証

herdr セッション内で実施する (launcher は popup 前提のため)。

- [ ] **Step 1: 実装時の確認事項を潰す**

herdr セッション内のシェルで以下を実行し、スクリプトの ID 解決ロジックを実出力に合わせる:

```bash
herdr workspace create --cwd /tmp --label test-launcher --no-focus  # stdout 形式を確認
herdr workspace list --json | head -c 500
herdr tab list --workspace <id> --json
herdr pane list --workspace <id> --json
herdr workspace close <id>  # 後片付け
hunk diff --help  # リビジョン比較構文を確認
```

- [ ] **Step 2: open モードの検証**

`prefix+ctrl+o` → 任意のリポジトリ → `open`。

Expected: workspace が作成され、`agent` タブで claude が起動、`editor` タブで nvim が起動、フォーカスは agent タブ

- [ ] **Step 3: worktree モードの検証**

`prefix+ctrl+o` → dotfiles → `worktree` → ブランチ名 `test-launcher` を入力。

Expected: `~/.herdr/worktrees/` 配下に worktree が作られ、親 workspace とグルーピングされた workspace が開く。レイアウトは Step 2 と同じ。検証後は `herdr worktree remove` で削除し、ブランチも消す

- [ ] **Step 4: pr-review モードの検証**

open PR のある仕事リポジトリで `prefix+ctrl+o` → `pr-review` → PR を選択。

Expected: PR ブランチが detached worktree に checkout され、`agent` タブで `/code-review xhigh <デフォルトブランチ>` が走り始め、`review` タブでデフォルトブランチとの hunk diff が開く

- [ ] **Step 5: `.herdr-setup.fish` の検証**

任意のリポジトリのルートに以下を置いて `open` モードで開く:

```fish
#!/usr/bin/env fish
herdr tab create --workspace $HERDR_LAUNCH_WORKSPACE_ID --cwd $PWD --label server --no-focus
```

Expected: `server` タブが追加で作成される。確認後ファイルは削除

- [ ] **Step 6: コミット**

```bash
git add -A
git commit -m "feat(herdr): ghq+fzf プロジェクトランチャーを追加 (open / worktree / pr-review)"
```
