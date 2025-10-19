return {
  header = {
    type = "text",
    align = "center",
    highlight = "Statement",
    margin = 5,
    content = {
      "████████╗██╗  ██╗██╗███╗   ██╗ ██████╗███████╗██╗     ██╗     ███████╗██████╗ ",
      "╚══██╔══╝██║  ██║██║████╗  ██║██╔════╝██╔════╝██║     ██║     ██╔════╝██╔══██╗",
      "   ██║   ███████║██║██╔██╗ ██║██║     █████╗  ██║     ██║     █████╗  ██████╔╝",
      "   ██║   ██╔══██║██║██║╚██╗██║██║     ██╔══╝  ██║     ██║     ██╔══╝  ██╔══██╗",
      "   ██║   ██║  ██║██║██║ ╚████║╚██████╗███████╗███████╗███████╗███████╗██║  ██║",
      "   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝",
      "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
      "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
      "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
      "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
      "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
    },
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
      { "Git File", "Telescope git_files", "<leader>ff" },
      { "Git Status", "Telescope git_status", "<leader>gs" },
      { "Live Grep", "Telescope live_grep", "<leader>f/" },
      { "GitHub PRs", "Telescope gh pull_request", "<leader>ghp" },
      { "Recents", "Telescope frecency", "<leader><leader>" },
    },
    highlight = "String",
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
  footer = {
    type = "text",
    align = "center",
    fold_section = false,
    title = "",
    margin = 5,
    content = function()
      local packpath_plugins = vim.fn.globpath(vim.o.packpath, "pack/*/start/*", 0, 1)
      local count = 0
      for _, plugin in ipairs(packpath_plugins) do
        -- Exclude treesitter grammar plugins from count
        if not plugin:match("treesitter%-grammar%-") then
          count = count + 1
        end
      end
      return { string.format("📦 %d plugins loaded", count) }
    end,
    highlight = "TSString",
  },
  options = {
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
    "clock",
    "footer",
  },
}
