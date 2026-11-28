# Hermes Agent を mac-mini に新規構築する実装計画

作成日: 2026-11-28

oberon で動かしている Hermes Agent とは別に、`kohei-m4-mac-mini` へ Hermes Agent を新規に立てる。
oberon からの状態移行はしない。oberon 側の撤去はこの計画の対象外で、mac-mini で使えると分かった後に別途行う。

## 決定事項

| 項目 | 方針 |
|---|---|
| 本体の導入 | upstream の公式インストーラ (`install.sh`)。Nix パッケージは使わない |
| 追従 | `hermes update` (stable チャンネル) |
| 常駐 | `hermes gateway install` が作る launchd agent。Nix では定義しない |
| 設定 | `config.yaml` を dotfiles に置き、out-of-store symlink で `~/.hermes/` に向ける |
| secret | sops-nix (home-manager) で `~/.hermes/.env` に配置 |
| メインモデル | Anthropic API の Sonnet 5.5 |
| サブエージェント、auxiliary、fallback | OpenCode Go の `kimi-k2.7-code` |
| 窓口 | Webapp を Tailscale Serve の HTTPS で開く。通知は ntfy (送信専用) |
| 引き継ぐ機能 | vault 連携 (skill 2 つと `session-vault-export` プラグイン) だけ |
| 使わないもの | Slack、kanban、worker profile、design-pipeline skill |

Nix パッケージを使わない理由: upstream v0.23.5 は JS 依存の固定ハッシュを `nix/pnpm-deps-hash` の
1 ファイルで全プラットフォーム共通に持つ。aarch64-darwin では別の値
(`sha256-W5V/4xsKZKolR2MQL5GN9GBa7844IPNmKVTTcLaZnvI=`) になり、ビルドできない。
外から差し替える引数も無い。

## 全タスク共通の制約

- 作業ディレクトリは worktree のルート。git root を辿って別の場所を編集しない。
- 対象ホストは `kohei-m4-mac-mini` だけ。`SC-N-843` と `oberon` の構成を変えない。
- `hosts/oberon/` 配下、`flake.nix`、`.github/workflows/update.yml` は変更しない。
- リポジトリは public。secret の平文、API key、ntfy の topic 名、tailnet 名を commit しない。
- age の秘密鍵 (`~/.config/sops/age/keys.txt`) を読まない、表示しない。
- 新規ファイルは `git add` してから `nix build` / `nix eval` を実行する (flake は git 管理下のファイルしか見ない)。
- `darwin-rebuild switch` は実行しない。検証は `nix build` / `nix eval` / `nix fmt` まで。
- コードコメントは既定で書かない。書くのは、コードから読み取れない理由や制約だけ。周囲のファイルに合わせて日本語で書く。
- ホームディレクトリは `/Users/thinceller`、dotfiles の作業ツリーは `/Users/thinceller/.dotfiles`。
- Hermes の作業ディレクトリは `/Users/thinceller/.hermes/workspace`、
  vault の clone 先は `/Users/thinceller/.hermes/workspace/knowledge-base`。
  ユーザー自身が使う vault (`~/src/github.com/thinceller/knowledge-base`) とは別の clone にする。
  Hermes が `git pull --rebase` と commit を行うので、未コミットの手元編集と衝突させないため。
- 検証には PATH にある `sops`、`python3`、`jq`、`grep` を使う。`yq` は入っていない。
- sandbox の制限で `nix build` / `nix eval` が nix daemon に接続できない場合は、回避せずにその旨を報告する。
  その場合、Task 3 の Nix の検証はリードかユーザーが sandbox の外で実行する。

## 確認済みの前提 (upstream v0.23.5 のソース)

- Hermes の設定保存は symlink を保つ。`utils/files.py` の `atomic_replace` が symlink を解決し、実体のファイルを置き換える。
  したがって `/model --global` や設定画面からの変更は dotfiles の作業ツリーに書かれる。
