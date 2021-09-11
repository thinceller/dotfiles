if empty(globpath(&rtp, 'plugged/nvim-treesitter'))
  finish
endif

au BufRead,BufNewFile *.graphql   setfiletype graphql
au BufRead,BufNewFile *.graphqls  setfiletype graphql
au BufRead,BufNewFile *.gql       setfiletype graphql

if has('nvim')
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = {
    enable = true,
    disable = {
      "ruby",
      "c_sharp",
      "vue",
      "haskell",
    }
  }
}
EOF
endif
