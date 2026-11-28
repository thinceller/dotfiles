# mac-mini の Hermes Agent

`kohei-m4-mac-mini` で動かす Hermes Agent のセットアップ手順。
Nix で管理しない部分 (設定リポジトリ、本体の導入、secret の実値、vault の clone、launchd、Tailscale Serve) と、
動作確認の項目をまとめる。

## 概要

| 項目 | 方針 |
|---|---|
| 本体の導入 | upstream の公式インストーラ (`install.sh`)。Nix パッケージは使わない |
| 追従 | `hermes update` (stable チャンネル) |
| 常駐 | `hermes gateway install` が作る launchd agent。Nix では定義しない |
| 設定 | `config.yaml` などは private リポジトリ `thinceller/dot-hermes` に置き、`~/.hermes/workspace/dot-hermes` の clone へ out-of-store symlink で向ける |
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

設定を dotfiles に置かない理由: 設定や skill は Hermes 自身が日常的に書き換える。
public で master が自動 deploy される dotfiles に置くと、意図しない diff と公開が問題になる。

Nix が持つのは設定の symlink と secret の配置だけで、定義は `home-manager/programs/hermes/default.nix` にある。
配置されるファイルは次の 6 つ。

| 配置先 | 元 | 種類 |
|---|---|---|
| `~/.hermes/config.yaml` | `~/.hermes/workspace/dot-hermes/config.yaml` | out-of-store symlink |
| `~/.hermes/SOUL.md` | `~/.hermes/workspace/dot-hermes/SOUL.md` | out-of-store symlink |
| `~/.hermes/workspace/AGENTS.md` | `~/.hermes/workspace/dot-hermes/workspace/AGENTS.md` | out-of-store symlink |
| `~/.hermes/plugins/session-vault-export` | `~/.hermes/workspace/dot-hermes/plugins/session-vault-export` (ディレクトリ) | out-of-store symlink |
| `~/.hermes/.env` | `secrets/hermes-mac.env` | sops-nix が復号した dotenv への symlink |
| `~/.hermes/github-ssh-key` | `secrets/oberon.yaml` の `hermes-github-ssh-key` | sops-nix が復号した SSH 秘密鍵への symlink (mode 0400) |

skill (`~/.hermes/workspace/dot-hermes/skills`) は symlink せず、`config.yaml` の `skills.create_dir` が直接指す。
Hermes が新しく作る skill もここに入る。

symlink の先は dot-hermes の clone である。
そのため設定の変更は dotfiles の deploy とは無関係に、その場で効く。

## 事前に用意するもの

この手順は、この設定を追加した変更が master にマージされ、comin が mac-mini に deploy 済みであることを前提にする。

mac-mini には、以前試したときの `~/.hermes/` が残っている場合がある (通常ファイルの `config.yaml`、`SOUL.md`、`auth.json` など)。
古い `auth.json` の認証情報が使われるのを避けるため、古い `~/.hermes/` は退避する。
退避は dot-hermes の clone を作る前に行う。
順序は「退避、clone の作成 (「設定リポジトリ」の節)、deploy」である。
この mac-mini では退避も clone の作成も済んでいるので、やり直さない。

```bash
mv ~/.hermes ~/.hermes.old
```

退避先に同名のディレクトリが既にあると、その中へ入れ子で移動してしまう。
退避先は存在しない名前にする。

clone が `~/.hermes/workspace/dot-hermes` にある状態で `mv ~/.hermes ...` を実行すると、clone ごと移動する。
その場合は clone を `~/.hermes/workspace/dot-hermes` に戻してから、手動で switch して symlink と secret を配置し直す (`docs/reference/mac-mini-deploy.md` の手動 fallback と同じ)。

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles#kohei-m4-mac-mini
```

deploy 済みかどうかは次で確かめる。2 つとも symlink として表示されればよい。

```bash
ls -l ~/.hermes/config.yaml ~/.hermes/.env
```

- Claude Console の API key。claude.ai の Settings > Billing で Console の organization をリンクし、
  Max プランの月 $100 のクレジットを受け取る (加入後 7 日経過が条件、月末で失効)。
- OpenCode Go の API key (oberon で使っているものと同じでよい)。
- ntfy の topic 名。ntfy.sh の topic は名前を知っていれば誰でも読めるので、推測されにくい名前にする。
- Tailscale の管理画面で HTTPS 証明書を有効にしておく。

## 設定リポジトリ

この mac-mini では、`~/.hermes/workspace/dot-hermes` にローカルのリポジトリを作成済みである。
git config (名義、署名なし、`core.sshCommand`) と remote も設定済みである。

初回の push には、次の 2 つが前提になる。

- GitHub に private リポジトリ `thinceller/dot-hermes` があり、machine user (thinceller-hermes) が write 権限の招待を承諾している。
- deploy で `~/.hermes/github-ssh-key` が配置されている。`core.sshCommand` がその鍵を読むため。

前提がそろったら、次のコマンドで push する。

```bash
git -C ~/.hermes/workspace/dot-hermes push -u origin main
```

別のマシンで復元する場合や、clone を作り直す場合は、次のように clone して git config を設定する。

```bash
git clone -c core.sshCommand="ssh -i /Users/thinceller/.hermes/github-ssh-key -o IdentitiesOnly=yes -o IdentityAgent=none" \
  git@github.com:thinceller/dot-hermes.git ~/.hermes/workspace/dot-hermes