- `config.yaml` は `${VAR}` で環境変数を参照でき、保存時もその書式が保たれる。
- Webapp を Tailscale Serve 越しに開くと (`webapp.public_url` を設定すると) サインインが必須になる。
  パスワード方式の認証情報は `HERMES_DASHBOARD_BASIC_AUTH_*` の環境変数で渡せる。
- auxiliary の `provider: auto` はメインモデルを引き継ぐ。
- `session-vault-export` が使う `SessionDB(read_only=True)`、`get_session`、`get_messages`、
  hook `on_session_finalize` は v0.23.5 にも存在する。引数の互換性は実機で確かめる。

## タスクの依存関係

```
Task 1 (sops ルールと secret の雛形) ─┐
Task 2 (configs/.hermes の中身)      ─┼─> Task 3 (home-manager モジュール) ─> Task 4 (手順書)
```

Task 1 と Task 2 は互いに独立。Task 3 は両方の成果物のパスを参照する。

---

## Task 1: sops のルールと secret の雛形を追加する

### Goal

mac-mini の Hermes 用 secret `secrets/hermes-mac.env` を、oberon からは復号できない形で追加する。
中身はダミー値の雛形にし、実際の値はユーザーが後で `sops` で入れる。

### Files

- 変更: `.sops.yaml`
- 新規: `secrets/hermes-mac.env`

### 内容

1. `.sops.yaml` の `creation_rules` に、次のルールを `secrets/cloudflare-access\.gitconfig$` のルールの直後に足す。
   末尾の包括ルール (`secrets/[^/]+\.(yaml|json|env|ini)$`) より前に置く必要がある。先に一致したルールが使われるため。

   ```yaml
     # mac-mini の Hermes Agent 用 secret。oberon では使わないので recipient に含めない。
     - path_regex: secrets/hermes-mac\.env$
       key_groups:
         - age:
             - *admin
             - *sc
             - *mac
   ```

2. 次の平文を `secrets/hermes-mac.env` に書き、その場で暗号化する。値はすべてダミーで、実際の secret ではない。

   ```dotenv
   ANTHROPIC_API_KEY=replace-me
   OPENCODE_GO_API_KEY=replace-me
   NTFY_TOPIC=replace-me
   NTFY_PUBLISH_TOPIC=replace-me
   NTFY_HOME_CHANNEL=replace-me
   HERMES_DASHBOARD_BASIC_AUTH_USERNAME=replace-me
   HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH=replace-me
   HERMES_DASHBOARD_BASIC_AUTH_SECRET=replace-me
   HERMES_WEBAPP_PUBLIC_URL=replace-me
   ```

   ```bash
   sops --encrypt --in-place secrets/hermes-mac.env
   ```

   暗号化に必要なのは `.sops.yaml` の公開鍵だけで、age の秘密鍵は要らない。

### Interfaces

- 生成物: `secrets/hermes-mac.env` (sops の dotenv 形式)。Task 3 が `sopsFile` として参照する。
- キー名は上の 9 つ。Task 4 の手順書が同じ名前を使う。
- `HERMES_WEBAPP_PUBLIC_URL` は Task 2 の `config.yaml` が `${HERMES_WEBAPP_PUBLIC_URL}` として参照する。

### Verification

```bash
grep -c 'ENC\[' secrets/hermes-mac.env
```

10 が返ること (9 つのキーと `sops_mac` の行)。既存の `secrets/hermes.env` は 6 キーで 7 を返す。

```bash
grep -c 'replace-me' secrets/hermes-mac.env
```

0 が返ること (平文が残っていない)。

```bash
grep -c '__map_recipient=' secrets/hermes-mac.env
```

3 が返ること (recipient が admin、sc、mac の 3 つ)。

```bash
grep -c 'age1sgdgpmndyyzz4zguf97uvppkprsfrklgn3t8cvdegtw8lh9h8fms7druqw' secrets/hermes-mac.env
```

0 が返ること (oberon の公開鍵が入っていない)。

---

## Task 2: Hermes の設定・人格・skill・plugin を configs/.hermes に置く

### Goal

