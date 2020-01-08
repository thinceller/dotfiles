" colorschemeを変更するたびに変更する
if empty(globpath(&rtp, 'plugged/iceberg.vim'))
  finish
endif

colorscheme iceberg
autocmd BufRead,BufNewFile *.jsx,*.tsx set filetype=typescript.tsx

hi SpecialKey ctermbg=NONE ctermfg=238 guibg=NONE guifg=NONE

" hi Normal guibg=NONE ctermbg=NONE
" hi NonText guibg=NONE ctermbg=NONE
" hi EndOfBuffer guibg=NONE ctermbg=NONE
" hi LineNr guibg=NONE ctermbg=NONE
" hi CursorLineNr guibg=NONE ctermbg=NONE

let g:terminal_ansi_colors = [
\ '#161821',
\ '#e27878',
\ '#b4be82',
\ '#e2a478',
\ '#84a0c6',
\ '#a093c7',
\ '#89b8c2',
\ '#c6c8d1',
\ '#6b7089',
\ '#e98989',
\ '#c0ca8e',
\ '#e9b189',
\ '#91acd1',
\ '#ada0d3',
\ '#95c4ce',
\ '#d2d4de'
\ ]
