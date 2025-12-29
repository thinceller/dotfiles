-- Example: Adding a new plugin with lz.n format
-- This file demonstrates various plugin configurations

-- Basic plugin with lazy loading on events
return {
  -- Simple plugin with event-based loading
  {
    "plugin-author/plugin-name",
    event = { "BufReadPre", "BufNewFile" },
    after = function()
      require("plugin-name").setup({
        option1 = true,
        option2 = "value",
      })
    end,
  },

  -- Plugin with deferred UI loading
  {
    "ui-plugin/example",
    event = "DeferredUIEnter",
    after = function()
      require("example").setup()
    end,
  },

  -- Plugin with filetype-specific loading
  {
    "language/plugin",
    ft = { "python", "rust" },
    after = function()
      require("plugin").setup()
    end,
  },

  -- Plugin with key-based loading
  {
    "keymap-plugin/example",
    keys = {
      { "<leader>xx", mode = "n" },
      { "<leader>xy", mode = { "n", "v" } },
    },
    after = function()
      require("example").setup()
      vim.keymap.set("n", "<leader>xx", function()
        require("example").action()
      end, { desc = "Example action" })
    end,
  },

  -- Plugin with dependencies
  {
    "complex-plugin/example",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    after = function()
      require("example").setup()
    end,
  },

  -- Plugin with conditional enabling
  {
    "optional-plugin/example",
    enabled = function()
      return vim.fn.executable("required-binary") == 1
    end,
    event = "VeryLazy",
    after = function()
      require("example").setup()
    end,
  },
}