cd ~/.hermes/workspace/dot-hermes
git config core.sshCommand "ssh -i /Users/thinceller/.hermes/github-ssh-key -o IdentitiesOnly=yes -o IdentityAgent=none"
git config user.name "Hermes Agent"
git config user.email "hermes@thinceller.dev"
git config commit.gpgsign false
```

clone が無い間は、`~/.hermes/config.yaml` などの symlink が宙に浮く。

Hermes は設定や skill を変えるたびに、このリポジトリへ commit と push を行う。
手順は `workspace/AGENTS.md` にある。
ただし、スラッシュコマンド (`/model --global` など) や設定画面からの変更は `config.yaml` を直接書き換えるので、自動では commit されない。
差分が残っていたら、Hermes に依頼するか自分で commit する。
この変更は dotfiles の CI を通らない。
壊れた `config.yaml` が commit されても、気付くのは Hermes の起動時になる。

## 本体の導入

公式インストーラを実行する。

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup
```

`--skip-setup` を付けないと、インストーラがセットアップウィザードと `hermes gateway install` を続けて実行する。
ウィザードは symlink 越しに dot-hermes の `config.yaml` を書き換え、secret を入れる前に gateway が常駐を始めてしまう。

本体は `~/.hermes/hermes-agent/`、ラッパーは `~/.local/bin/hermes` に入る。

導入後に `ls -l ~/.hermes/config.yaml` を実行し、symlink のままであることを確認する。
あわせて `git -C ~/.hermes/workspace/dot-hermes diff config.yaml` を実行し、意図しない差分が出ていないことを確認する。
通常ファイルに置き換わっていたら、削除して switch し直す。

```bash
sudo darwin-rebuild switch --flake ~/.dotfiles#kohei-m4-mac-mini
```

## secret の実値を入れる

Webapp のサインインに使うユーザー名とパスワードを設定する。
このコマンドは gateway を常駐させる前に実行する。
パスワードのハッシュと署名鍵を dot-hermes の `config.yaml` に書くため、gateway が動いていると、Hermes がその差分を commit して push するおそれがある。

```bash
hermes dashboard password --username thinceller
```

パスワードを後で変えるときは、先に `hermes gateway stop` で gateway を止めてから実行する。

このコマンドは `dashboard.basic_auth` の `username`、`password_hash`、`secret` を `config.yaml` に書く。
秘密の値はリポジトリに置かず sops で管理する方針なので、この 3 つの値を次の手順で sops 側へ移す。

```bash
cd ~/.dotfiles
sops secrets/hermes-mac.env
```

各キーに次の値を入れる。

| キー | 値 |
|---|---|
| `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` | `dashboard.basic_auth` の `username` |
| `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH` | `dashboard.basic_auth` の `password_hash` |
| `HERMES_DASHBOARD_BASIC_AUTH_SECRET` | `dashboard.basic_auth` の `secret` |
| `ANTHROPIC_API_KEY` | Claude Console の API key |
| `OPENCODE_GO_API_KEY` | OpenCode Go の API key |
| `NTFY_TOPIC` | ntfy の topic 名 |
| `NTFY_PUBLISH_TOPIC` | ntfy の topic 名 (`NTFY_TOPIC` と同じ) |
| `NTFY_HOME_CHANNEL` | ntfy の topic 名 (`NTFY_TOPIC` と同じ) |
| `HERMES_WEBAPP_PUBLIC_URL` | 「Tailscale Serve」の手順で分かる URL。まだ分からなければ後で入れる |

ntfy の 3 つのキーには同じ topic 名を入れる。
`NTFY_ALLOWED_USERS` を設定しないので、ntfy は通知の送信専用になる。

その後、`config.yaml` から `dashboard.basic_auth` のブロックだけを手で削除する。
次のコマンドで、パスワードのハッシュと署名鍵が残っていないことを確かめる。

```bash
git -C ~/.hermes/workspace/dot-hermes diff config.yaml
```

ブロックを削除した後に dot-hermes 側へ残った差分 (Hermes が足した `_config_version` など) は、内容を確かめてから dot-hermes に commit して push する。
dotfiles の secret (`secrets/hermes-mac.env`) の変更は、dotfiles で commit して master に入れ、comin の deploy を待つ。

`~/.hermes/.env` は復号済みファイルへの symlink である。
Hermes や手作業で書き換えた内容は、次の activation で元に戻る。
値を変えるときは必ず `sops secrets/hermes-mac.env` で編集する。

