{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      hackgen-font
      hackgen-nf-font
    ];
  };
}
