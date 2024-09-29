require('telescope').setup{
  extensions = {
    frecency = {
      ignore_patterns = { '*.git/*', '*./tmp/*', '*/node_modules/*' },
      db_safe_mode = false,
      auto_validate = true,
    }
  }
}

local option = { noremap = true, silent = true }

-- vim.keymap.set('n', '<Leader>ff', '<Cmd>Telescope find_files<CR>', option)
vim.keymap.set('n', '<Leader>ff', '<Cmd>Telescope git_files<CR>', option)
vim.keymap.set('n', '<Leader>f/', '<Cmd>Telescope live_grep<CR>', option)
vim.keymap.set('n', '<Leader>fb', '<Cmd>Telescope buffers<CR>', option)
vim.keymap.set('n', '<Leader>fl', '<Cmd>Telescope current_buffer_fuzzy_find<CR>', option)
vim.keymap.set('n', '<Leader>gs', '<Cmd>Telescope git_status<CR>', option)
vim.keymap.set('n', '<Leader>gs', '<Cmd>Telescope git_status<CR>', option)
vim.keymap.set('n', '<Leader><Leader>', '<Cmd>Telescope frecency<CR>', option)
vim.keymap.set('n', '<C-g>', '<Cmd>Telescope grep_string<CR>', option)
vim.keymap.set('n', '<Leader>co', '<Cmd>Telescope commands<CR>', option)
