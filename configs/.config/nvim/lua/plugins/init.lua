vim.cmd("packadd vim-jetpack")

require("jetpack.paq")({
  { "tani/vim-jetpack" },
  -- color scheme
  {
    "oxfist/night-owl.nvim",
    config = function()
      require("plugins/night-owl")
    end,
  },
  {
    "xiyaowong/nvim-transparent",
    config = function()
      require("plugins/nvim-transparent")
    end,
  },
  -- lua plugins
  "nvim-lua/plenary.nvim",
  -- denops
  {
    "vim-denops/denops.vim",
    requires = { "vim-denops/denops-shared-server.vim" },
    config = function()
      require("plugins/denops")
    end,
  },
  -- fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins/telescope")
    end,
  },
  {
    "nvim-telescope/telescope-frecency.nvim",
    config = function()
      require("telescope").load_extension("frecency")
    end,
  },
  {
    "nvim-telescope/telescope-github.nvim",
    config = function()
      require("telescope").load_extension("gh")
    end,
  },
  -- file explorer
  {
    "stevearc/oil.nvim",
    requires = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("plugins/oil")
    end,
  },
  -- status line
  {
    "nvim-lualine/lualine.nvim",
    requires = { "oxfist/night-owl.nvim" },
    config = function()
      require("plugins/lualine")
    end,
  },
  -- git
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("plugins/gitsigns")
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins/lazygit")
    end,
  },
  -- misc
  "vim-jp/vimdoc-ja",
  {
    "famiu/bufdelete.nvim",
    config = function()
      require("plugins/bufdelete")
    end,
  },
  {
    "shortcuts/no-neck-pain.nvim",
    config = function()
      require("plugins/no-neck-pain")
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },
  "machakann/vim-sandwich",
})

-- automatic plugin installation
-- https://github.com/tani/vim-jetpack#automatic-plugin-installation-on-startup
local jetpack = require("jetpack")
for _, name in ipairs(jetpack.names()) do
  if not jetpack.tap(name) then
    jetpack.sync()
    break
  end
end
