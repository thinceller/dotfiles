require("lz.n").load({
  {
    "night-owl.nvim",
    -- should be setup before enabling the color scheme
    -- colorscheme = "night-owl",
    after = function()
      require("plugins/night-owl")
    end,
  },
  {
    "transparent.nvim",
    after = function()
      require("plugins/nvim-transparent")
    end,
  },
  {
    "plenary.nvim",
  },
  {
    "denops.vim",
    -- after = function()
    --   require("plugins/denops")
    -- end,
  },
  --     requires = { "vim-denops/denops-shared-server.vim" },
  {
    "ddc.vim",
    after = function()
      require("plugins/ddc")
    end,
  },
  {
    "pum.vim",
  },
  -- {
  --   "ddc-pum-ui",
  -- },
  --       "Shougo/ddc-source-around",
  --       "LumaKernel/ddc-source-file",
  --       "tani/ddc-fuzzy",
  {
    "telescope.nvim",
    after = function()
      require("plugins/telescope")
    end,
  },
  {
    "telescope-frecency.nvim",
  },
  {
    "telescope-github.nvim",
  },
  {
    "oil.nvim",
    after = function()
      require("plugins/oil")
    end,
  },
  {
    "nvim-web-devicons",
  },
  {
    "lualine.nvim",
    after = function()
      require("plugins/lualine")
    end,
  },
  {
    "gitsigns.nvim",
    after = function()
      require("plugins/gitsigns")
    end,
  },
  {
    "lazygit.nvim",
    after = function()
      require("plugins/lazygit")
    end,
  },
  {
    "bufdelete.nvim",
    after = function()
      require("plugins/bufdelete")
    end,
  },
  {
    "no-neck-pain.nvim",
    after = function()
      require("plugins/no-neck-pain")
    end,
  },
  {
    "nvim-autopairs",
    after = function()
      require("nvim-autopairs").setup()
    end,
  },
  {
    "Comment.nvim",
    after = function()
      require("Comment").setup()
    end,
  },
  {
    "vim-sandwich",
  },
})
