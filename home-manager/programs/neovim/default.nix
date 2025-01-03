{ pkgs }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = false;
    plugins = with pkgs.vimPlugins; [
      vim-jetpack
    ];
  };
}
