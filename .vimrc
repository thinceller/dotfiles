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
set wildmode=full
set showcmd
set showtabline=2
set clipboard=unnamed
set backspace=indent,eol,start
set nrformats=
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
set signcolumn=yes

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
nnoremap + <C-a>
nnoremap - <C-x>
nnoremap <silent><Esc><Esc> <Cmd>set nohlsearch!<CR>

let mapleader = "\<Space>"

"================================================
" plugins
"================================================
call plug#begin()

Plug 'vim-jp/vimdoc-ja'
Plug 'mhinz/vim-startify'
Plug 'haishanh/night-owl.vim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'bronson/vim-trailing-whitespace'
Plug 'qpkorr/vim-bufkill'
Plug 'machakann/vim-sandwich'
Plug 'simeji/winresizer'
Plug 'tyru/columnskip.vim'
Plug 'tpope/vim-commentary'
Plug 'cohama/lexima.vim'
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
Plug 'lambdalisue/fern-git-status.vim'
Plug 'lambdalisue/glyph-palette.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'vim-denops/denops.vim'
Plug 'lambdalisue/gin.vim'

call plug#end()

"================================================
" colors
"================================================
colorscheme night-owl

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

lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = {
    enable = true,
    disable = {
      'lua',
      'ruby',
      'toml',
      'c_sharp',
      'vue',
    }
  }
}
EOF

"================================================
" vim-startify
"================================================
"" ref: http://mjhd.hatenablog.com/entry/recommendation-of-vim-startify
let g:startify_files_number = 5
let g:startify_bookmarks = [
  \ '~/.vimrc',
  \ '~/.zshenv',
  \ '~/.zshrc',
  \ '~/.tmux.conf'
  \ ]

function! s:center(lines) abort
  let longest_line   = max(map(copy(a:lines), 'strwidth(v:val)'))
  let centered_lines = map(copy(a:lines),
        \ 'repeat(" ", (&columns / 2) - (longest_line / 2)) . v:val')
  return centered_lines
endfunction

let g:startify_custom_header = s:center([
  \'   __  __    _                 ____',
  \'  / /_/ /_  (_)___  ________  / / /__  _____',
  \' / __/ __ \/ / __ \/ ___/ _ \/ / / _ \/ ___/',
  \'/ /_/ / / / / / / / /__/  __/ / /  __/ /',
  \'\__/_/ /_/_/_/ /_/\___/\___/_/_/\___/_/',
  \'',
  \'             _    ___',
  \'            | |  / (_)___ ___',
  \'            | | / / / __ `__ \',
  \'            | |/ / / / / / / /',
  \'            |___/_/_/ /_/ /_/',
  \'',
  \])

"================================================
" lightline.vim
"================================================
set noshowmode

let g:lightline = {
  \ 'colorscheme': 'nightowl',
  \ 'tabline': { 'left': [ [ 'buffers' ] ], 'right': [ [ 'tabs' ] ]},
  \ 'component_expand': {
  \   'buffers': 'lightline#bufferline#buffers',
  \ },
  \ 'component_type': {
  \   'buffers': 'tabsel',
  \ },
  \ }

let g:lightline#bufferline#show_number = 1

"================================================
" fern.vim
"================================================
nnoremap <Leader>ee <Cmd>Fern . -drawer -reveal=% -toggle<CR>

let g:fern#default_hidden = 1
" let g:fern#default_exclude = '.git/'
let g:fern#renderer = "nerdfont"

augroup my-glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
  autocmd FileType nerdtree,startify call glyph_palette#apply()
augroup END

"================================================
" vim-trailing-whitespace
"================================================
let g:extra_whitespace_ignored_filetypes = ['startify', 'TelescopePrompt']

"================================================
" vim-bufkill
"================================================
nnoremap <Leader>q <Cmd>BW<CR>

"================================================
" columnskip.vim
"================================================
nmap tj <Plug>(columnskip:nonblank:next)
omap tj <Plug>(columnskip:nonblank:next)
xmap tj <Plug>(columnskip:nonblank:next)
nmap tk <Plug>(columnskip:nonblank:prev)
omap tk <Plug>(columnskip:nonblank:prev)
xmap tk <Plug>(columnskip:nonblank:prev)

"================================================
" telescope.nvim
"================================================
nnoremap <Leader>ff <Cmd>Telescope find_files<Cr>
nnoremap <Leader>fg <Cmd>Telescope live_grep<Cr>
nnoremap <Leader>fb <Cmd>Telescope buffers<Cr>
nnoremap <Leader>f/ <Cmd>Telescope current_buffer_fuzzy_find<Cr>
nnoremap <Leader>gs <Cmd>Telescope git_status<Cr>

"================================================
" vim-lsp
"================================================
nmap <silent> gd <Cmd>LspDefinition<CR>
nmap <silent> gt <Cmd>LspTypeDefinition<CR>
nmap <silent> gr <Cmd>LspReferences<CR>
nmap <silent> gi <Cmd>LspImplementation<CR>
nmap <Leader>ca <Cmd>LspCodeAction<CR>
nnoremap <silent> K <Cmd>LspHover<CR>
nnoremap [c <Cmd>LspPreviousDiagnostic<CR>
nnoremap ]c <Cmd>LspNextDiagnostic<CR>

hi LspError guifg=#dc6f79 ctermfg=167
hi LspErrorText guifg=#dc6f79 ctermfg=167 gui=bold cterm=bold
hi LspErrorHighlight gui=underline cterm=underline
hi LspErrorVirtualText guifg=#dc6f79 ctermfg=167 gui=bold cterm=bold
hi LspWarning guifg=#ac8b83 ctermfg=138
hi LspWarningText guifg=#ac8b83 ctermfg=138 gui=bold cterm=bold
hi LspWarningHighlight gui=underline cterm=underline
hi LspWarningVirtualText guifg=#ac8b83 ctermfg=138 gui=bold cterm=bold
hi LspInformation guifg=#82dabf ctermfg=115
hi LspInformationText guifg=#82dabf ctermfg=115 gui=bold cterm=bold
hi LspInformationHighlight gui=underline cterm=underline
hi LspInformationVirtualText guifg=#545c8c ctermfg=60 gui=bold cterm=bold
hi LspHint guifg=#82dabf ctermfg=115
hi LspHintText guifg=#82dabf ctermfg=115 gui=bold cterm=bold
hi LspHintHighlight gui=underline cterm=underline
hi LspHintVirtualText guifg=#545c8c ctermfg=60 gui=bold cterm=bold

"================================================
" gin.vim
"================================================
nnoremap <Leader>gd <Cmd>GinDiff<CR>
nnoremap [g <Plug>(gin-diffjump-old)
nnoremap ]g <Plug>(gin-diffjump-new)