mac-mini の Hermes が読む設定ファイル一式を、dotfiles の `configs/.hermes/` に作る。
このタスクはファイルを置くだけで、`~/.hermes/` への配置は Task 3 が行う。

### Files

- 新規: `configs/.hermes/config.yaml`
- 新規: `configs/.hermes/SOUL.md`
- 新規: `configs/.hermes/workspace/AGENTS.md`
- 新規: `configs/.hermes/external-skills/vault-capture/SKILL.md`
- 新規: `configs/.hermes/external-skills/vault-clip/SKILL.md`
- 新規: `configs/.hermes/plugins/session-vault-export/__init__.py`
- 新規: `configs/.hermes/plugins/session-vault-export/plugin.yaml`
- 変更: `.gitignore`

### 内容

#### `configs/.hermes/config.yaml`

次の内容をそのまま書く。

```yaml
model:
  provider: anthropic
  default: claude-sonnet-5-5

# Anthropic の残高が尽きると API が止まるので OpenCode Go へ逃がす。
fallback_providers:
  - provider: opencode-go
    model: kimi-k2.7-code

delegation:
  provider: opencode-go
  model: kimi-k2.7-code

# provider "auto" はメインモデルを引き継ぐ。Claude のクレジットを対話だけに使うため、
# 裏で走るタスクは明示的に OpenCode Go へ向ける。vision は画像入力が要るので既定のままにする。
auxiliary:
  compression:
    provider: opencode-go
    model: kimi-k2.7-code
  approval:
    provider: opencode-go
    model: kimi-k2.7-code
  mcp:
    provider: opencode-go
    model: kimi-k2.7-code
  title_generation:
    provider: opencode-go
    model: kimi-k2.7-code
  memory_query_rewrite:
    provider: opencode-go
    model: kimi-k2.7-code
  goal_judge:
    provider: opencode-go
    model: kimi-k2.7-code
  curator:
    provider: opencode-go
    model: kimi-k2.7-code
  background_review:
    provider: opencode-go
    model: kimi-k2.7-code
  review:
    provider: opencode-go
    model: kimi-k2.7-code

terminal:
  cwd: /Users/thinceller/.hermes/workspace

approvals:
  mode: smart

memory:
  memory_enabled: true
  user_profile_enabled: true

privacy:
  redact_pii: true

plugins:
  enabled:
    - session-vault-export

skills:
  external_dirs:
    - /Users/thinceller/.dotfiles/configs/.hermes/external-skills

# public_url は Tailscale Serve の HTTPS URL。tailnet 名を public リポジトリに載せないため、
# 値は sops 側の .env に置く。
webapp:
  enabled: true
  host: 127.0.0.1
  port: 9120
  public_url: ${HERMES_WEBAPP_PUBLIC_URL}
```

#### `configs/.hermes/SOUL.md`

次の内容をそのまま書く。

```markdown
# Hermes Agent

あなたは mac-mini 上で動く、thinceller の秘書的アシスタントです。
日本語で、簡潔かつ明確に会話してください。

## 役割

Webapp から届く依頼を引き受けます。knowledge-base vault への記録と検索、質問への回答、
調査までを担当します。具体的な手順は AGENTS.md と skill が定めます。

進め方に迷ったら、自分で決めずにユーザーに聞いてください。

## 外部サービスと取り消しにくい操作

このマシンはユーザー本人のアカウントで動いており、ホームディレクトリ全体に手が届きます。
ユーザーの明示的な承認なしに、外部サービスの状態を変更したり、取り消しにくい操作を
行ったりしないでください。特に以下は禁止です。

- GitHub へのマージ、リリース作成
- 本番環境への反映
- force push、default branch への直接 push (vault の定められた手順を除く)
- 認証情報やトークンをリポジトリに保存すること
- `~/.hermes/workspace` の外にあるファイルの変更や削除

## 言語とトーン

- 日本語で応答する
- 技術的な正確性を優先する
- 確認できる事実と推測を区別し、推測は「推測」と明示する
- 曖昧な要求では、決めるべき論点を整理し、推奨案を添えて一度に1つずつ質問する
```

