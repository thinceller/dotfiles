# Completion Configuration Reference

## blink.cmp Setup

This configuration uses `blink.cmp` as the completion engine.

### Current Configuration

- **Disabled in**: Markdown files
- **Trigger**: InsertEnter event
- **Sources**: LSP, Path, Buffer

### Keymap

| Key | Action |
|-----|--------|
| `<C-t>` | Toggle completion/documentation |
| `<C-n>` | Next item (default) |
| `<C-p>` | Previous item (default) |
| `<C-y>` | Accept completion (default) |

### Modifying Keymaps

Edit `configs/.config/nvim/lua/plugins/completion.lua`:

```lua
require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<C-space>"] = {},  -- Disable
    ["<C-t>"] = { "show", "show_documentation", "hide_documentation" },
    ["<CR>"] = { "accept", "fallback" },  -- Accept on Enter
  },
})
```

## Completion Sources

### Current Sources

```lua
sources = {
  default = { "lsp", "path", "buffer" },
  providers = {
    lsp = {
      name = "LSP",
      module = "blink.cmp.sources.lsp",
    },
  },
},
```

### Adding Custom Sources

```lua
sources = {
  default = { "lsp", "path", "buffer", "snippets" },
  providers = {
    snippets = {
      name = "Snippets",
      module = "blink.cmp.sources.snippets",
    },
  },
},
```

## Menu Appearance

### Current Style

- Border: single line
- Columns: kind icon, label, description, source name

### Customizing Menu

```lua
completion = {
  menu = {
    border = "rounded",  -- Options: single, double, rounded, shadow
    draw = {
      columns = {
        { "kind_icon" },
        { "label", "label_description", "source_name", gap = 1 },
      },
    },
  },
},
```

## Documentation Window

Auto-shows documentation after 500ms:

```lua
documentation = {
  auto_show = true,
  auto_show_delay_ms = 500,
  window = { border = "single" },
},
```

### Disable Auto Documentation

```lua
documentation = {
  auto_show = false,
},
```

## Signature Help

Enabled with single border:

```lua
signature = {
  enabled = true,
  window = { border = "single" },
},
```

## Selection Behavior

Current settings:
- `preselect = true` - First item is preselected
- `auto_insert = true` - Auto-insert selected item

### Modify Selection

```lua
completion = {
  list = {
    selection = {
      preselect = false,  -- Don't preselect
      auto_insert = false,  -- Don't auto-insert
    },
  },
},
```

## Filetype-Specific Configuration

Disable for specific filetypes:

```lua
{
  "blink.cmp",
  enabled = function()
    local disabled_ft = { "markdown", "TelescopePrompt" }
    return not vim.tbl_contains(disabled_ft, vim.bo.filetype)
  end,
}
```

## Command Line Completion

Currently uses "cmdline" preset:

```lua
cmdline = {
  keymap = {
    preset = "cmdline",
  },
},
```
