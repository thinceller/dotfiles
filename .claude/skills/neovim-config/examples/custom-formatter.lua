-- Example: Adding custom formatters with conform.nvim
-- Add this configuration to lua/plugins/lsp.lua in the conform.nvim setup

-- Helper function to check formatter availability
local available = function(formatter, bufnr)
  return require("conform").get_formatter_info(formatter, bufnr).available
end

-- Example: Conditional formatter for Python
local python_formatters = function(bufnr)
  local formatters = {}

  -- Prefer ruff if available
  if available("ruff_format", bufnr) then
    table.insert(formatters, "ruff_format")
    table.insert(formatters, "ruff_fix") -- Also run ruff --fix
  elseif available("black", bufnr) then
    table.insert(formatters, "black")
  end

  -- Always add isort for import sorting
  if available("isort", bufnr) then
    table.insert(formatters, "isort")
  end

  return formatters
end

-- Example: Sequential vs parallel formatters
-- Formatters in same table run sequentially
-- Separate tables run in parallel
local go_formatters = function(bufnr)
  return {
    { "gofumpt", "goimports" }, -- Run these in order
  }
end

require("conform").setup({
  formatters_by_ft = {
    -- Simple single formatter
    lua = { "stylua" },
    nix = { "nixfmt" },

    -- Multiple formatters run sequentially
    rust = { "rustfmt" },

    -- Conditional formatters
    python = python_formatters,

    -- Stop after first formatter succeeds
    markdown = { "prettierd", "prettier", stop_after_first = true },

    -- Apply to all filetypes
    ["_"] = { "trim_whitespace" },
  },

  -- Custom formatter configuration
  formatters = {
    -- Override stylua settings
    stylua = {
      prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
    },

    -- Custom formatter definition
    custom_fmt = {
      command = "custom-formatter",
      args = { "--stdin", "$FILENAME" },
      stdin = true,
    },
  },

  -- Format on save with options
  format_on_save = function(bufnr)
    -- Disable for large files
    local max_lines = 10000
    if vim.api.nvim_buf_line_count(bufnr) > max_lines then
      return false
    end

    -- Disable for certain filetypes
    local disabled_ft = { "sql", "text" }
    if vim.tbl_contains(disabled_ft, vim.bo[bufnr].filetype) then
      return false
    end

    return {
      timeout_ms = 1000,
      lsp_format = "fallback",
    }
  end,
})

-- Manual format command with range support
vim.keymap.set({ "n", "v" }, "<leader>fm", function()
  require("conform").format({
    async = true,
    timeout_ms = 2000,
  })
end, { desc = "Format buffer or selection" })
