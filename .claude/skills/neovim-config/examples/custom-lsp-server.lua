-- Example: Adding a custom LSP server with specific configuration
-- Add this to lua/plugins/lsp.lua

-- Step 1: Add to the servers list
for _, ls in pairs({
  "biome",
  "lua_ls",
  "nixd",
  -- Add your new server
  "pyright", -- Python LSP
  "gopls", -- Go LSP
}) do
  -- Step 2: Add custom configuration if needed
  if ls == "pyright" then
    vim.lsp.config(ls, {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "strict",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
          },
        },
      },
    })
  end

  if ls == "gopls" then
    vim.lsp.config(ls, {
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
            shadow = true,
          },
          staticcheck = true,
          gofumpt = true,
        },
      },
    })
  end

  if ls == "lua_ls" then
    vim.lsp.config(ls, {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = { enable = false },
        },
      },
    })
  end

  vim.lsp.enable(ls)
end

-- Step 3: Add custom keymaps for specific LSP features (optional)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local opts = { buffer = ev.buf }

    -- Go-specific keymaps
    if client and client.name == "gopls" then
      vim.keymap.set("n", "<leader>gt", function()
        vim.lsp.buf.execute_command({
          command = "gopls.run_tests",
        })
      end, opts)
    end

    -- Python-specific keymaps
    if client and client.name == "pyright" then
      vim.keymap.set("n", "<leader>po", function()
        vim.lsp.buf.execute_command({
          command = "pyright.organizeimports",
          arguments = { vim.api.nvim_buf_get_name(ev.buf) },
        })
      end, opts)
    end
  end,
})
