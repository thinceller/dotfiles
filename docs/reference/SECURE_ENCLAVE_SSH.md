# Secure Enclave SSH 鍵 (個人 Mac) マニュアル

このドキュメントでは、個人 Mac で github.com への SSH 認証と git commit 署名を macOS Secure Enclave の鍵で行う手動運用手順について説明します。

## 概要

個人 Mac (`hosts/kohei-m4-mac-mini`, `userConfig.isPersonal = true`) では、github.com への SSH 認証と git commit 署名を 1Password SSH agent ではなく macOS Secure Enclave の鍵で行っている。

理由は Claude Code の Remote Control との相性である。モバイルから Mac のセッションを操作すると、1Password の鍵利用承認プロンプトが Mac 上に出てモバイルからは承認できず作業が止まる。1Password 側にリモート承認・承認省略の機能は無い (feature request CFP-19201、回答なし)。

他ホスト (oberon-cf, forgejo.thinceller.dev など) と仕事 Mac (SC-N-843) は引き続き 1Password を使う。

Nix 側の設定はすでに入っている:

- `home-manager/programs/ssh/default.nix`: `Host github.com` に `IdentityFile ~/.ssh/id_github_se`, `IdentitiesOnly yes`, `IdentityAgent none`, `SecurityKeyProvider /usr/lib/ssh-keychain.dylib` を設定
- `home-manager/programs/git/default.nix`: `user.signingkey` を `~/.ssh/id_github_se` に設定。`gpg.ssh.program` は `SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib` を export して `/usr/bin/ssh-keygen` を exec するラッパー `ssh-sign-se`

鍵ファイル自体は Nix 管理外で、端末ごとに手動作成が必要。macOS 14+ 標準の `sc_auth create-ctk-identity` で作成でき、Secretive 等の追加ツールは不要。

## 初回セットアップ

```bash
sc_auth create-ctk-identity -l github -k p-256-ne -t none
sc_auth list-ctk-identities            # Public Key Hash を控える (削除時に使う)
cd ~/.ssh
SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=true ssh-keygen -w /usr/lib/ssh-keychain.dylib -K -N ""
mv id_ecdsa_sk_rk     id_github_se
mv id_ecdsa_sk_rk.pub id_github_se.pub
chmod 600 id_github_se
```

- `-k p-256-ne`: OpenSSH は p-384 に非対応のため p-256 を指定
- `-t none`: Touch ID を要求しない。代わりに Mac 上の任意のプロセスが承認なしで push / 署名できる割り切りになるが、秘密鍵自体は SE から取り出せない
- `id_github_se` は SE 内の鍵へのハンドルであり、秘密鍵本体は含まない
- `SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=true` は OpenSSH 10 の PIN プロンプトを回避するため

GitHub への登録 (同じ公開鍵を認証用・署名用に 2 回登録する)。`gh` に `admin:public_key,admin:ssh_signing_key` スコープが必要:

```bash
gh auth refresh -h github.com -s admin:public_key,admin:ssh_signing_key

gh ssh-key add ~/.ssh/id_github_se.pub --type authentication --title "<hostname> secure-enclave"
gh ssh-key add ~/.ssh/id_github_se.pub --type signing        --title "<hostname> secure-enclave"
```

疎通確認 (Nix 適用前でも可):

```bash
ssh -o IdentityAgent=none -o IdentitiesOnly=yes -o SecurityKeyProvider=/usr/lib/ssh-keychain.dylib -i ~/.ssh/id_github_se -T git@github.com
```

その後 Nix を適用する:

```bash
sudo darwin-rebuild switch --flake .#<host>
```

既存の 1Password 鍵は GitHub に登録したままにする (過去 commit の Verified 表示を維持するため、また他ホスト用に引き続き使うため)。

## 新しい Mac を追加するとき

Secure Enclave の鍵は端末固有で、バックアップ・移行はできない。新しい Mac では上記「初回セットアップ」を再度実行する。対象は `isPersonal = true` のホストのみ。

## 確認コマンド

```bash
sc_auth list-ctk-identities
ssh -T git@github.com
git log --show-signature -1
gh api repos/<owner>/<repo>/commits/<sha> --jq .commit.verification
```

## トラブルシューティング

- **`Permission denied (publickey)`**: `gh ssh-key list` で GitHub 側に鍵が登録されているか確認し、`ssh -v git@github.com` で `SecurityKeyProvider` と `IdentityFile` が効いているか確認する
- **`Failed to get TKTokenDriver configuration`**: Claude Code の sandbox 内で実行している可能性が高い。sandbox 内では CryptoTokenKit (ctkd) への XPC が塞がれ `sc_auth` はこのエラーで失敗する。`git commit *` / `git push *` / `ssh *` は `home-manager/programs/claude-code/default.nix` の `excludedCommands` により sandbox 外で実行されるため、通常はこの問題を踏まない
- **`sc_auth list-ctk-identities` の `Valid To` (作成から 1 年) が切れている**: OpenSSH はこの有効期限を参照しないため、切れていても動作する
- **`ssh-keygen -K` で PIN を聞かれる**: `SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=true` を付けて実行する
- **1Password のプロンプトが github.com で出る**: `~/.ssh/config` で `Host github.com` が `Host *` より前に定義されているか確認する

## 鍵の削除 / ロールバック

```bash
sc_auth delete-ctk-identity -h <Public Key Hash>
gh ssh-key delete <authentication 用の ID>
gh ssh-key delete <signing 用の ID>
rm ~/.ssh/id_github_se ~/.ssh/id_github_se.pub
```

その後 Nix 側の変更を revert し、`darwin-rebuild switch` を実行する。

## 実測結果 (2026-08-30)

macOS 26.5.2, OpenSSH 10.2p1 で検証。`-t none` の SE 鍵 (`sk-ecdsa-sha2-nistp256@openssh.com`) で GitHub への SSH 認証は成功した (`Hi thinceller!`)。

GitHub は `no-touch-required` オプション付き公開鍵の登録を拒否するが、`-t none` 鍵の公開鍵にはそのオプションが付かないため問題は起きなかった。ファイル鍵への fallback は不要だった。

## 参考リンク

- [mizdra: Secure Enclave で git commit の署名鍵を管理する](https://www.mizdra.net/entry/2026/08/07/101542)
- https://gist.github.com/arianvp/5f59f1783e3eaf1a2d4cd8e952bb4acf
- https://www.1password.dev/ssh/agent/security
- https://github.com/orgs/community/discussions/10593
