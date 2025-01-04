vim.cmd("packadd vim-jetpack")

require("jetpack.packer").startup(function(use)
  use({ "tani/vim-jetpack" })
  -- color scheme
  use({
    "oxfist/night-owl.nvim",
    config = function()
      require("plugins/night-owl")
    end,
  })
  use({
    "xiyaowong/nvim-transparent",
    config = function()
      require("plugins/nvim-transparent")
    end,
  })
  -- lua plugins
  use("nvim-lua/plenary.nvim")
  -- denops
  use({
    "vim-denops/denops.vim",
    requires = { "vim-denops/denops-shared-server.vim" },
    config = function()
      require("plugins/denops")
    end,
  })
  -- fuzzy finder
  use({
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins/telescope")
    end,
  })
  use({
    "nvim-telescope/telescope-frecency.nvim",
    config = function()
      require("telescope").load_extension("frecency")
    end,
  })
  use({
    "nvim-telescope/telescope-github.nvim",
    config = function()
      require("telescope").load_extension("gh")
    end,
  })
  -- file explorer
  use({
    "stevearc/oil.nvim",
    requires = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("plugins/oil")
    end,
  })
  -- status line
  use({
    "nvim-lualine/lualine.nvim",
    requires = { "oxfist/night-owl.nvim" },
    config = function()
      require("plugins/lualine")
    end,
  })
  -- git
  use({
    "lewis6991/gitsigns.nvim",
    config = function()
      require("plugins/gitsigns")
    end,
  })
  use({
    "kdheepak/lazygit.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins/lazygit")
    end,
  })
  -- misc
  use("vim-jp/vimdoc-ja")
  use({
    "famiu/bufdelete.nvim",
    config = function()
      require("plugins/bufdelete")
    end,
  })
  use({
    "shortcuts/no-neck-pain.nvim",
    config = function()
      require("plugins/no-neck-pain")
    end,
  })
  use({
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end,
  })
  use({
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  })
  use("machakann/vim-sandwich")
end)

-- automatic plugin installation
-- https://github.com/tani/vim-jetpack#automatic-plugin-installation-on-startup
local jetpack = require("jetpack")
for _, name in ipairs(jetpack.names()) do
  if not jetpack.tap(name) then
    jetpack.sync()
    break
  end
end
