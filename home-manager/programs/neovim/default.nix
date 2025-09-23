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
      docker-compose-language-service
      dockerfile-language-server
      haskell-language-server
      lua-language-server
      nixd
      eslint_d
      rubocop
      ruby-lsp
      rust-analyzer
      stylelint-lsp
      tailwindcss-language-server
      terraform-ls
      typescript-language-server
      typos-lsp
      vscode-langservers-extracted
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
        conform-nvim
        # AI tools
        claude-code-nvim
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
        startup-nvim
        fidget-nvim
        toggleterm-nvim
      ];
  };
}
