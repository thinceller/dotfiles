vim.g.mapleader = ' '
-- vim.g.maplocalleader = "\\"

vim.keymap.set('i', 'jj', '<Esc>', { silent = true })
vim.keymap.set('n', ';', ':', {})
vim.keymap.set('n', ':', ';', {})
vim.keymap.set('n', 'Y', 'y$', {})
vim.keymap.set('n', 'U', '<C-r>', {})
vim.keymap.set('n', '<C-n>', ':bnext<CR>', {})
vim.keymap.set('n', '<C-p>', ':bprev<CR>', {})
vim.keymap.set('n', '+', '<C-a>', {})
vim.keymap.set('n', '-', '<C-x>', {})
vim.keymap.set('n', '<Esc><Esc>', '<Cmd>nohlsearch<CR>', { silent = true })
