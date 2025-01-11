return {
  {
    "night-owl.nvim",
    -- should be setup before enabling the color scheme
    -- colorscheme = "night-owl",
    after = function()
      require("night-owl").setup()
      vim.cmd.colorscheme("night-owl")
    end,
  },
  {
    "transparent.nvim",
    after = function()
      require("transparent").setup({
        groups = { -- table: default groups
          "Normal",
          "NormalNC",
          "Comment",
          "Constant",
          "Special",
          "Identifier",
          "Statement",
          "PreProc",
          "Type",
          "Underlined",
          "Todo",
          "String",
          "Function",
          "Conditional",
          "Repeat",
          "Operator",
          "Structure",
          "LineNr",
          "NonText",
          "SignColumn",
          "CursorLineNr",
          "EndOfBuffer",
        },
        extra_groups = {}, -- table: additional groups that should be cleared
        exclude_groups = {}, -- table: groups you don't want to clear
      })
    end,
  },
  {
    "lualine.nvim",
    after = function()
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
    end,
  },
}
