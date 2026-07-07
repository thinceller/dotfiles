# Hermes への thinceller リポジトリ push 権限付与 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** oberon 上の Hermes Agent が machine account `thinceller-hermes` として、招待された thinceller 個人リポジトリへブランチ push + PR 作成できるようにする。

**Architecture:** machine account を Write collaborator として招待する方式 (許可リスト = 招待リスト)。git push は SSH 鍵 (既存の `GIT_SSH_COMMAND` パターン)、PR 作成は PAT を gh wrapper 経由で使う。実行系 repo は ruleset で default branch を保護。設計の詳細は [`2026-07-06-hermes-github-push-design.md`](2026-07-06-hermes-github-push-design.md) を参照。

**Tech Stack:** GitHub (machine account / rulesets / PAT), sops-nix, NixOS (oberon), gh CLI

**注意:** Task 1〜4 は GitHub 上の手作業 (ユーザーが実施)。Task 5 以降が dotfiles の変更。knowledge-base の deploy key は Task 8 の検証完了まで削除しない。

---

### Task 1: machine account 作成 (手作業)

- [ ] **Step 1: GitHub で machine account を作成**

  - ブラウザのプライベートウィンドウで https://github.com/signup
  - username: `thinceller-hermes`、email: `hermes@thinceller.dev` (Cloudflare Email Routing で受信可)
  - パスワードは 1Password に保存

- [ ] **Step 2: email 検証と 2FA 有効化**

  - 確認メールのリンクを踏んで email を検証 (commit が machine account に紐づくために必要)
  - Settings → Password and authentication → 2FA を有効化 (TOTP、1Password に保存)

### Task 2: SSH 鍵の生成・登録・sops 追加

- [ ] **Step 1: 鍵ペアを生成 (Mac ローカル)**

```bash
ssh-keygen -t ed25519 -C "hermes-agent@oberon" -N "" -f "$TMPDIR/hermes-github-key"
cat "$TMPDIR/hermes-github-key.pub"
```

- [ ] **Step 2: 公開鍵を machine account に登録 (手作業)**

  - `thinceller-hermes` でログインした状態で Settings → SSH and GPG keys → New SSH key
  - Title: `hermes-agent@oberon`、Key: 上記 `.pub` の内容

- [ ] **Step 3: 秘密鍵を sops に追加**

```bash
cd ~/.dotfiles && sops secrets/oberon.yaml
```

エディタで以下を追加。**秘密鍵は複数行なので YAML の block scalar (`|`) を使い、末尾改行を欠落させない** (過去に `hermes-vault-deploy-key` で末尾改行欠落により ssh が鍵を読めないバグがあった。`|-` ではなく `|` を使う):

```yaml
hermes-github-ssh-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  (中身)
  -----END OPENSSH PRIVATE KEY-----
```

- [ ] **Step 4: ローカルの鍵ファイルを削除**

```bash
rm "$TMPDIR/hermes-github-key" "$TMPDIR/hermes-github-key.pub"
```

### Task 3: PAT の発行と sops 追加

- [ ] **Step 1: fine-grained PAT が使えるか確認 (手作業)**

  `thinceller-hermes` の Settings → Developer settings → Fine-grained tokens → Generate new token で、Resource owner に `thinceller` (他ユーザー) の collaborator repo を選択できるか確認する。

  - **選択できる場合**: fine-grained PAT (Repository permissions: Contents = Read and write, Pull requests = Read and write、期限 90 日) を発行し、Step 2 をスキップ
  - **選択できない場合** (2026-07 時点の想定): Step 2 へ

- [ ] **Step 2: classic PAT を発行 (手作業)**

  Settings → Developer settings → Tokens (classic) → Generate new token (classic)。scope: `repo` のみ、期限 90 日。Note: `hermes-agent@oberon`。

  期限切れの 1 週間前に GitHub からメールが来るので、そのタイミングで再発行 → sops 更新 → 再 deploy がローテーション手順になる。

- [ ] **Step 3: PAT を sops に追加**

```bash
cd ~/.dotfiles && sops secrets/oberon.yaml
```

```yaml
hermes-github-pat: ghp_xxxxxxxxxxxx
```

### Task 4: リポジトリ招待と rulesets 設定 (手作業)

- [ ] **Step 1: 対象 repo に Write collaborator として招待**

  各対象 repo (knowledge-base を含む) の Settings → Collaborators → Add people → `thinceller-hermes`、Role: **Write**。

- [ ] **Step 2: machine account で招待を承認**

