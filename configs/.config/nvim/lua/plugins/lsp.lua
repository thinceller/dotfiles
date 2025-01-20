return {
  {
    "nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    after = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lspconfig = require("lspconfig")

      lspconfig.lua_ls.setup({ capabilities = capabilities })
      lspconfig.nixd.setup({ capabilities = capabilities })
      lspconfig.ts_ls.setup({ capabilities = capabilities })
    end,
  },
}
