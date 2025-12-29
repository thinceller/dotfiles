# Formatter Configuration Reference

## conform.nvim Setup

This configuration uses `conform.nvim` for formatting with format-on-save enabled.

### Current Formatters

| Filetype | Formatters |
|----------|------------|
| `lua` | stylua |
| `nix` | nixfmt |
| `javascript` | eslint_d, biome-check, prettier (conditional) |
| `javascriptreact` | eslint_d, biome-check, prettier (conditional) |
| `typescript` | eslint_d, biome-check, prettier (conditional) |
| `typescriptreact` | eslint_d, biome-check, prettier (conditional) |
| `json` | eslint_d, biome-check, prettier (conditional) |
| `css` | stylelint, prettier |
| `scss` | stylelint, prettier |
| `ruby` | rubocop |

### Adding a Simple Formatter

Edit `configs/.config/nvim/lua/plugins/lsp.lua`:

```lua
require("conform").setup({
  formatters_by_ft = {
    -- Existing formatters...
    python = { "black", "isort" },
    go = { "gofmt", "goimports" },
  },
})
```

### Conditional Formatter Selection

Use a function to conditionally select formatters:

```lua
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
    javascript = js_formatters,
    typescript = js_formatters,
  },
})
```

### Checking Formatter Availability

```lua
local available = function(formatter, bufnr)
  return require("conform").get_formatter_info(formatter, bufnr).available
end
```

## Format on Save

Currently configured with 1 second timeout:

```lua
format_on_save = {
  timeout_ms = 1000,
},
```

### Disable Format on Save

```lua
format_on_save = false,
```

### Conditional Format on Save

```lua
format_on_save = function(bufnr)
  -- Skip for certain filetypes
  if vim.bo[bufnr].filetype == "markdown" then
    return false
  end
  return { timeout_ms = 1000 }
end,
```

## LSP Fallback

When no formatter is configured, conform falls back to LSP formatting:

```lua
default_format_opts = {
  lsp_format = "fallback",
},
```

## Manual Formatting

Format current buffer:
```vim
:lua require("conform").format()
```

Format with specific options:
```lua
require("conform").format({
  async = true,
  timeout_ms = 2000,
})
```

## Custom Formatter Configuration

Override formatter settings:

```lua
require("conform").setup({
  formatters = {
    stylua = {
      prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
    },
  },
})
```