#### `configs/.hermes/workspace/AGENTS.md`

冒頭は次のとおり書く。

```markdown
# Hermes Agent on mac-mini

Hermes Agent は mac-mini 上で、公式インストーラで導入した本体を launchd で常駐させています。
この AGENTS.md は作業ディレクトリである `/Users/thinceller/.hermes/workspace/` に配置され、
Hermes の system prompt に自動で注入されます。

## ワークスペース

- 作業ディレクトリ: `/Users/thinceller/.hermes/workspace`
- この配下にあるリポジトリ:
  - `knowledge-base/`

## 注意

- `~/.hermes/config.yaml`、`SOUL.md`、この `AGENTS.md`、vault 系 skill、plugin は
  dotfiles リポジトリ (`/Users/thinceller/.dotfiles/configs/.hermes/`) への symlink です。
- `.env` などの秘密情報は sops-nix によって管理されます。
```

その後ろに、`hosts/oberon/hermes-documents/AGENTS.md` の
`# knowledge-base vault (個人ナレッジベース) への記録と参照` の見出しから
`## 制約` の節の末尾 (`Notes/` には書かない、の行) までを写す。写すときに次の 3 点だけ変える。

- `/var/lib/hermes/workspace/knowledge-base` をすべて `/Users/thinceller/.hermes/workspace/knowledge-base` にする。
- `認証は machine user (thinceller-hermes) の SSH 鍵で設定済み。そのまま` の文を
  `認証と commit の名義は clone 済みリポジトリの git config に設定済み。そのまま` にする。
- `## 制約` の 1 項目目の括弧書き
  `(外部スキルディレクトリは読み取り専用で、書き込みはエラーになる)` を
  `(dotfiles で管理しているため、ここから書き換えない)` にする。

oberon 版にある「プロファイル」「プロジェクト別の規約」「開発依頼の設計」「GitHub リポジトリでの作業」の節は写さない。

#### skill 2 つ

`hosts/oberon/hermes-skills/vault-capture/SKILL.md` を `configs/.hermes/external-skills/vault-capture/SKILL.md` へ、
`hosts/oberon/hermes-skills/vault-clip/SKILL.md` を `configs/.hermes/external-skills/vault-clip/SKILL.md` へ写す。
それぞれ次の 2 点だけ変える。

- frontmatter の `platforms: [linux]` を `platforms: [macos]` にする。
- `/var/lib/hermes/workspace/knowledge-base` をすべて `/Users/thinceller/.hermes/workspace/knowledge-base` にする。

`design-pipeline` と `to-kanban` は写さない。

#### plugin

`hosts/oberon/hermes-plugins/session-vault-export/` の `__init__.py` と `plugin.yaml` を
`configs/.hermes/plugins/session-vault-export/` へ写す。`__init__.py` は次の 1 行だけ変える。

```python
# 変更前
_VAULT_REPO = Path("/var/lib/hermes/workspace/knowledge-base")
# 変更後
_VAULT_REPO = Path.home() / ".hermes" / "workspace" / "knowledge-base"
```

写した後に `grep -n -E '/var/lib|oberon' configs/.hermes/plugins/session-vault-export/__init__.py` を実行する。
一致が残っていたら、その行を報告する (勝手に書き換えない)。

#### `.gitignore`

Hermes が plugin を読み込むと `__pycache__` が作業ツリーにできるので、末尾に次を足す。

```gitignore

configs/.hermes/plugins/**/__pycache__
```

### Interfaces

Task 3 が symlink の元として参照するパス:

- `configs/.hermes/config.yaml`
- `configs/.hermes/SOUL.md`
- `configs/.hermes/workspace/AGENTS.md`
- `configs/.hermes/plugins/session-vault-export` (ディレクトリ)

`configs/.hermes/external-skills` は symlink せず、`config.yaml` の `skills.external_dirs` が直接指す。

### Verification

