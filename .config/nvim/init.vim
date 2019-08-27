" ---------------------------------
"  Vim Plugin
" ---------------------------------
call plug#begin('~/.vim/plugged')

Plug 'vim-jp/vimdoc-ja'
Plug 'mhinz/vim-startify'
" NERDTree
Plug 'scrooloose/nerdtree'
Plug 'vwxyutarooo/nerdtree-devicons-syntax'
" comment out
Plug 'tpope/vim-commentary'
" auto close
Plug 'tpope/vim-ragtag'
Plug 'cohama/lexima.vim'
Plug 'tpope/vim-endwise'
" visualize trailing space
Plug 'bronson/vim-trailing-whitespace'
" editorconfig
Plug 'editorconfig/editorconfig-vim'
" surround.vim
Plug 'tpope/vim-surround'
" resize window
Plug 'simeji/winresizer'
" indent guide
Plug 'nathanaelkane/vim-indent-guides'
" delete buffer and keep window/split
Plug 'qpkorr/vim-bufkill'
" language pack
Plug 'sheerun/vim-polyglot'

" ----- 補完 -----
" Tabnine
Plug 'zxqfl/tabnine-vim', { 'branch': 'master' }
" coc.nvim
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
" ctags
Plug 'szw/vim-tags'

" languages plugin
" javascript plugin
" Plug 'pangloss/vim-javascript'
" Plug 'mxw/vim-jsx'
Plug 'othree/es.next.syntax.vim'
" typescript plugin
" Plug 'leafgarland/typescript-vim'
" Plug 'styled-components/vim-styled-components', { 'branch': 'develop' }
" Plug 'othree/javascript-libraries-syntax.vim'
" ruby plugin
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rbenv'
Plug 'tpope/vim-bundler'
" golang plugin
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" markdown
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'

" lint
" Plug 'w0rp/ale'

" Git Plugin
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
" Plug 'gregsexton/gitv'

" fzf
Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

" colorscheme
Plug 'haishanh/night-owl.vim'

"-------------------
" airline
"-------------------
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'

call plug#end()

" ---------------------------------
"  Basic settings
" ---------------------------------
let g:python_host_prog = $PYENV_ROOT.'/versions/neovim2/bin/python'
let g:python3_host_prog = $PYENV_ROOT.'/versions/neovim3/bin/python'

" endoding
set encoding=utf-8
scriptencoding utf-8
set helplang=ja,en
" off vi
set nocompatible
" show cursor
set ruler
" line number
set number
" show title
set title
" show status
set laststatus=2
set mouse=a

" color
set background=dark
syntax enable
if (has("termguicolors"))
   set termguicolors
endif
colorscheme night-owl
let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"

autocmd ColorScheme * highlight LineNr ctermfg=12
highlight CursorLineNr ctermbg=4 ctermfg=0
set cursorline
" hi clear CursorLine
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

" autoindent
" set autoindent
set smartindent
" indent space
set shiftwidth=2
set softtabstop=2
set tabstop=2
" tab to space
set expandtab
set smarttab

set wildmenu

" invalidate bell
set visualbell t_vb=

" line wrap
set wrap
" move through line wrap
set whichwrap=b,s,h,l,<,>,~,[,]
" show last line
set display=lastline

" file formats
"set fileformats=unix,doc,mac

" search
set incsearch
set hlsearch
nnoremap <Esc><Esc> :nohlsearch<CR><CR>
set ignorecase
set smartcase
set wrapscan
set gdefault

" default split
" set splitright
set splitbelow

" list characters
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

" complement in command mode
set wildmode=list:longest,full

" show typing commands
set showcmd

" share clipboard
set clipboard=unnamed

" set backspace to move
set backspace=indent,eol,start
set nrformats-=octal

" complement size
set pumheight=10

" brackets
set showmatch
set matchtime=1
source $VIMRUNTIME/macros/matchit.vim " Vimの「%」を拡張する

" no save when change buffer
set hidden

" rendering performance
set ttyfast
set lazyredraw

" backup
set nobackup
set nowritebackup
set backupdir=$HOME/.vim/backup
set noundofile
set undodir=$HOME/.vim/backup
set noswapfile

" for coc.nvim settings
set cmdheight=2
set updatetime=300
set signcolumn=yes

" filetype plugin
" filetype plugin indent on


" ---------------------------------
" Key mappings
" ---------------------------------
"jjでノーマルモード
inoremap <silent> jj <ESC>
"; でコマンド
nnoremap ; :

"Yで行末までヤンク
nnoremap Y y$

let mapleader = "\<Space>"

" terminal
" terminal modeでESC
if has('nvim')
  nnoremap <leader>t :sp<CR>:term<CR>
