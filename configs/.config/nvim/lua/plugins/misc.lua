return {
  {
    "bufdelete.nvim",
    event = "DeferredUIEnter",
    after = function()
      vim.keymap.set("n", "<Leader>q", "<Cmd>bdelete<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "no-neck-pain.nvim",
    after = function()
      require("no-neck-pain").setup({
        width = 120,
        autocmds = {
          enableOnVimEnter = true,
        },
        buffers = {
          wo = {
            fillchars = "eob: ",
          },
        },
      })

      vim.keymap.set("n", "<Leader>np", "<Cmd>NoNeckPain<CR>", { noremap = true, silent = true })
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
