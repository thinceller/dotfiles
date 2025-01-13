return {
  {
    "gitsigns.nvim",
    after = function()
      require("gitsigns").setup({
        current_line_blame = true,
        current_line_blame_opts = {
          delay = 100,
        },
      })
    end,
  },
  {
    "lazygit.nvim",
    after = function()
      vim.keymap.set("n", "<Leader>gg", "<Cmd>LazyGit<CR>", { noremap = true, silent = true })
    end,
  },
}