else
  nnoremap <leader>t :bo term<CR>
endif

if has('nvim')
  au TermOpen * tnoremap <Esc> <c-\><c-n>
  au FileType fzf tunmap <Esc>
endif

"tagsジャンプの時に複数ある時は一覧表示
"nnoremap <C-]> g<C-]>
"垂直ジャンプ
"nnoremap <C-h> :vsp<CR> :exe("tjump ".expand('<cword>'))<CR>
"nnoremap <C-k> :split<CR> :exe("tjump ".expand('<cword>'))<CR>

"ESCキー2度押しでハイライトの切り替え
nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>

augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END


"ペースト時に自動インデントで崩れるのを防ぐ
" if &term =~ "xterm"
"   let &t_SI .= "\e[?2004h"
"   let &t_EI .= "\e[?2004l"
"   let &pastetoggle = "\e[201~"

"   function XTermPasteBegin(ret)
"     set paste
"     return a:ret
"   endfunction

"   inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
" endif

" ---------------------------------
" Plugin airline
" 参考: https://original-game.com/vim-airline/
" ---------------------------------
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
" let g:airline#extensions#ale#error_symbol = ' '
" let g:airline#extensions#ale#warning_symbol = ' '

nmap <C-p> <Plug>AirlineSelectPrevTab
nmap <C-n> <Plug>AirlineSelectNextTab

set ttimeoutlen=50

let g:airline_theme = 'dark'

let g:airline#extensions#coc#enabled = 1
let airline#extensions#coc#error_symbol = ' '
let airline#extensions#coc#warning_symbol = ' '
let airline#extensions#coc#stl_format_err = '%E{[%e(#%fe)]}'
let airline#extensions#coc#stl_format_warn = '%W{[%w(#%fw)]}'

let g:airline_section_z = '%3l:%2v %{airline#extensions#coc#get_warning()} %{airline#extensions#coc#get_error()}'

" ---------------------------------
" NERDTree
" ---------------------------------
" autocmd vimenter * NERDTree
nnoremap <leader>e :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" ---------------------------------
" vim-startify
" 参考: http://mjhd.hatenablog.com/entry/recommendation-of-vim-startify
" ---------------------------------
let g:startify_files_number = 5
let g:startify_lists = [
  \ { 'type': 'files', 'header': ['♻  最近使ったファイル'] },
  \ { 'type': 'dir', 'header': ['♲  最近使ったファイル（カレントディレクトリ）'] },
  \ { 'type': 'sessions', 'header': ['⚑  セッション'] },
  \ { 'type': 'bookmarks', 'header': ['📕  ブックマーク'] }
  \ ]
let g:startify_bookmarks = ['~/.vimrc']

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

" ---------------------------------
" indent guide
" ---------------------------------
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2
let g:indent_guides_exclude_filetypes = ['help', 'nerdtree', 'startify', 'terminal', 'fzf']

nnoremap <space>in :IndentGuidesToggle<CR>


" ---------------------------------
" polyglot
" ---------------------------------

let g:polyglot_disabled = ['css']

" ---------------------------------
" Git
" ---------------------------------
if has('nvim')
  nnoremap tig :tab :term tig<CR>
else
  nnoremap tig :tab :term ++close tig<CR>
endif

" ---------------------------------
" coc.nvim
" ---------------------------------
" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Highlight symbol under cursor on CursorHold
autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
" xmap <leader>f  <Plug>(coc-format-selected)
" nmap <leader>f  <Plug>(coc-format-selected)

" augroup mygroup
"   autocmd!
"   " Setup formatexpr specified filetype(s).
"   autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
"   " Update signature help on jump placeholder
"   autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
" augroup end

" Use <tab> for select selections ranges, needs server support, like: coc-tsserver, coc-python
" nmap <silent> <TAB> <Plug>(coc-range-select)
" xmap <silent> <TAB> <Plug>(coc-range-select)
" xmap <silent> <S-TAB> <Plug>(coc-range-select-backword)

" Use `:Format` to format current buffer
command! -nargs=0 Format :call CocAction('format')
" Use `:Fold` to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" Add status line support, for integration with other plugin, checkout `:h coc-status`
" set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" ---------------------------------
"  fzf.vim
" ---------------------------------
function! FzfWordRg()
  :Rg ' .expand('<cword>')'<CR>
endfunction

" preview
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=? -complete=dir GitFiles
  \ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

nnoremap <C-g> :Rg<Space>
nnoremap <leader>g :exec 'Rg' expand('<cword>')<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>p :GFiles<CR>
nnoremap <leader>F :GFiles?<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>l :BLines<CR>
nnoremap <leader>h :History<CR>

