if empty(globpath(&rtp, 'plugged/vim-fugitive'))
  finish
endif

nnoremap [fugitive] <Nop>
nmap <space>g [fugitive]

nnoremap <silent> [fugitive]b :Gblame<CR>
nnoremap <silent> [fugitive]d :Gdiff<CR>
