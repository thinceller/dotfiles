" ==================================================================
"  Basic settings
" ==================================================================
let g:python_host_prog = $PYENV_ROOT.'/versions/neovim2/bin/python'
let g:python3_host_prog = $PYENV_ROOT.'/versions/neovim3/bin/python'

if &compatible
  set nocompatible
endif

set encoding=utf-8
scriptencoding utf-8
" set helplang=ja,en
set ruler
set number
set title
set laststatus=2
set mouse=a
set visualbell t_vb=

set background=dark
syntax enable
if (has("termguicolors"))
  set termguicolors
endif
let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"

autocmd ColorScheme * highlight LineNr ctermfg=12
highlight CursorLineNr ctermbg=4 ctermfg=0
set cursorline
" terminal color - like night-owl
let g:terminal_ansi_colors = [
\ '#000000',
\ '#ef5350',
\ '#22da6e',
\ '#addb67',
\ '#82aaff',
\ '#c792ea',
\ '#21c7a8',
\ '#ffffff',
\ '#575656',
\ '#ef5350',
\ '#22da6e',
\ '#ffeb95',
\ '#82aaff',
\ '#c792ea',
\ '#7fdbca',
\ '#ffffff'
\ ]
autocmd BufEnter *.{js,jsx,ts,tsx} :syntax sync fromstart
autocmd BufLeave *.{js,jsx,ts,tsx} :syntax sync clear

" set autoindent
set smartindent

set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set smarttab

set wildmenu

set wrap
set whichwrap=b,s,h,l,<,>,~,[,]
set display=lastline

" file formats
"set fileformats=unix,doc,mac

set incsearch
set hlsearch
set ignorecase
set smartcase
set wrapscan
set gdefault

" set splitright
set splitbelow

set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

set wildmode=list:longest,full

set showcmd

set clipboard=unnamed

set backspace=indent,eol,start
set nrformats-=octal

" complement size
set pumheight=10

set showmatch
set matchtime=1
source $VIMRUNTIME/macros/matchit.vim " Vimの「%」を拡張する

set hidden

" rendering performance
set ttyfast
set lazyredraw

set nobackup
set nowritebackup
set backupdir=$HOME/.vim/backup
set noundofile
set undodir=$HOME/.vim/backup
set noswapfile

" ==================================================================
"   Key mappings
" ==================================================================
inoremap <silent> jj <ESC>
nnoremap ; :

nnoremap Y y$

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

