" colorschemeを変更するたびに変更する
if empty(globpath(&rtp, 'plugged/iceberg.vim'))
  finish
endif

colorscheme iceberg
autocmd BufRead,BufNewFile *.jsx,*.tsx set filetype=typescript.tsx

hi Normal guibg=NONE ctermbg=NONE
hi NonText guibg=NONE ctermbg=NONE
hi EndOfBuffer guibg=NONE ctermbg=NONE
" hi LineNr guibg=NONE ctermbg=NONE
" hi CursorLineNr guibg=NONE ctermbg=NONE

