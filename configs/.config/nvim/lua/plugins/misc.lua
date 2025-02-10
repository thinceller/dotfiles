return {
  {
    "bufdelete.nvim",
    event = "DeferredUIEnter",
    after = function()
      vim.keymap.set("n", "<Leader>q", "<Cmd>bdelete<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "zen-mode.nvim",
    after = function()
      require("zen-mode").setup({
        window = {
          backdrop = 1,
          width = 140,
        },
      })
      vim.keymap.set("n", "<Leader>z", "<Cmd>ZenMode<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "nvim-autopairs",
    event = "DeferredUIEnter",
    after = function()
      require("nvim-autopairs").setup()
    end,
  },
  {
    "Comment.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("Comment").setup()
    end,
  },
  {
    "vim-sandwich",
    event = "DeferredUIEnter",
  },
}
