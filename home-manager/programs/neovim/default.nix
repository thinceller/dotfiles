{ pkgs }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = false;
    plugins = with pkgs.vimPlugins; [
      lz-n
      # color scheme
      night-owl-nvim
      transparent-nvim
      # lua plugins
      plenary-nvim
      # denops
      denops-vim
      # completion and lsp
      ddc-vim
      pum-vim
      ddc-ui-pum
      # fuzzy finder
      telescope-nvim
      telescope-frecency-nvim
      telescope-github-nvim
      # file explorer
      oil-nvim
      nvim-web-devicons
      # status line
      lualine-nvim
      # git
      gitsigns-nvim
      lazygit-nvim
      # misc
      bufdelete-nvim
      no-neck-pain-nvim
      nvim-autopairs
      comment-nvim
      vim-sandwich
    ];
  };
}
