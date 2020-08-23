if empty(globpath(&rtp, 'plugged/gina.vim'))
  finish
endif

nnoremap <leader>as :Gina status<CR>
nnoremap <leader>ac :Gina commit<CR>
nnoremap <leader>ap :Gina push<CR>
