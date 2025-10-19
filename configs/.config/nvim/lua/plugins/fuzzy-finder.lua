return {
  {
    "telescope.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("telescope").setup({
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--hidden",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          live_grep = {
            glob_pattern = { "!**/node_modules/**", "!.git" },
          },
        },
        extensions = {
          frecency = {
            ignore_patterns = { "*.git/*", "*./tmp/*", "*/node_modules/*" },
            db_safe_mode = false,
            auto_validate = true,
          },
        },
      })

      local builtin = require("telescope.builtin")
      local frecency = require("telescope").extensions.frecency
      local gh = require("telescope").extensions.gh
      local option = { noremap = true, silent = true }

      -- vim.keymap.set('n', '<Leader>ff', '<Cmd>Telescope find_files<CR>', option)
      vim.keymap.set("n", "<Leader>ff", builtin.git_files, option)
      vim.keymap.set("n", "<Leader>f/", builtin.live_grep, option)
      vim.keymap.set("n", "<Leader>fb", builtin.buffers, option)
      vim.keymap.set("n", "<Leader>fc", builtin.commands, option)
      vim.keymap.set("n", "<Leader>fk", builtin.keymaps, option)
      vim.keymap.set("n", "<Leader>fl", builtin.current_buffer_fuzzy_find, option)
      vim.keymap.set("n", "<Leader>fd", builtin.diagnostics, option)
      vim.keymap.set("n", "<Leader>gs", builtin.git_status, option)
      vim.keymap.set("n", "<Leader>ghp", gh.pull_request, option)
      vim.keymap.set("n", "<Leader><Leader>", frecency.frecency, option)
      vim.keymap.set("n", "<C-g>", builtin.grep_string, option)
    end,
  },
}
