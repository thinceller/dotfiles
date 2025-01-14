return {
  {
    "oil.nvim",
    after = function()
      require("oil").setup({
        view_options = {
          show_hidden = true,
        },
      })

      vim.keymap.set("n", "<Leader>o", "<Cmd>Oil<CR>", { noremap = true, silent = true })
    end,
  },
}
