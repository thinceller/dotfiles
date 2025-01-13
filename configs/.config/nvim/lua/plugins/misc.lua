return {
  {
    "bufdelete.nvim",
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
}
