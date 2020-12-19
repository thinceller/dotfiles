if empty(globpath(&rtp, 'plugged/vim-bufkill'))
  finish
endif

let g:BufKillCreateMappings = 0
nnoremap <leader>q :exec 'BD'<CR>
