vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use { 'wbthomason/packer.nvim', opt = true }

  use {
    'haishanh/night-owl.vim',
    event = { 'VimEnter', 'ColorSchemePre' },
    -- config = function() require('plugins/night-owl') end,
  }
  use {
    'EdenEast/nightfox.nvim',
    event = { 'VimEnter', 'ColorSchemePre' },
    config = function ()
      require('plugins/nightfox')
    end
  }
  use { 'kyazdani42/nvim-web-devicons', after = 'nightfox.nvim' }
  use {
    'xiyaowong/nvim-transparent',
    after = 'nightfox.nvim',
    config = function ()
      require('plugins/nvim-transparent')
    end
  }

  -- denops.vim
  use 'vim-denops/denops.vim'

  -- lua plugins
  use 'nvim-lua/plenary.nvim'
  use 'tami5/sqlite.lua'
  use 'MunifTanjim/nui.nvim'

  -- fuzzy finder
  use {
    'nvim-telescope/telescope.nvim',
    after = 'nightfox.nvim',
    config = function()
      require('plugins/telescope')
    end,
  }
  use {
    'nvim-telescope/telescope-frecency.nvim',
    after = { 'telescope.nvim' },
    config = function()
      require('telescope').load_extension('frecency')
    end
  }
  use {
    'nvim-telescope/telescope-github.nvim',
    after = { 'telescope.nvim' },
    config = function ()
      require('telescope').load_extension('gh')
    end
  }

  -- lsp
  use {
    'onsails/lspkind-nvim',
    config = function()
      require('plugins/lspkind-nvim')
    end,
  }
  use { 'hrsh7th/cmp-nvim-lsp', after = 'nvim-cmp' }
  use {
    'neovim/nvim-lspconfig',
    event = { 'VimEnter' },
    config = function()
      require('plugins/nvim-lspconfig')
    end,
  }
  use {
    'williamboman/nvim-lsp-installer',
    after = { 'nvim-lspconfig', 'cmp-nvim-lsp' },
    config = function()
      require('plugins/nvim-lsp-installer')
    end,
  }
  use {
    'hrsh7th/nvim-cmp',
    event = { 'VimEnter' },
    config = function()
      require('plugins/nvim-cmp')
    end,
  }
  use { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' }
  use { 'hrsh7th/cmp-path', after = 'nvim-cmp' }
  use { 'hrsh7th/cmp-emoji', after = 'nvim-cmp' }
  use { 'f3fora/cmp-spell', after = 'nvim-cmp' }
  use { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp' }
  use { 'hrsh7th/cmp-vsnip', after = 'nvim-cmp' }
  use { 'hrsh7th/vim-vsnip', after = 'nvim-cmp' }
  use { 'hrsh7th/cmp-nvim-lsp-signature-help', after = 'nvim-cmp' }
  use { 'davidsierradz/cmp-conventionalcommits', after = 'nvim-cmp' }

  use 'folke/lsp-colors.nvim'

  use {
    'j-hui/fidget.nvim',
    after = 'nvim-lsp-installer',
    config = function()
      require('fidget').setup({})
    end
  }

  -- treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    after = 'nightfox.nvim',
    config = function ()
      require('plugins/nvim-treesitter')
    end
  }
  use {
    'RRethy/nvim-treesitter-endwise',
    after = 'nvim-treesitter'
  }
  use {
    'JoosepAlviste/nvim-ts-context-commentstring',
    after = 'nvim-treesitter'
  }
  use {
    'windwp/nvim-ts-autotag',
    after = 'nvim-treesitter'
  }

  -- filer
  use {
    'nvim-neo-tree/neo-tree.nvim',
      branch = 'v2.x',
      event = 'VimEnter',
      config = function()
        require('plugins/neo-tree')
      end
  }
  use {
    'famiu/bufdelete.nvim',
    event = 'VimEnter',
    config = function ()
      require('plugins/bufdelete')
    end
  }

  -- statusline
  use {
    'nvim-lualine/lualine.nvim',
    after = 'nightfox.nvim',
    config = function()
      require('plugins/lualine')
    end
  }

  -- coding
  use {
    'windwp/nvim-autopairs',
    event = 'VimEnter',
    config = function() require('nvim-autopairs').setup {} end,
  }
  use {
    'numToStr/Comment.nvim',
    event = 'VimEnter',
    config = function()
      require('Comment').setup()
    end
  }
  use {
    'machakann/vim-sandwich',
    event = 'VimEnter',
  }

  -- formatter
  use { 'bronson/vim-trailing-whitespace', event = 'VimEnter' }
  use { 'gpanders/editorconfig.nvim', event = 'VimEnter' }

  -- git
  use {
    'lewis6991/gitsigns.nvim',
    event = 'VimEnter',
    config = function() require('plugins/gitsigns') end,
  }

  -- highlight
  use {
    'RRethy/vim-illuminate',
    event = 'VimEnter'
  }
  use {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    config = function()
      require('todo-comments').setup()
    end
  }
  -- use {
  --   'lukas-reineke/indent-blankline.nvim',
  --   event = 'VimEnter',
  --   config = function ()
  --     require('plugins.indent-blankline')
  --   end
  -- }

  -- terminal
  use {
    'akinsho/toggleterm.nvim',
    tag = 'v1.*',
    config = function()
      require('plugins/toggleterm')
    end
  }

  -- browser
  use {
    'tyru/open-browser.vim',
    event = 'VimEnter'
  }
  use {
    'tyru/open-browser-github.vim',
    after = 'open-browser.vim'
  }

  -- test
  use {
    'klen/nvim-test',
    event = 'VimEnter',
    config = function()
      require('plugins/nvim-test')
    end
  }
end)
