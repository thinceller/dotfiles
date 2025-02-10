return {
  header = {
    type = "text",
    align = "center",
    highlight = "Statement",
    margin = 5,
    content = require("startup.headers").hydra_header,
  },
  header_2 = {
    type = "text",
    align = "center",
    highlight = "Constant",
    margin = 5,
    content = require("startup.functions").quote(),
  },
  body = {
    type = "mapping",
    align = "center",
    fold_section = false,
    title = "Basic Commands",
    margin = 5,
    content = {
      { "Git File", "Telescope git_files", "<Leader>ff" },
      { "Recents", "Telescope frecency", "<Leader><Leader>" },
    },
    highlight = "String",
  },
  body_2 = {
    type = "oldfiles",
    oldfiles_directory = true,
    align = "center",
    fold_section = false,
    title = "Oldfiles of Directory",
    margin = 5,
    content = "startup.nvim",
    highlight = "String",
    oldfiles_amount = 5,
  },
  footer = {
    type = "oldfiles",
    oldfiles_directory = false,
    align = "center",
    fold_section = true,
    title = "Oldfiles",
    margin = 5,
    content = "startup.nvim",
    highlight = "TSString",
    oldfiles_amount = 5,
  },
  clock = {
    type = "text",
    align = "center",
    fold_section = false,
    title = "",
    margin = 5,
    content = function()
      local date = "󰃭 " .. os.date("%Y-%m-%d")
      local clock = " " .. os.date("%H:%M")
      return { string.format("%s %s", date, clock) }
    end,
    highlight = "TSString",
  },
  options = {
    after = function()
      require("startup.utils").oldfiles_mappings()
    end,
    mapping_keys = true,
    cursor_column = 0.5,
    empty_lines_between_mappings = true,
    disable_statuslines = true,
    paddings = { 2, 2, 2, 2, 2, 2, 2 },
  },
  parts = {
    "header",
    "header_2",
    "body",
    "body_2",
    "footer",
    "clock",
  },
}
