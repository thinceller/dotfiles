{ pkgs }:
let
  loadPluginOptionally = map (p: {
    plugin = p;
    optional = false;
  });
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = false;
    extraPackages = with pkgs; [
      # language servers
      lua-language-server
      nixd
      typescript-language-server
    ];
    plugins =
      with pkgs.vimPlugins;
      [ lz-n ]
      ++ loadPluginOptionally [
        # color scheme
        night-owl-nvim
        tokyonight-nvim
        transparent-nvim
        nvim-treesitter.withAllGrammars
        # lua plugins
        plenary-nvim
        # denops
        denops-vim
        # completion and lsp
        blink-cmp
        nvim-lspconfig
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
        nvim-autopairs
        comment-nvim
        vim-sandwich
        zen-mode-nvim
      ];
  };
}
