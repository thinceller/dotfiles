# LSP Configuration Reference

## LSP Server Setup

This configuration uses Neovim's native `vim.lsp.enable()` API with `nvim-lspconfig`.

### Current LSP Servers

| Server | Languages |
|--------|-----------|
| `lua_ls` | Lua |
| `nixd` | Nix |
| `ts_ls` | TypeScript, JavaScript |
| `biome` | TypeScript, JavaScript, JSON |
| `html` | HTML |
| `cssls` | CSS |
| `tailwindcss` | Tailwind CSS |
| `ruby_lsp` | Ruby |
| `rust_analyzer` | Rust |
| `terraformls` | Terraform |
| `dockerls` | Dockerfile |
| `docker_compose_language_service` | Docker Compose |
| `hls` | Haskell |
| `jsonls` | JSON |
| `typos_lsp` | Typo checking |

### Adding a New LSP Server

Edit `configs/.config/nvim/lua/plugins/lsp.lua`:

```lua
for _, ls in pairs({
  -- Existing servers...
  "new_lsp_server",  -- Add here
}) do
  vim.lsp.enable(ls)
end
```

### Custom Server Configuration

Add server-specific settings with `vim.lsp.config()`:

```lua
if ls == "new_server" then
  vim.lsp.config(ls, {
    settings = {
      newServer = {
        optionA = true,
        optionB = "value",
      },
    },
  })
end
```

### nixd Configuration Example

```lua
if ls == "nixd" then
  vim.lsp.config(ls, {
    settings = {
      formatting = {
        command = "nixfmt",
      },
    },
  })
end
```

## LSP Keymaps

Keymaps are set in the `LspAttach` autocmd:

| Key | Action |
|-----|--------|
| `gD` | Go to declaration |
| `gd` | Go to definition |
| `K` | Hover documentation |
| `gi` | Go to implementation |
| `<C-k>` | Signature help |
| `<leader>D` | Type definition |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `gr` | Find references |
| `<leader>cf` | Format buffer |
| `<leader>dl` | Diagnostics list |

### Adding Custom LSP Keymaps

```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    -- Add custom keymaps
    vim.keymap.set("n", "<leader>xx", function()
      -- Custom action
    end, opts)
  end,
})
```

## Diagnostics Configuration

```lua
vim.diagnostic.config({
  virtual_text = true,      -- Inline diagnostics
  signs = true,             -- Gutter signs
  underline = true,         -- Underline problems
  update_in_insert = false, -- Update after leaving insert
  severity_sort = true,     -- Sort by severity
})
```

## Troubleshooting

### Check LSP Status
```vim
:LspInfo
:checkhealth lsp
```

### View Server Logs
```vim
:LspLog
```

### Restart LSP
```vim
:LspRestart
```
