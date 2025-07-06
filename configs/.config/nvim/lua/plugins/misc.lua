return {
  {
    "bufdelete.nvim",
    event = "DeferredUIEnter",
    after = function()
      vim.keymap.set("n", "<Leader>q", "<Cmd>bdelete<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "zen-mode.nvim",
    after = function()
      require("zen-mode").setup({
        window = {
          backdrop = 1,
          width = 140,
        },
      })
      vim.keymap.set("n", "<Leader>z", "<Cmd>ZenMode<CR>", { noremap = true, silent = true })
    end,
  },
  {
    "nvim-autopairs",
    event = "DeferredUIEnter",
    after = function()
      require("nvim-autopairs").setup()
    end,
  },
  {
    "Comment.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("Comment").setup()
    end,
  },
  {
    "vim-sandwich",
    event = "DeferredUIEnter",
  },
  {
    "startup.nvim",
    after = function()
      require("startup").setup({
        theme = "my_theme",
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "startup" },
        callback = function()
          vim.opt_local.spell = false
        end,
      })
    end,
  },
  {
    "fidget.nvim",
    after = function()
      require("fidget").setup()
    end,
  },
  {
    "toggleterm.nvim",
    after = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 20
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.3
          end
        end,
      })

      local opt = { noremap = true, silent = true }
      vim.keymap.set("n", "<Leader>th", "<Cmd>ToggleTerm direction=horizontal<CR>", opt)
      vim.keymap.set("n", "<Leader>tv", "<Cmd>ToggleTerm direction=vertical<CR>", opt)

      function _G.set_terminal_keymaps()
        -- Disable temporarily as claude-code.nvim prevents sending the Esc key
        -- vim.keymap.set("t", "<ESC>", [[<C-\><C-n>]], opt)
        vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opt)
      end
      vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
    end,
  },
}
