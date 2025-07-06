return {
  {
    "claude-code.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("claude-code").setup({
        window = {
          position = "vertical",
        },
        command = "~/.claude/local/claude",
      })
    end,
  },
}