```bash
grep -c -E '^  default: claude-sonnet-5-5$|^  port: 9120$|^  public_url: \$\{HERMES_WEBAPP_PUBLIC_URL\}$' configs/.hermes/config.yaml
```

3 が返ること。

```bash
grep -c 'provider: opencode-go' configs/.hermes/config.yaml
```

11 が返ること (fallback 1、delegation 1、auxiliary 9)。

```bash
grep -rn -E '/var/lib/hermes|platforms: \[linux\]' configs/.hermes
```

何も返らないこと。

```bash
python3 -m py_compile configs/.hermes/plugins/session-vault-export/__init__.py && rm -rf configs/.hermes/plugins/session-vault-export/__pycache__
```

エラーなく終わること。

---

## Task 3: home-manager モジュールで ~/.hermes に配置する

### Goal

mac-mini でだけ、Task 2 のファイルを `~/.hermes/` に out-of-store symlink で配置し、
Task 1 の secret と GitHub 用の SSH 鍵を sops-nix で復号して配置する。

### Files

- 新規: `home-manager/programs/hermes/default.nix`
- 変更: `home-manager/programs/default.nix`

### 内容

`home-manager/programs/hermes/default.nix` を次の内容で作る。

```nix
{
  config,
  lib,
  userConfig,
  ...
}:
let
  rootDir = userConfig.dotfilesDir + "/configs/.hermes";
  symlink = config.lib.file.mkOutOfStoreSymlink;
  hermesHome = "${config.home.homeDirectory}/.hermes";
in
lib.mkIf (userConfig.hostname == "kohei-m4-mac-mini") {
  # 本体は公式インストーラで導入する (upstream の Nix パッケージは pnpm 依存の
  # 固定ハッシュが aarch64-darwin で一致せずビルドできない)。
  # ここでは設定の symlink と secret の配置だけを持つ。
  # 手順は docs/reference/hermes-mac-mini.md を参照。
  home.file = {
    ".hermes/config.yaml".source = symlink "${rootDir}/config.yaml";
    ".hermes/SOUL.md".source = symlink "${rootDir}/SOUL.md";
    ".hermes/workspace/AGENTS.md".source = symlink "${rootDir}/workspace/AGENTS.md";
    ".hermes/plugins/session-vault-export".source = symlink "${rootDir}/plugins/session-vault-export";
  };

  sops.secrets."hermes-env" = {
    sopsFile = ../../../secrets/hermes-mac.env;
    format = "dotenv";
    path = "${hermesHome}/.env";
  };

  # thinceller-hermes (GitHub machine account) の SSH 秘密鍵。vault の clone に設定した
  # core.sshCommand が読む。個人の Secure Enclave 鍵は無人の push に使えないため分ける。
  sops.secrets."hermes-github-ssh-key" = {
    sopsFile = ../../../secrets/oberon.yaml;
    path = "${hermesHome}/github-ssh-key";
    mode = "0400";
  };
}
```

`home-manager/programs/default.nix` の `imports` に `./hermes` を足す。
位置はアルファベット順で、`./git` の後、`./htop` の前。

`sops.secrets."hermes-github-ssh-key"` が参照する `secrets/oberon.yaml` には、
同名のキー `hermes-github-ssh-key` がすでにあり、recipient に mac の鍵が含まれている。新しい secret は足さない。

### Interfaces

- 参照するもの: Task 1 の `secrets/hermes-mac.env`、Task 2 の `configs/.hermes/` 配下の 4 パス。
- 配置されるもの (Task 4 の手順書が前提にするパス):
  - `~/.hermes/config.yaml`、`~/.hermes/SOUL.md`、`~/.hermes/workspace/AGENTS.md`、
    `~/.hermes/plugins/session-vault-export` (symlink)
  - `~/.hermes/.env` (復号した dotenv への symlink)
  - `~/.hermes/github-ssh-key` (復号した SSH 秘密鍵への symlink、mode 0400)

### Verification

