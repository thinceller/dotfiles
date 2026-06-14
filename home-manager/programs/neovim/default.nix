{ pkgs, sources, ... }:
let
  loadPluginOptionally = map (p: {
    plugin = p;
    optional = false;
  });

  direnv-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "direnv.nvim";
    inherit (sources.direnv-nvim) version src;
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = false;
    # init.lua は home-manager に生成させ、lua/ 配下のモジュールをここから読み込む。
    # configs/.config/nvim/lua/ は files.nix で out-of-store symlink され live-edit 可能。
    initLua = ''
      require("base")
      require("keymaps")
      require("lz.n").load("plugins")
    '';
    extraPackages = with pkgs; [
      # language servers
      biome
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
      typescript-go
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
        nui-nvim
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
        neo-tree-nvim
        oil-nvim
        nvim-web-devicons
        # status line
        lualine-nvim
        # git
        gitsigns-nvim
        lazygit-nvim
        openingh-nvim
        # misc
        bufdelete-nvim
        direnv-nvim
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
