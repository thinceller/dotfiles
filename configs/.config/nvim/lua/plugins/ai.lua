return {
  {
    "claude-code.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("claude-code").setup({
        window = {
          position = "vertical",
        },
      })
    end,
  },
  {
    "copilot-lsp",
    event = "DeferredUIEnter",
    after = function()
      require("copilot-lsp").setup({})
    end,
  },
  {
    "copilot.lua",
    event = "DeferredUIEnter",
    after = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<Tab>",
          },
        },
        nes = {
          enabled = true,
          keymap = {
            accept_and_goto = "<Leader>p",
            accept = false,
            dismiss = "<Esc>",
          },
        },
      })
    end,
  },
}