```bash
git add home-manager/programs/hermes configs/.hermes secrets/hermes-mac.env .sops.yaml .gitignore
nix fmt
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link
```

エラーなく終わること。nix daemon に接続できない場合は、`git add` と `nix fmt` 以外の検証を実行せず、
未実行である旨を報告する (リードかユーザーが sandbox の外で実行する)。

```bash
nix eval --json .#darwinConfigurations.kohei-m4-mac-mini.config.home-manager.users.thinceller.home.file --apply 'f: builtins.filter (n: builtins.match "\\.hermes/.*" n != null) (builtins.attrNames f)'
```

`.hermes/` で始まる 4 つの名前が返ること。

```bash
nix eval --json .#darwinConfigurations.SC-N-843.config.home-manager.users --apply 'us: builtins.all (u: builtins.all (n: builtins.match "\\.hermes/.*" n == null) (builtins.attrNames u.home.file)) (builtins.attrValues us)'
```

`true` が返ること (仕事用 Mac には配置されない)。

```bash
nix eval --raw .#nixosConfigurations.oberon.config.system.build.toplevel.drvPath
```

エラーなく drv パスが返ること (oberon の構成が壊れていない)。

---

## Task 4: 実機セットアップの手順書を書く

### Goal

Nix で管理しない部分 (本体の導入、secret の実値、vault の clone、launchd、Tailscale Serve) の手順と、
動作確認の項目を `docs/reference/hermes-mac-mini.md` に残す。

### Files

- 新規: `docs/reference/hermes-mac-mini.md`
- 変更: `CLAUDE.md`

### 内容

`CLAUDE.md` の「Common Development Commands」節にある
`kohei-m4-mac-mini と oberon は master push 時に comin が…` の段落の後ろに、次の 1 段落を足す。

```markdown
mac-mini の Hermes Agent は公式インストーラで導入しており、Nix が持つのは設定の symlink と
secret だけ (`home-manager/programs/hermes/`)。実機の手順は `docs/reference/hermes-mac-mini.md` を参照。
```

`docs/reference/hermes-mac-mini.md` は、次の見出しと内容で書く。文体は既存の `docs/reference/hermes-kanban.md` に合わせる。

1. **概要**: この計画の「決定事項」の表と、Nix パッケージを使わない理由を写す。
   どのファイルが dotfiles のどこにあり、`~/.hermes/` のどこへ symlink されるかの表を付ける
   (Task 3 の Interfaces にある 6 つ)。
   symlink の先は `/Users/thinceller/.dotfiles` の作業ツリーなので、設定の変更は comin の deploy ではなく
   その作業ツリーの更新で反映される、と明記する。

2. **事前に用意するもの**:
   - Claude Console の API key。claude.ai の Settings > Billing で Console の organization をリンクし、
     Max プランの月 $100 のクレジットを受け取る (加入後 7 日経過が条件、月末で失効)。
   - OpenCode Go の API key (oberon で使っているものと同じでよい)。
   - ntfy の topic 名。ntfy.sh の topic は名前を知っていれば誰でも読めるので、推測されにくい名前にする。
   - Tailscale の管理画面で HTTPS 証明書を有効にしておく。

3. **本体の導入**: 先に `~/.dotfiles` の作業ツリーを最新の master にする。
   symlink と `skills.external_dirs` は comin の clone ではなく、この作業ツリーを指すため。

   ```bash
   git -C ~/.dotfiles pull
   ```

   ```bash
   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
   ```

   本体は `~/.hermes/hermes-agent/`、ラッパーは `~/.local/bin/hermes` に入る。
   導入後に `ls -l ~/.hermes/config.yaml` を実行し、symlink のままであることを確認する。
   通常ファイルに置き換わっていたら、削除して home-manager の activation をやり直す。

