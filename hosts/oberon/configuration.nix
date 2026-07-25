{ userConfig, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./users.nix
    ./forgejo.nix
    ./cloudflared.nix
    ./hermes-agent.nix
    ./tailscale.nix
    ../../nixos/modules/common.nix
  ];

  networking.hostName = userConfig.hostname;

  # 2GB RAM の VPS では swap 無しだと nixos-rebuild の評価・ビルドが OOM で死ぬ。
  # root ext4 上に 4GiB の swapfile を確保してビルド時のメモリ逼迫を吸収する。
  swapDevices = [
    {
      device = "/swapfile";
      size = 4096; # MiB
    }
  ];

  # zram: 2GB RAM でエージェント (claude/opencode) を回すための圧縮スワップ。
  # 既存の /swapfile (4GiB, ディスク) より優先度が高く、先に zram が使われる。
  zramSwap.enable = true;

  # mosh: スマホ (Moshi アプリ) からの接続でモバイル回線の切断・ローミングを
  # 吸収する。UDP 60000-61000 のグローバル開放はせず、tailscale0 を
  # trustedInterfaces に入れることで tailnet 内からのみ到達可能にする
  # (tailscale.nix 参照)。
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  # herdr / home-manager のユーザー環境は fish 前提 (herdr config の
  # default_shell = "fish")。login shell 登録のため system 側でも有効化する。
  programs.fish.enable = true;

  # さくらのVPS は SeaBIOS (legacy BIOS) なので、UEFI 系の systemd-boot ではなく
  # GRUB を BIOS モードで使う。
  # 書き込み先 device は disko 側で EF02 partition から自動設定されるため、
  # ここで `boot.loader.grub.device` を指定すると mirroredBoots 重複エラーになる。
  boot.loader.grub.enable = true;

  system.stateVersion = "25.11";
}
