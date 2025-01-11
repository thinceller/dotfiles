require("nvim-treesitter.configs").setup({
  ensure_installed = "all",
  ignore_install = { "phpdoc" },
  -- highlight = {
  --   enable = true,
  --   disable = { 'ruby' },
  --   additional_vim_regex_highlighting = false,
  -- },
  indent = {
    enable = true,
  },
  endwise = {
    enable = true,
  },
  context_commentstring = {
    enable = true,
  },
  autotag = {
    enable = true,
  },
})
