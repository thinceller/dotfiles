return {
  {
    "neo-tree.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
          },
          follow_current_file = {
            enabled = true,
            leave_dirs_open = true,
          },
        },
      })

      vim.keymap.set("n", "<Leader>e", "<Cmd>Neotree toggle<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "oil.nvim",
    event = "DeferredUIEnter",
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
