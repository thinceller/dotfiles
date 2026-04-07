{
  pkgs,
  ...
}:
{
  fonts = {
    packages = with pkgs; [
      hackgen-font
      hackgen-nf-font
      plemoljp
      plemoljp-nf
      udev-gothic
      udev-gothic-nf
    ];
  };
}
