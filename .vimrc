"================================================
" basic
"================================================

set helplang=ja,en
set ruler
set number relativenumber
set title
set mouse=a
set visualbell
set background=dark
set termguicolors
set expandtab
set tabstop=4
set smarttab
set shiftwidth=2
set softtabstop=2
set smartindent
set cursorline
set wildmenu
set wrap
set whichwrap=b,s,h,l,<,>,~,[,]
set display=lastline
set ignorecase
set smartcase
set splitbelow
set list
set listchars=tab:»-,space:･,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

"================================================
" mappings
"================================================

inoremap <silent> jj <ESC>
nnoremap ; :
nnoremap : ;
nnoremap Y y$
nnoremap U <C-r>
nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprev<CR>

"================================================
" plugins
"================================================
call plug#begin()

Plug 'vim-jp/vimdoc-ja'

call plug#end()
