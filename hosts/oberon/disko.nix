{
  # さくらのVPS は SeaBIOS (legacy BIOS) なので、ESP (UEFI) ではなく
  # GPT 上に BIOS boot partition (type EF02, 1MiB) を切って GRUB を埋め込む。
  # 残りを ext4 root にする最小構成。
  disko.devices = {
    disk.vda = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            priority = 1;
            size = "1M";
            type = "EF02"; # BIOS boot partition (GRUB が GPT に embed するため)
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
