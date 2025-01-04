require("oil").setup({
  view_options = {
    show_hidden = true,
  },
})

vim.keymap.set("n", "<Leader>e", "<Cmd>Oil<CR>", { noremap = true, silent = true })
