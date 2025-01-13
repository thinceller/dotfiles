return {
  {
    "blink.cmp",
    after = function()
      require("blink.cmp").setup({
        keymap = {
          preset = "default",
          ["<C-space>"] = {},
          ["<C-t>"] = { "show", "show_documentation", "hide_documentation" },
          ["<CR>"] = { "accept", "fallback" },
          cmdline = {
            preset = "default",
          },
        },
        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = "mono",
        },
        sources = {
          default = { "lsp", "path", "buffer" },
          providers = {
            lsp = {
              name = "LSP",
              module = "blink.cmp.sources.lsp",
            },
          },
        },
        completion = {
          list = {
            selection = "auto_insert",
          },
          menu = {
            border = "single",
            draw = {
              columns = { { "kind_icon" }, { "label", "label_description", "source_name", gap = 1 } },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            window = { border = "single" },
          },
        },
        signature = {
          enabled = true,
          window = { border = "single" },
        },
      })
    end,
  },
}
