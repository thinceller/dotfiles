if empty(globpath(&rtp, 'plugged/vim-polyglot'))
  finish
endif

let g:polyglot_disabled = ['markdown']
