if empty(globpath(&rtp, 'plugged/nvim-treesitter'))
  finish
endif

if has('nvim')
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "all",
  highlight = {
    enable = true,
    disable = {
      "ruby",
      "c_sharp",
      "vue",
    }
  }
}
EOF
endif
