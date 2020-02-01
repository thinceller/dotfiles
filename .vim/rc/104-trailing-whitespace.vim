if empty(globpath(&rtp, 'plugged/vim-trailing-whitespace'))
  finish
endif

let g:extra_whitespace_ignored_filetypes = ['startify']
