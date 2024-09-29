require('toggleterm').setup {

}

vim.cmd('autocmd TermEnter term://*toggleterm#* tnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>')
vim.keymap.set('n', '<C-t>', '<Cmd>execute v:count1 . "ToggleTerm"<CR>', { noremap = true, silent = true })
vim.keymap.set('i', '<C-t>', '<Esc><Cmd>execute v:count1 . "ToggleTerm"<CR>', { noremap = true, silent = true })
