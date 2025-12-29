---
name: Neovim Config
description: This skill should be used when the user asks to "add a new plugin", "configure LSP", "add keymaps", "modify Neovim settings", "set up completion", "configure formatters", or mentions Neovim, nvim, or plugin configuration in this dotfiles repository.
---

# Neovim Config Helper

Provide guidance for managing Neovim configuration in this dotfiles repository.

## Configuration Overview

This Neovim setup uses:
- **Lua-based configuration** with `init.lua` as the entry point
- **lz.n** for lazy loading plugin management
- **nvim-lspconfig** with native `vim.lsp.enable()` for LSP
- **conform.nvim** for formatting
- **blink.cmp** for completion

## Directory Structure

```
configs/.config/nvim/
├── init.lua              # Entry point (loads base, keymaps, plugins)
├── lua/
│   ├── base.lua          # Basic vim options (numbers, tabs, search, etc.)
│   ├── keymaps.lua       # Global keymaps (leader = space)
│   └── plugins/          # Plugin configurations by category
│       ├── appearance.lua    # Theme, statusline (tokyonight, lualine)
│       ├── lsp.lua           # LSP servers and conform.nvim
│       ├── completion.lua    # Completion engine (blink.cmp)
│       ├── fuzzy-finder.lua  # Telescope
│       ├── file-explorer.lua # File browser (oil.nvim)
│       ├── git.lua           # Git integration
│       ├── ai.lua            # AI tools
│       ├── misc.lua          # Miscellaneous plugins
│       └── basis.lua         # Core dependencies (denops)
```

## Common Tasks

### Adding a New Plugin

Add to the appropriate category file in `lua/plugins/` using lz.n format:

```lua
{
  "plugin-name",
  event = { "BufReadPre", "BufNewFile" },
  after = function()
    require("plugin-name").setup({
      -- Plugin configuration
    })
  end,
}
```

See `examples/new-plugin.lua` for complete examples including:
- Event-based, filetype-based, and key-based lazy loading
- Dependencies and conditional enabling

### Adding an LSP Server

Edit `lua/plugins/lsp.lua`:

```lua
for _, ls in pairs({
  -- Existing servers...
  "new_lsp_server",
}) do
  vim.lsp.enable(ls)
end
```

For custom server configuration:

```lua
if ls == "new_server" then
  vim.lsp.config(ls, {
    settings = { ... },
  })
end
```

See `references/lsp-configuration.md` for the full server list and detailed configuration options.

### Adding a Formatter

Edit `lua/plugins/lsp.lua` in the conform.nvim setup:

```lua
require("conform").setup({
  formatters_by_ft = {
    -- Existing formatters...
    python = { "black", "isort" },
  },
})
```

See `references/formatters.md` for conditional formatters and advanced configuration.

### Modifying Completion

Edit `lua/plugins/completion.lua` for blink.cmp settings.

See `references/completion.md` for keymap customization and source configuration.

### Adding Keymaps

**Global keymaps** - Edit `lua/keymaps.lua`:

```lua
vim.keymap.set("n", "<leader>xx", function()
  -- Action
end, { desc = "Description" })
```

**LSP keymaps** - Modify the `LspAttach` autocmd in `lua/plugins/lsp.lua`.

## Key Conventions

- **Leader**: Space
- **`;` and `:`**: Swapped for easier command mode
- **`jj`**: Exit insert mode
- **LSP**: `gd` (definition), `gr` (references), `K` (hover), `<leader>ca` (code action)

## Configuration Notes

1. **Out-of-Store Symlinks**: Edits apply immediately without Nix rebuild
2. **Format on Save**: Enabled by default (1 second timeout)
3. **Backup Directory**: Unused configs stored in `lua/plugins/backup/`

## Troubleshooting

```vim
:LspInfo          " Check LSP status
:checkhealth      " General health check
:ConformInfo      " Check formatter status
```

## Additional Resources

- **`references/lsp-configuration.md`** - LSP servers, keymaps, diagnostics
- **`references/formatters.md`** - conform.nvim configuration
- **`references/completion.md`** - blink.cmp configuration
- **`examples/new-plugin.lua`** - Plugin configuration patterns
- **`examples/custom-lsp-server.lua`** - LSP setup examples
- **`examples/custom-formatter.lua`** - Formatter configuration examples
