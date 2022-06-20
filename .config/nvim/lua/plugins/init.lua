vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use {
    'haishanh/night-owl.vim',
    event = { "VimEnter", "ColorSchemePre" },
    -- config = function() require('plugins/night-owl') end,
  }
  use {
    "EdenEast/nightfox.nvim",
    config = function ()
      require('plugins/nightfox')
    end
  }
  use 'kyazdani42/nvim-web-devicons'

  -- denops.vim
  use 'vim-denops/denops.vim'

  -- lua plugins
  use 'nvim-lua/plenary.nvim'
  use 'tami5/sqlite.lua'
  use 'MunifTanjim/nui.nvim'

  -- fuzzy finder
  use {
    'nvim-telescope/telescope.nvim',
    -- requires = { {'nvim-lua/plenary.nvim'} }
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
  use 'hrsh7th/cmp-nvim-lsp'
  use {
    'neovim/nvim-lspconfig',
    config = function()
      require('plugins/nvim-lspconfig')
    end,
  }
  use {
    'williamboman/nvim-lsp-installer',
    config = function()
      require('plugins/nvim-lsp-installer')
    end,
  }
  use {
    'hrsh7th/nvim-cmp',
    config = function()
      require('plugins/nvim-cmp')
    end,
  }
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-emoji'
  use 'f3fora/cmp-spell'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/cmp-vsnip'
  use 'hrsh7th/vim-vsnip'
  use 'hrsh7th/cmp-nvim-lsp-signature-help'
  use 'davidsierradz/cmp-conventionalcommits'

  use 'folke/lsp-colors.nvim'
  
  use {
    'j-hui/fidget.nvim',
    config = function()
      require('fidget').setup({})
    end
  }

  -- treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
  }

  -- filer
  use {
    'nvim-neo-tree/neo-tree.nvim',
      branch = 'v2.x',
      config = function()
        require('plugins/neo-tree')
      end
  }

  -- coding
  use {
    'windwp/nvim-autopairs',
    config = function() require('nvim-autopairs').setup {} end,
  }

  -- git
  use {
    'lewis6991/gitsigns.nvim',
    config = function() require('gitsigns').setup() end,
  }
end)
