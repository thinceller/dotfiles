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
        "eslint",
        "stylelint_lsp",
        "tailwindcss",
        "rubocop",
        "ruby_lsp",
        "rust_analyzer",
        "terraformls",
        "dockerls",
        "docker_compose_language_service",
        "typos_lsp",
      }) do
        local config = {}

        if ls == "eslint" then
          config = {
            on_attach = function(_, buf)
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = buf,
                command = "EslintFixAll",
              })
            end,
          }
        elseif ls == "stylelint_lsp" then
          config = {
            root_dir = lspconfig.util.root_pattern(
              "stylelint.config.js",
              "stylelint.config.mjs",
              "stylelint.config.cjs"
            ),
            settings = {
              stylelintplus = {
                autoFixOnSave = true,
              },
            },
          }
        elseif ls == "nixd" then
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
        end,
      })
    end,
  },
}
