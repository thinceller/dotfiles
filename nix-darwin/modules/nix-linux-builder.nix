# nix-darwin の linux-builder。macOS の Virtualization framework 上に NixOS の
# VM を立て、Linux 向け derivation のビルドをこの VM へ委譲する (remote builder)。
#
# 主目的は Apple Silicon (aarch64-darwin) 上で x86_64-linux 向け OCI イメージを
# ビルドすること。VM 自体は aarch64-linux のため、x86_64-linux は QEMU の
# user-mode emulation (binfmt) でエミュレート実行される。
#
# 仕組み (2 つが揃って初めて x86_64 ビルドが通る):
#   1. systems に x86_64-linux を含める     -> host 側 Nix daemon がこの builder に
#                                              x86_64-linux ジョブを振り分けるようになる
#   2. config.boot.binfmt.emulatedSystems   -> VM 内で QEMU を binfmt 登録し、
#                                              x86_64 バイナリを実行可能にする
#
# binfmt 入りのカスタム guest は cache に無く、ビルドに linux-builder 自身が要る
# (chicken-and-egg)。新規マシン導入や config 変更時の 2 段階手順・CI への Cachix
# seed は docs/linux-builder-bootstrap.md を参照。日常利用は docs/LINUX_BUILDER.md。
{
  ...
}:
{
  nix.linux-builder = {
    enable = true;

    # host の Nix daemon に「この builder へ振り分けてよい system」を広告する。
    # aarch64-linux はネイティブ、x86_64-linux は下の binfmt でエミュレート実行。
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    # guest (VM) 側の NixOS 構成。
    config = {
      # aarch64 VM 内に QEMU x86_64 emulator を binfmt 登録する。
      # これにより VM の nix.settings.extra-platforms にも x86_64-linux が
      # 自動追加され、x86_64-linux derivation を実行できるようになる。
      boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

      # エミュレートビルドはメモリ・ディスクを食うのでデフォルト
      # (1 core / 3GB / 20GB) から引き上げる。
      virtualisation = {
        cores = 6;
        darwin-builder = {
          memorySize = 8 * 1024; # MiB = 8GB
          diskSize = 50 * 1024; # MiB = 50GB
        };
      };
    };
  };

  # remote builder への委譲は trusted user に対してのみ行われる。
  # trusted-users (root + ユーザー名) は nix.nix で設定済み。
}
