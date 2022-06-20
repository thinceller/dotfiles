require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    filtered_items = {
      hide_dotfiles = false,
    },
  }
})

vim.keymap.set('n', '<Leader>e', '<Cmd>NeoTreeRevealToggle<CR>', { noremap = true, silent = true })
