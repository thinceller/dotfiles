return {
  {
    "nvim-lspconfig",
    after = function()
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true })

      local capabilities = require("ddc_source_lsp").make_client_capabilities()
      local lspconfig = require("lspconfig")

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
      })
      lspconfig.nixd.setup({
        capabilities = capabilities,
      })
    end,
  },
}
