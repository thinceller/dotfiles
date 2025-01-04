require("lualine").setup({
  theme = "night-owl",
  tabline = {
    lualine_a = {
      {
        "buffers",
        show_filename_only = false,
      },
    },
  },
  winbar = {
    lualine_b = {
      {
        "filetype",
        colored = true,
        icon_only = true,
      },
    },
    lualine_c = {
      {
        "filename",
        path = 1,
      },
    },
  },
  inactive_winbar = {
    lualine_b = {
      {
        "filetype",
        colored = true,
        icon_only = true,
      },
    },
    lualine_c = {
      {
        "filename",
        path = 1,
      },
    },
  },
  extensions = { "oil" },
})
