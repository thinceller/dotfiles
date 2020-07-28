" colorschemeを変更するたびに変更する
if empty(globpath(&rtp, 'plugged/night-owl.vim'))
  finish
endif

colorscheme night-owl
" colorscheme iceberg
autocmd BufRead,BufNewFile *.jsx,*.tsx set filetype=typescript.tsx

" hi SpecialKey ctermbg=NONE ctermfg=238 guibg=NONE guifg=NONE
augroup TransparentBG
  autocmd!
  autocmd VimEnter,Colorscheme * hi Normal ctermbg=NONE
  autocmd VimEnter,Colorscheme * hi NonText ctermbg=NONE
  autocmd VimEnter,Colorscheme * hi EndOfBuffer ctermbg=NONE
  autocmd VimEnter,Colorscheme * hi LineNr ctermbg=NONE
  autocmd VimEnter,Colorscheme * hi CursorLineNr ctermbg=NONE
augroup END

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
