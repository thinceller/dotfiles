require("no-neck-pain").setup({
  width = 120,
})

vim.keymap.set("n", "<Leader>np", "<Cmd>NoNeckPain<CR>", { noremap = true, silent = true })
