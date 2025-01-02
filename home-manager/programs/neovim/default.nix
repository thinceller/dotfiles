{ pkgs, sources }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = false;
    plugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = sources.vim-jetpack.pname;
        version = sources.vim-jetpack.version;
        src = sources.vim-jetpack.src;
      })
    ];
  };
}
