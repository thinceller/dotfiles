vim.cmd("packadd vim-jetpack")

require("jetpack.paq")({
  { "tani/vim-jetpack" },
  -- color scheme
  {
    "haishanh/night-owl.vim",
    event = { "VimEnter", "ColorSchemePre" },
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
    config = function()
      require("plugins/lualine")
    end,
  },
  -- git
  {
    "kdheepak/lazygit.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins/lazygit")
    end,
  },
  -- misc
  {
    "famiu/bufdelete.nvim",
    event = "VimEnter",
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