4. **secret の実値を入れる**:

   ```bash
   hermes dashboard password --username thinceller
   ```

   このコマンドは `dashboard.basic_auth` の `username`、`password_hash`、`secret` を `config.yaml` に書く。
   `config.yaml` は public リポジトリのファイルなので、この 3 つの値を次の手順で sops 側へ移す。

   ```bash
   cd ~/.dotfiles
   sops secrets/hermes-mac.env
   ```

   `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`、`HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH`、
   `HERMES_DASHBOARD_BASIC_AUTH_SECRET` に上の 3 つを入れ、
   `ANTHROPIC_API_KEY`、`OPENCODE_GO_API_KEY` に API key を入れる。
   `NTFY_TOPIC`、`NTFY_PUBLISH_TOPIC`、`NTFY_HOME_CHANNEL` には同じ topic 名を入れる
   (`NTFY_ALLOWED_USERS` を設定しないので、通知の送信専用になる)。
   `HERMES_WEBAPP_PUBLIC_URL` には手順 7 で分かる URL を入れる。まだ分からなければ後で入れる。

   その後、`config.yaml` から `dashboard.basic_auth` のブロックだけを手で削除する。
   `git -C ~/.dotfiles diff configs/.hermes/config.yaml` で、パスワードのハッシュと署名鍵が残っていないことを確かめる。
   Hermes が足した他の差分 (`_config_version` など) は残してよい。
   secret の変更は commit して master に入れ、comin の deploy を待つ。

   `~/.hermes/.env` は復号済みファイルへの symlink なので、Hermes や手作業で書き換えた内容は
   次の activation で元に戻る。値を変えるときは必ず `sops` で編集する、と注記する。

5. **vault の clone**:

   ```bash
   git clone -c core.sshCommand="ssh -i /Users/thinceller/.hermes/github-ssh-key -o IdentitiesOnly=yes -o IdentityAgent=none" \
     git@github.com:thinceller/knowledge-base.git ~/.hermes/workspace/knowledge-base
   cd ~/.hermes/workspace/knowledge-base
   git config core.sshCommand "ssh -i /Users/thinceller/.hermes/github-ssh-key -o IdentitiesOnly=yes -o IdentityAgent=none"
   git config user.name "Hermes Agent"
   git config user.email "hermes@thinceller.dev"
   git config commit.gpgsign false
   ```

   ユーザー自身の vault (`~/src/github.com/thinceller/knowledge-base`) とは別の clone にする理由と、
   個人の Secure Enclave 鍵ではなく machine user の鍵を使う理由を 1 文ずつ書く。

6. **常駐**:

   ```bash
   hermes gateway install
   hermes gateway status
   tail -f ~/.hermes/logs/gateway.log
   ```

   plist は `~/Library/LaunchAgents/ai.hermes.gateway.plist` にでき、導入時点の PATH を取り込む。
   PATH に入るツールを増やしたら `hermes gateway install` をやり直す、と書く。
   ユーザーの LaunchAgent は GUI ログイン中しか動かない、とも書く。

7. **Tailscale Serve**:

   ```bash
   /Applications/Tailscale.app/Contents/MacOS/Tailscale serve --bg 9120
   /Applications/Tailscale.app/Contents/MacOS/Tailscale serve status
   ```

   表示された `https://<machine>.<tailnet>.ts.net` を `sops secrets/hermes-mac.env` で
   `HERMES_WEBAPP_PUBLIC_URL` に入れる。commit して master に入れ、deploy 後に
   `hermes gateway stop && hermes gateway start` で再起動する。
   `config.yaml` は `${HERMES_WEBAPP_PUBLIC_URL}` を参照するだけなので、tailnet 名はリポジトリに平文で載らない。
   この変数が `replace-me` のままだと URL として不正なので、Webapp は起動しない、とも書く。

