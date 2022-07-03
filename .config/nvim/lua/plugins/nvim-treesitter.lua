require('nvim-treesitter.configs').setup {
  ensure_installed = 'all',
  ignore_install = { 'phpdoc' },
  highlight = {
    enable = true,
    disable = { 'ruby' },
    additional_vim_regex_highlighting = false,
  },
  endwise = {
    enable = true,
  },
  context_commentstring = {
    enable = true,
  },
  autotag = {
    enable = true,
  }
}
