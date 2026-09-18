# Linux Builder のセットアップと経緯

`nix-linux-builder.nix` を**新規マシンに導入する / guest 構成 (`config`) を変更する**ときの
手順と、その背景。日常利用 (OCI イメージのビルド方法など) は
[`LINUX_BUILDER.md`](./LINUX_BUILDER.md) を参照。

## なぜ 2 段階で入れるのか (chicken-and-egg)

binfmt 入りのカスタム guest イメージは `cache.nixos.org` に無く、ビルドに linux-builder
自身が必要になる。だが初回はその builder がまだ存在しない。一方、デフォルト (stock) の
builder イメージは完全に cache 済みで、Linux builder 無しでも起動できる。そこで:

1. **PHASE 1**: stock builder を先に起動する
2. **PHASE 2**: 動き始めた stock builder にカスタム guest をビルドさせる

の 2 段階を踏む。リポジトリ上の `nix-linux-builder.nix` は **PHASE 2 (フル構成) の状態**で
コミットしてある。新規マシンや作り直しのときだけ、いったん PHASE 1 状態に戻して進める。

> **カスタム guest closure が Cachix に seed 済みなら 2 段階は不要**: 後述の
> `thinceller-dotfiles` への seed が済んでいれば、新規マシンでも guest はそこから
> substitute されるため、フル構成のまま `darwin-rebuild switch` するだけでよい
> (`SC-N-843` への導入はこの方法で完了)。`config` を変更した直後など cache に無い
> 状態のときだけ 2 段階手順が必要になる。

## 手順

### 1. stock builder を起動 (PHASE 1)

`nix-linux-builder.nix` は **import を有効にしたまま**、`systems` と `config` ブロックを
**コメントアウトして `enable = true` だけ**にする。この状態なら guest は全て cache から
fetch され (`run-builder` / `create-builder` の darwin スクリプト 2 本だけローカルビルド)、
Linux builder 無しで起動できる。

```bash
sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
sudo launchctl kickstart -k system/org.nixos.nix-daemon   # trusted-users / machines を反映
```

> import 自体を外すと builder が一切立たず PHASE 2 の委譲先が無くなる。`enable = true` は残すこと。

### 2. フル構成を適用 (PHASE 2)

`systems` / `config` のコメントを外して再度 switch する。動いている stock builder が
binfmt 入り guest をビルドする (QEMU のコンパイルが走るため初回は時間がかかる)。完了すると
launchd service が新しい guest で再起動し、x86_64-linux が実行可能になる。

```bash
sudo darwin-rebuild switch --flake .#kohei-m4-mac-mini
```

> **PHASE 2 の switch 後は qcow2 を必ず作り直す**:
>
> ```bash
> sudo rm -f /var/lib/linux-builder/nixos.qcow2
> sudo launchctl kickstart -k system/org.nixos.linux-builder
> ```
>
> 理由は 2 つ。
>
> 1. `diskSize` は qcow2 作成時にしか効かない (nix-darwin #1200)。PHASE 1 で作られた
>    デフォルト 20GB のイメージがそのまま再利用される (memorySize / cores は再起動だけで反映される)。
> 2. guest の `/nix/store` は erofs の store image + qcow2 上の書き込み層 (overlay) で、
>    qcow2 は stock guest と新 guest で共有される。PHASE 2 中に stock guest が書き込んだ
>    store path (新 guest の `nix.conf` や `binfmt_nixos.conf` を含む) は、switch 時の
>    `kickstart -k` による強制終了で **ゼロ長ファイル** として残り、overlay の上位層として
>    store image 内の正しい内容を隠してしまう。結果、新 guest では `/etc/nix/nix.conf` や
>    `/etc/binfmt.d/nixos.conf` が空になり、`systemd-binfmt` は active でも
>    `/proc/sys/fs/binfmt_misc/` に `x86_64-linux` が登録されず x86_64 ビルドだけが失敗する
>    (`path ... is not valid`、ビルドログは空)。

### 3. CI 用に Cachix へ seed

CI (`macos-latest`) は Linux builder を持たず binfmt 入り guest をビルドできない。そのため
ビルド済みの guest closure を `thinceller-dotfiles` Cachix に push しておき、CI はそこから
substitute する。darwin-system の out path closure には guest VM の最終 output
(`linux-builder-start` → `create-builder` → guest `nixos-system`) が runtime 依存として
含まれるので、これを push すれば中間 derivation のビルドは不要になる。

```bash
nix build .#darwinConfigurations.kohei-m4-mac-mini.system --no-link --print-out-paths \
  | cachix push thinceller-dotfiles
```

**`config` 配下の変更だけでなく、flake.lock の更新 (`nix run .#update`) でも guest closure の
hash は変わる。guest 由来の derivation が変わるコミットを push する前に、この seed をやり直すこと。**
さもないと CI の build job が `qemu-x86_64-binfmt-P.drv` の platform mismatch
(aarch64-linux を macos-latest でビルドできない) で失敗する。両ホストとも同じ guest を
参照しているので、seed は片方の host の closure を push すれば足りるが、darwin 側の差分も
cache に載るよう両方 push しておくとよい。

## ホスト鍵について

nix-darwin は builder の host key を pin するため、通常 root の手動 SSH 受け入れは不要
(daemon の offload は自動で通る)。もし `failed to start SSH connection` が出る場合のみ、
root の known_hosts に登録する:

```bash
sudo ssh builder@linux-builder -i /etc/nix/builder_ed25519
# ED25519 host key の確認に yes、その後 exit
```