```bash
GH_TOKEN=<発行したPAT> gh api /user/repository_invitations --jq '.[] | {id, repository: .repository.full_name}'
GH_TOKEN=<発行したPAT> gh api --method PATCH /user/repository_invitations/<id>
```

(またはブラウザで `thinceller-hermes` としてログインして承認)

- [ ] **Step 3: 実行系 repo に ruleset を設定**

  push 内容が機械で実行される repo (dotfiles 等) の Settings → Rules → Rulesets → New branch ruleset:

  - Name: `protect-default-branch`、Enforcement: Active
  - Target branches: Include default branch
  - Rules: **Require a pull request before merging** + **Block force pushes** (デフォルト有効)
  - Bypass list: `Repository admin` を追加 (本人の直 push は維持)

  **注意**: private repo の ruleset 強制は GitHub Free の personal account では使えない (Pro が必要)。対象の実行系 repo が private かつ Free プランの場合は、(a) Pro にする、(b) その repo を招待しない、(c) 直 push リスクを受容して AGENTS.md の運用ルールのみで縛る、のいずれかをユーザーが選ぶ。

- [ ] **Step 4: コンテンツ repo は force push 禁止のみ設定**

  knowledge-base 等は同様に ruleset を作り **Block force pushes** のみ有効化 (Require a pull request は付けない。直 push は現状どおり許可)。

### Task 5: Nix 変更 — secrets と GIT_SSH_COMMAND と gh wrapper

**Files:**
- Modify: `hosts/oberon/hermes-agent.nix`

- [ ] **Step 1: sops secrets 定義を追加**

`hosts/oberon/hermes-agent.nix` の `sops.secrets."hermes-vault-deploy-key"` ブロック (17〜22 行目付近) の直後に追加:

```nix
  # thinceller-hermes (GitHub machine account) の SSH 秘密鍵。招待済み repo への
  # git push に使う。vault deploy key と同じく GIT_SSH_COMMAND 経由で ssh が直接
  # 読むため、エージェントのコンテキストに秘密鍵が乗ることはない。
  sops.secrets."hermes-github-ssh-key" = {
    sopsFile = ../../secrets/oberon.yaml;
    owner = "hermes";
    mode = "0400";
    restartUnits = [ "hermes-agent.service" ];
  };

  # thinceller-hermes の PAT (PR 作成用)。gh wrapper (extraPackages) が実行時に
  # 読むため、systemd の Environment= には載せない。
  sops.secrets."hermes-github-pat" = {
    sopsFile = ../../secrets/oberon.yaml;
    owner = "hermes";
    mode = "0400";
    restartUnits = [ "hermes-agent.service" ];
  };
```

- [ ] **Step 2: GIT_SSH_COMMAND の鍵を差し替え**

`environment` 内 (73〜75 行目付近) を変更:

```nix
      # git push 用 (machine user thinceller-hermes の鍵。招待済み repo すべてに届く)。
      # ホスト鍵検証は programs.ssh.knownHosts (上記) が担う。
      GIT_SSH_COMMAND = "ssh -i ${
        config.sops.secrets."hermes-github-ssh-key".path
      } -o IdentitiesOnly=yes";
```

(`hermes-vault-deploy-key` の secret 定義自体は Task 8 の検証完了まで残す)

- [ ] **Step 3: gh wrapper を extraPackages に追加**

`extraPackages = [ pkgs.openssh ];` を変更:

```nix
    # service path には git はあるが ssh がないため openssh を追加。
    # gh は PAT を実行時に sops path から読む wrapper として提供する
    # (トークンを systemd Environment= に載せない)。
    extraPackages = [
      pkgs.openssh
      (pkgs.writeShellScriptBin "gh" ''
        GH_TOKEN="$(cat ${config.sops.secrets."hermes-github-pat".path})" \
          exec ${pkgs.gh}/bin/gh "$@"
      '')
    ];
```

- [ ] **Step 4: コミット**

```bash
cd ~/.dotfiles
git add hosts/oberon/hermes-agent.nix secrets/oberon.yaml
git commit -m "feat(oberon): hermes に machine user 経由の GitHub push/PR 権限を追加"
```

### Task 6: AGENTS.md に運用ルールを追記

**Files:**
- Modify: `hosts/oberon/hermes-documents/AGENTS.md`

- [ ] **Step 1: GitHub 作業ルールのセクションを追加**

ファイル末尾に追加 (repo リストは実際に招待した repo に合わせて記入する):

