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
}
