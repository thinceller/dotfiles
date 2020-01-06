if &compatible
  set nocompatible
endif

set helplang=ja,en
set encoding=utf-8
scriptencoding utf-8
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

autocmd BufRead,BufNewFile *.jsx set filetype=javascript.jsx
autocmd BufRead,BufNewFile *.tsx set filetype=typescript.tsx

autocmd FileType json syntax match Comment +\/\/.\+$+

set smartindent

set shiftwidth=2
set softtabstop=2
set tabstop=4
set expandtab
set smarttab

set wildmenu

set wrap
set whichwrap=b,s,h,l,<,>,~,[,]
set display=lastline

set incsearch
set hlsearch
set ignorecase
set smartcase
set wrapscan
set gdefault

set splitbelow

set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
" set list lcs=tab:\|\ 

set wildmode=list:longest,full

set showcmd

set clipboard=unnamed

set backspace=indent,eol,start
set nrformats-=octal

" complement size
set pumheight=10

set showmatch
set matchtime=1

set hidden

set ttyfast
set lazyredraw

set nobackup
set nowritebackup
set noundofile
set noswapfile

set updatetime=100
set cmdheight=2
set signcolumn=yes

" プラグインの読み込み
call plug#begin('~/.vim/plugged')

" 0XX: Vim本体の拡張
Plug 'mhinz/vim-startify'
Plug 'vim-jp/vimdoc-ja'

Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'ryanoasis/vim-devicons'

" 1XX: Vimのstyleの拡張
Plug 'cocopon/iceberg.vim'
Plug 'Yggdroot/indentLine'
Plug 'bronson/vim-trailing-whitespace'

" 2XX: グローバルなプラグイン
"   lspやコマンドの拡張など
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

Plug 'qpkorr/vim-bufkill'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'simeji/winresizer'

" 3XX: ファイルタイプごとのプラグイン
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'cohama/lexima.vim'

Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
Plug 'tpope/vim-rails', { 'for': 'ruby' }
Plug 'tpope/vim-rbenv', { 'for': 'ruby' }
Plug 'tpope/vim-endwise', { 'for': 'ruby' }

Plug 'mattn/vim-goimports', { 'for': 'go' }

" 4XX: アプリケーション拡張
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'rhysd/git-messenger.vim'

Plug 'tyru/open-browser.vim', { 'for': ['markdown', 'plantuml'] }
Plug 'previm/previm', { 'for': 'markdown' }
Plug 'junegunn/goyo.vim', { 'for': 'markdown' }
Plug 'weirongxu/plantuml-previewer.vim', { 'for': 'plantuml' }
Plug 'glidenote/memolist.vim'

call plug#end()

" 各種設定の読み込み
call map(sort(split(globpath(&runtimepath, 'rc/*.vim'))), {->[execute('exec "so" v:val')]})