```markdown

# GitHub リポジトリでの作業 (vault 以外)

machine account `thinceller-hermes` として、招待済みの repo にのみ push できる。

- 扱ってよい repo: <招待した repo をここに列挙。例: thinceller/dotfiles>
- 作業場所: `/var/lib/hermes/workspace/<repo名>` に clone する
  (なければ `git@github.com:thinceller/<repo名>.git` を clone)
- 変更は必ず `hermes/<短い英数字slug>` ブランチを切って push する。
  default branch (master/main) への直 push はしない
- force push は絶対にしない
- push したら `gh pr create` で PR を作成し、PR の URL を返信する
- 上記リスト外の repo を操作するよう指示されたら、push せずユーザーに確認する
```

- [ ] **Step 2: コミット**

```bash
git add hosts/oberon/hermes-documents/AGENTS.md
git commit -m "feat(oberon): hermes の GitHub 作業ルールを AGENTS.md に追記"
```

### Task 7: ビルド検証と deploy

- [ ] **Step 1: ビルド検証 (Mac 上)**

```bash
cd ~/.dotfiles
nix build .#nixosConfigurations.oberon.config.system.build.toplevel --no-link
```

Expected: エラーなく完了

- [ ] **Step 2: deploy (方式 A、`docs/reference/oberon-deploy.md` 参照)**

```bash
nixos-rebuild switch --flake .#oberon --target-host oberon --build-host oberon --sudo
```

- [ ] **Step 3: secret 配置と service 起動を確認**

```bash
ssh oberon 'sudo ls -l /run/secrets/hermes-github-ssh-key /run/secrets/hermes-github-pat && systemctl is-active hermes-agent'
```

Expected: 両ファイルが `hermes` owner / `0400`、service は `active`

### Task 8: E2E 検証と deploy key 廃止

- [ ] **Step 1: hermes にブランチ push + PR 作成をさせる**

  Slack から hermes に依頼: 「`<対象repo>` を clone して、README に 1 行追記するブランチ `hermes/e2e-test` を push し、PR を作って」

  Expected: PR が `thinceller-hermes` 名義で作成され、URL が返信される。確認後 PR は close してブランチを削除。

- [ ] **Step 2: default branch への直 push が拒否されることを確認**

  Slack から hermes に依頼: 「さっきの変更を master に直接 push してみて」

  Expected: ruleset により `GH013: Repository rule violations` で拒否される

- [ ] **Step 3: vault フロー (Inbox capture) が machine user 鍵で動くことを確認**

  Slack から hermes に依頼: 「これ Inbox に: E2E テストメモ」

  Expected: knowledge-base に commit が push される (author: Hermes Agent)。GitHub 上で `thinceller-hermes` の push として記録される。

- [ ] **Step 4: knowledge-base の deploy key を GitHub から削除 (手作業)**

  knowledge-base の Settings → Deploy keys から旧 deploy key を削除。

- [ ] **Step 5: Nix から deploy key の残骸を削除**

  `hosts/oberon/hermes-agent.nix` から `sops.secrets."hermes-vault-deploy-key"` ブロックを削除し、`sops secrets/oberon.yaml` で `hermes-vault-deploy-key` キーを削除。

```bash
git add hosts/oberon/hermes-agent.nix secrets/oberon.yaml
git commit -m "chore(oberon): knowledge-base deploy key を machine user 鍵に統合し廃止"
```

- [ ] **Step 6: 再ビルド + 再 deploy + vault フロー再確認**

```bash
nix build .#nixosConfigurations.oberon.config.system.build.toplevel --no-link
nixos-rebuild switch --flake .#oberon --target-host oberon --build-host oberon --sudo
```

  deploy 後、Slack から再度 Inbox capture を 1 件実行して push が通ることを確認。

### Task 9: ドキュメント更新

**Files:**
- Modify: `docs/reference/mnemos.md` (deploy key 記述の更新)
- Modify: `hosts/oberon/hermes-documents/AGENTS.md` (「認証は deploy key で設定済み」の文言)

- [ ] **Step 1: deploy key 前提の記述を machine user に更新**

  - `AGENTS.md` 冒頭の「認証は deploy key で設定済み」→「認証は machine user (thinceller-hermes) の SSH 鍵で設定済み」
  - `docs/reference/mnemos.md` の `hermes-agent.nix` 行 (248 行目付近) の「deploy key・instruction」→「machine user 鍵・instruction」。他に deploy key 言及があれば同様に更新

- [ ] **Step 2: コミット**

```bash
git add hosts/oberon/hermes-documents/AGENTS.md docs/reference/mnemos.md
git commit -m "docs(oberon): hermes の GitHub 認証を machine user 前提に更新"
```