## vault の clone

Hermes 専用の vault を clone し、認証と commit の名義をリポジトリの git config に設定する。

```bash
git clone -c core.sshCommand="ssh -i /Users/thinceller/.hermes/github-ssh-key -o IdentitiesOnly=yes -o IdentityAgent=none" \
  git@github.com:thinceller/knowledge-base.git ~/.hermes/workspace/knowledge-base
cd ~/.hermes/workspace/knowledge-base
git config core.sshCommand "ssh -i /Users/thinceller/.hermes/github-ssh-key -o IdentitiesOnly=yes -o IdentityAgent=none"
git config user.name "Hermes Agent"
git config user.email "hermes@thinceller.dev"
git config commit.gpgsign false
```

ユーザー自身の vault (`~/src/github.com/thinceller/knowledge-base`) とは別の clone にする。
Hermes が `git pull --rebase` と commit を行うので、未コミットの手元編集と衝突させないため。

鍵は個人の Secure Enclave 鍵ではなく、machine user (thinceller-hermes) の鍵を使う。
個人の Secure Enclave 鍵は無人の push に使えないため。

## 常駐

launchd agent を登録し、状態とログを確認する。

```bash
hermes gateway install
hermes gateway status
tail -f ~/.hermes/logs/gateway.log
```

plist は `~/Library/LaunchAgents/ai.hermes.gateway.plist` にでき、導入時点の PATH を取り込む。
PATH に入るツールを増やしたら、`hermes gateway install` をやり直す。

ユーザーの LaunchAgent は GUI ログイン中しか動かない。

## Tailscale Serve

Webapp のポート 9120 を Tailscale Serve の HTTPS で公開する。

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --bg 9120
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve status
```

表示された `https://<machine>.<tailnet>.ts.net` を、`sops secrets/hermes-mac.env` で
`HERMES_WEBAPP_PUBLIC_URL` に入れる。
commit して master に入れ、deploy 後に Hermes を再起動する。

```bash
hermes gateway stop && hermes gateway start
```

`config.yaml` は `${HERMES_WEBAPP_PUBLIC_URL}` を参照するだけなので、tailnet 名はリポジトリに平文で載らない。

この変数が `replace-me` のままだと URL として不正なので、Webapp は起動しない。

## 動作確認

| 項目 | 確認方法 | 期待する結果 |
|---|---|---|
| Webapp | iPhone の Safari で `public_url` を開く | サインイン画面が出て、設定したユーザー名とパスワードで入れる |
| メインモデル | Webapp で 1 通送る | 応答が返り、モデル表示が Sonnet 5.5 |
| サブエージェント | 調査を委任させる依頼を送り、`~/.hermes/logs/gateway.log` を見る | 子エージェントが `opencode-go` で動く |
| fallback | `realpath ~/.hermes/.env` で分かる復号済みファイルで `ANTHROPIC_API_KEY` を一時的に無効な値に書き換え、1 通送る | OpenCode Go のモデルで応答が返る。確認後は `sudo darwin-rebuild switch --flake ~/.dotfiles#kohei-m4-mac-mini` で元に戻す |
| 通知 | `hermes send --to ntfy "test"` | iPhone の ntfy アプリに届く |
| vault への記録 | 「これ Inbox に: テスト」と送る | vault に commit が push され、名義が Hermes Agent |
| セッションの書き出し | Webapp で `/new` を実行 | vault の `Agents/Hermes-Agent/sessions/` に Markdown が増える |
| 設定の即時変更 | `/model --global` で別のモデルに切り替え、`ls -l ~/.hermes/config.yaml` と `git -C ~/.hermes/workspace/dot-hermes status --short` を見る | symlink のままで、dot-hermes の作業ツリーに差分が出る。`/model` はスラッシュコマンドで `config.yaml` を直接書き換えるため、自動では commit されない。Hermes に commit を依頼するか、自分で commit する |
| 追従 | `hermes update --check` | 更新の有無が表示される |

モデル ID `claude-sonnet-5-5` が Hermes 側で通らなかった場合は、`hermes model` で選び直す。
その後、dot-hermes で `config.yaml` の diff を commit して push する。

## 既知の注意点

- Hermes が `config.yaml` を書き直すと、キーの並びや `_config_version` の差分が出る。commit は Hermes が行うので、差分は dot-hermes の履歴で確認できる。
- `hermes update` での更新は、dotfiles の履歴にも CI にも残らない。
- upstream が `nix/pnpm-deps-hash` をプラットフォーム別に持つようになれば、Nix パッケージに戻せる。
- oberon の Hermes (`hosts/oberon/hermes-agent.nix`) は別途撤去する。
- mac-mini の `~/.hermes/github-ssh-key` は `secrets/oberon.yaml` の `hermes-github-ssh-key` を復号したもの。oberon の Hermes を撤去するときに、このキーを消さない。
