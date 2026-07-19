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

  # claude / opencode は重い Node/Bun プロセスで、forgejo + hermes-agent 常駐の
  # 2GB RAM では逼迫する。zram はディスク swap より桁違いに速く、swapfile に
  # 落ちる前の圧縮バッファとしてスパイクを吸収する (zram が優先され、溢れた分
  # だけ swapfile に行く)。
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # さくらのVPS は SeaBIOS (legacy BIOS) なので、UEFI 系の systemd-boot ではなく
  # GRUB を BIOS モードで使う。
  # 書き込み先 device は disko 側で EF02 partition から自動設定されるため、
  # ここで `boot.loader.grub.device` を指定すると mirroredBoots 重複エラーになる。
  boot.loader.grub.enable = true;

  system.stateVersion = "25.11";
}
