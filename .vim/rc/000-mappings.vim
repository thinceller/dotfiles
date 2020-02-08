inoremap <silent> jj <ESC>
nnoremap ; :
nnoremap : ;

nnoremap Y y$

nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprev<CR>

let mapleader = "\<Space>"

" terminal
if has('nvim')
  nnoremap <leader>t :sp<CR>:term<CR>
  nnoremap tig :tab :term tig<CR>
  au TermOpen * tnoremap <Esc> <c-\><c-n>
  au FileType fzf tunmap <Esc>
  autocmd TermOpen * setlocal norelativenumber
  autocmd TermOpen * setlocal nonumber
else
  command! Terminal call popup_create(term_start([&shell], #{ hidden: 1, term_finish: 'close'}), #{ border: [], minwidth: winwidth(0)/2, minheight: &lines/2 })

  nnoremap <leader>t :bo term ++close<CR>
  nnoremap tig :tab :term ++close tig<CR>
endif

nnoremap <C-]> g<C-]>
" nnoremap <C-h> :vsp<CR> :exe("tjump ".expand('<cword>'))<CR>
" nnoremap <C-k> :split<CR> :exe("tjump ".expand('<cword>'))<CR>

nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>

augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

