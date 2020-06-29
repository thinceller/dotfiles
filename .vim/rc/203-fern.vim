if empty(globpath(&rtp, 'plugged/fern.vim'))
  finish
endif

let g:fern#renderer = "devicons"
let g:fern#default_hidden = 1

augroup fern-custom
  autocmd! *
  autocmd FileType fern set nonumber
augroup END

nnoremap <leader>e :Fern . -reveal=% -drawer -toggle<CR>
