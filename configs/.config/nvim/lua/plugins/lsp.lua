return {
  {
    "nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    after = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lspconfig = require("lspconfig")

      for _, ls in pairs({
        "lua_ls",
        "nixd",
        "jsonls",
        "ts_ls",
        "html",
        "cssls",
        "tailwindcss",
        "ruby_lsp",
        "rust_analyzer",
        "terraformls",
        "dockerls",
        "docker_compose_language_service",
        "typos_lsp",
      }) do
        local config = {}

        if ls == "nixd" then
          config = {
            settings = {
              formatting = {
                command = "nixfmt",
              },
            },
          }
        end

        config.capabilities = capabilities
        lspconfig[ls].setup(config)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        -- group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          -- Mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          -- vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
          -- vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
          -- vim.keymap.set("n", "<space>wl", function()
          --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          -- end, opts)
          vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
          end, opts)

          -- vim.api.nvim_create_autocmd("BufWritePre", {
          --   buffer = ev.buf,
          --   callback = function()
          --     vim.lsp.buf.format({ async = false })
          --   end,
          -- })
        end,
      })
    end,
  },
  {
    "conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    after = function()
      local available = function(formatter, bufnr)
        return require("conform").get_formatter_info(formatter, bufnr).available
      end

      local js_formatters = function(bufnr)
        local config = {}
        if available("eslint_d", bufnr) then
          table.insert(config, "eslint_d")
        end
        if available("biome-check", bufnr) then
          table.insert(config, "biome-check")
        end
        if available("prettier", bufnr) then
          table.insert(config, "prettier")
        end
        return config
      end

      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          nix = { "nixfmt" },
          javascript = js_formatters,
          javascriptreact = js_formatters,
          typescript = js_formatters,
          typescriptreact = js_formatters,
          json = js_formatters,
          css = { "stylelint", "prettier" },
          scss = { "stylelint", "prettier" },
          ruby = { "rubocop" },
        },
        format_after_save = {
          lsp_format = "fallback",
        },
      })
    end,
  },
}
