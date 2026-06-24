# Linux Builder (nix-darwin)

Apple Silicon の Mac (`aarch64-darwin`) で x86_64-linux 向けの OCI / Docker イメージを Nix で
ビルドするための remote builder。`kohei-m4-mac-mini` / `SC-N-843` で有効化済み
([`nix-darwin/modules/nix-linux-builder.nix`](../../nix-darwin/modules/nix-linux-builder.nix))。

> 初回セットアップ・guest 構成 (`config`) の変更手順・CI への Cachix seed は
> [`linux-builder-bootstrap.md`](./linux-builder-bootstrap.md) を参照。

## 概要

`nix.linux-builder` は macOS の Virtualization framework 上に最小構成の NixOS VM を起動し、
**remote build machine** として Nix daemon に登録する。`nix build` / `darwin-rebuild` が
Linux 向け derivation を要求すると、ローカル SSH 経由でこの VM に処理が委譲される。

OCI イメージの中身 (glibc, coreutils, アプリ本体 …) はすべて **Linux derivation** であり、
darwin 単体では realize できない。そのため OCI イメージのビルドには linux-builder が要る。

## x86_64 はエミュレーション

Apple Silicon では VM は **aarch64-linux** ゲストとして動くため、**x86_64-linux ビルドは常に
QEMU user-mode emulation (binfmt) 経由**になる (Rosetta ではない)。通すには **2 つの設定が
両方** 必要:

| 設定 | 場所 | 役割 |
| --- | --- | --- |
| `nix.linux-builder.systems` に `x86_64-linux` | host (Mac) | daemon が x86_64 ジョブをこの builder へ振り分ける (広告) |
| `config.boot.binfmt.emulatedSystems = [ "x86_64-linux" ]` | guest (VM) | VM 内で x86_64 を実行可能にする (binfmt 登録) |

> host の `nix.settings.extra-platforms` は不要 (ローカルビルド用)。委譲は
> `buildMachines[].systems` で制御される。

**性能**: エミュレーションはネイティブの 5〜10 倍以上遅い。ただし一般的な x86_64-linux
パッケージは `cache.nixos.org` から substitute されるため、コストを払うのは主に「自前の
x86_64 コードをビルドするとき」。重い x86_64 ビルドが多いなら
[`cpick/nix-rosetta-builder`](https://github.com/cpick/nix-rosetta-builder) (Rosetta ベース)
も検討。

## x86_64-linux OCI イメージをビルドする

中身を x86_64 にする素直でキャッシュの効く方法は、**`system = "x86_64-linux"` で nixpkgs を
import** すること (`architecture` は自動で `amd64`)。ローカルロードは store に tar を作らない
`streamLayeredImage` が推奨。別プロジェクトの `flake.nix` の例:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      hostSystem = "aarch64-darwin"; # ビルドを実行する Mac
      pkgsLinuxX86 = import nixpkgs { system = "x86_64-linux"; }; # 中身の target arch
    in
    {
      packages.${hostSystem}.container = pkgsLinuxX86.dockerTools.streamLayeredImage {
        name = "myapp";
        tag = "latest";
        contents = [ pkgsLinuxX86.cowsay ];
        config.Cmd = [ "${pkgsLinuxX86.cowsay}/bin/cowsay" "hello from x86_64-linux" ];
      };
    };
}
```

```bash
# streamLayeredImage: result は tar を stdout に吐くスクリプト
nix build .#container
./result | docker load
docker run --rm myapp:latest
```

`buildLayeredImage` / `buildImage` を使うと result が gzip tarball になり
`docker load < result` でロードする。レジストリへ高速 push したい場合は
[`nix2container`](https://github.com/nlewo/nix2container) も選択肢 (copy 処理も Linux で
走るため linux-builder は必要)。

## 動作確認

```bash
# VM が起動しているか
sudo launchctl list org.nixos.linux-builder

# /etc/nix/machines が両 system を広告しているか
cat /etc/nix/machines

# ネイティブ aarch64-linux ビルド
nix build --impure --expr \
  '(with import <nixpkgs> { system = "aarch64-linux"; }; runCommand "t" {} "uname -a > $out")'
cat result   # -> Linux ... aarch64 GNU/Linux

# エミュレート x86_64-linux ビルド
nix build --impure --expr \
  '(with import <nixpkgs> { system = "x86_64-linux"; }; runCommand "t" {} "uname -a > $out")'
cat result   # -> Linux ... x86_64 GNU/Linux
```

## トラブルシューティング

- **`Failed to find a machine for remote build!` / `a required feature is not supported`**:
  `systems` に `x86_64-linux` が無い、または binfmt が未設定。両方揃っているか確認。
- **`connect to host localhost port 31022: Connection refused`**: VM の起動待ち。数十秒待つ
  か `sudo launchctl kickstart -k system/org.nixos.linux-builder`。
- **`failed to start SSH connection`**: root の known_hosts 未登録。
  [`linux-builder-bootstrap.md`](./linux-builder-bootstrap.md) の「ホスト鍵について」参照。
- **鍵の権限エラー**: `/etc/nix/builder_ed25519` は `600` のまま。`644` にすると SSH が
  「too open」で拒否する。ユーザーから読みたい場合は `sudo chown $USER /etc/nix/builder_ed25519`。
- **`diskSize` を変えても反映されない**: qcow2 の作り直しが必要 (nix-darwin #1200)。
  [`linux-builder-bootstrap.md`](./linux-builder-bootstrap.md) の PHASE 2 の注記参照。
- **VM 状態が壊れた** (`User not known to the underlying authentication module` 等):
  `ephemeral = true` で再適用、または `sudo rm -f /var/lib/linux-builder/*.qcow2`。

## 参考

- nixpkgs docs — darwin-builder: <https://github.com/NixOS/nixpkgs/blob/master/doc/packages/darwin-builder.section.md>
- Nixcademy — Build and Deploy Linux Systems from macOS: <https://nixcademy.com/posts/macos-linux-builder/>
- nixpkgs manual — dockerTools: <https://ryantm.github.io/nixpkgs/builders/images/dockertools/>
- nix-darwin module source: <https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/linux-builder.nix>
- 参考記事 (takeokunn): <https://www.takeokunn.org/posts/fleeting/20251130151735-run_nixos_apple_linux_builder/>
