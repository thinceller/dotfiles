{ userConfig, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ./users.nix
    ./forgejo.nix
    ./cloudflared.nix
    ../../nixos/modules/common.nix
  ];

  networking.hostName = userConfig.hostname;

  # さくらのVPS は SeaBIOS (legacy BIOS) なので、UEFI 系の systemd-boot ではなく
  # GRUB を BIOS モードで使う。
  # 書き込み先 device は disko 側で EF02 partition から自動設定されるため、
  # ここで `boot.loader.grub.device` を指定すると mirroredBoots 重複エラーになる。
  boot.loader.grub.enable = true;

  system.stateVersion = "25.11";
}