8. **動作確認**: 次の項目を表にする (項目、確認方法、期待する結果)。

   | 項目 | 確認方法 | 期待する結果 |
   |---|---|---|
   | Webapp | iPhone の Safari で `public_url` を開く | サインイン画面が出て、設定したユーザー名とパスワードで入れる |
   | メインモデル | Webapp で 1 通送る | 応答が返り、モデル表示が Sonnet 5.5 |
   | サブエージェント | 調査を委任させる依頼を送り、`~/.hermes/logs/gateway.log` を見る | 子エージェントが `opencode-go` で動く |
   | fallback | 復号済みの `.env` の実体で `ANTHROPIC_API_KEY` を一時的に無効な値に書き換え、1 通送る | OpenCode Go のモデルで応答が返る。確認後は activation をやり直して元に戻す |
   | 通知 | `hermes send --to ntfy "test"` | iPhone の ntfy アプリに届く |
   | vault への記録 | 「これ Inbox に: テスト」と送る | vault に commit が push され、名義が Hermes Agent |
   | セッションの書き出し | Webapp で `/new` を実行 | vault の `Agents/Hermes-Agent/sessions/` に Markdown が増える |
   | 設定の即時変更 | `/model --global` で別のモデルに切り替え、`ls -l ~/.hermes/config.yaml` と `git -C ~/.dotfiles diff` を見る | symlink のままで、dotfiles に diff が出る |
   | 追従 | `hermes update --check` | 更新の有無が表示される |

   モデル ID `claude-sonnet-5-5` が Hermes 側で通らなかった場合は `hermes model` で選び直し、
   `config.yaml` の diff を commit する、と注記する。

9. **既知の注意点**:
   - Hermes が `config.yaml` を書き直すと、キーの並びや `_config_version` の差分が出る。内容を確かめて commit する。
   - `hermes update` での更新は dotfiles の履歴にも CI にも残らない。
   - upstream が `nix/pnpm-deps-hash` をプラットフォーム別に持つようになれば、Nix パッケージに戻せる。
   - oberon の Hermes (`hosts/oberon/hermes-agent.nix`) は別途撤去する。

### Interfaces

- 参照するもの: Task 1 のキー名 9 つ、Task 3 が配置する 6 つのパス。

### Verification

```bash
grep -c -E '^## ' docs/reference/hermes-mac-mini.md
```

9 が返ること。

```bash
grep -n -E 'ts\.net|ntfy\.sh/[a-z0-9]|sk-ant-' docs/reference/hermes-mac-mini.md
```

`<machine>.<tailnet>.ts.net` の例示以外に一致が無いこと (実際の tailnet 名、topic、API key が書かれていない)。

```bash
nix fmt
```

差分が出ないこと。

---

## 実装後に人が行うこと

1. 変更をレビューする (実装者とは別のコンテキストで。`dev-practice:reviewer` に diff を渡す)。
2. PR を作り、CI の通過を確認して master にマージする。comin が mac-mini に deploy する。
3. mac-mini で `~/.dotfiles` を最新の master にし、`docs/reference/hermes-mac-mini.md` の手順 2 から 8 を実行する。
4. 動作確認の表の全項目が通ったら、oberon の Hermes を撤去する計画を別途立てる。

## この計画に含めないもの

- oberon の `hermes-agent.nix`、Cloudflare Tunnel の経路、関連 secret、`flake.nix` の `hermes-agent` input の撤去
- `.github/workflows/update.yml` の変更 (追従は `hermes update` で行うので不要)
- 自作の窓口アプリ、ページ公開の基盤
- `hermes update` の定期実行

## 実装時に計画から変えた点

レビューの指摘を受けて、次の点を計画から変えた。手順の正は `docs/reference/hermes-mac-mini.md`。

- インストーラは `--skip-setup` を付けて実行する。付けないとセットアップウィザードと `hermes gateway install` が続けて走り、
  symlink 越しに `config.yaml` が書き換わり、secret を入れる前に gateway が常駐を始める。
- mac-mini に残っていた古い `~/.hermes/` を、マージの前に退避する手順を足した。
- 「activation をやり直す」を、手動の `sudo darwin-rebuild switch --flake ~/.dotfiles#kohei-m4-mac-mini` に具体化した。
- skill 2 つに残っていた「Slack で返信する」を「返信する」に直した。
- `hermes-github-ssh-key` は oberon と共有しているので、oberon の Hermes を撤去するときに消さない旨を注記した。
