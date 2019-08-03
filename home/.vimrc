" ---------------------------------
"  Vim Plugin
" ---------------------------------
call plug#begin('~/vim/plugged')

" ファイルオープン
Plug 'Shougo/unite.vim'

" 非同期処理
Plug 'Shougo/vimproc.vim', { 'do': 'make' }

" unite.vim 強化
Plug 'Shougo/neomru.vim'

" NERDTree
Plug 'scrooloose/nerdtree'

" コメントアウト
Plug 'tpope/vim-commentary'

" 括弧のオートクローズ
Plug 'tpope/vim-ragtag'
Plug 'cohama/lexima.vim'

" end系のオートクローズ
Plug 'tpope/vim-endwise'

" タグ作成
Plug 'szw/vim-tags'

" vim-fugitive (git コマンド利用)
Plug 'tpope/vim-fugitive'

" git log view (tig相当 fugitive依存)
Plug 'gregsexton/gitv'

" インデント見やすく
Plug 'nathanaelkane/vim-indent-guides'

" ag (silver seacher による grep)
Plug 'rking/ag.vim'

" 検索
Plug 'dyng/ctrlsf.vim'

" 行末の半角スペースを可視化
Plug 'bronson/vim-trailing-whitespace'

" editorconfig プラグイン
Plug 'editorconfig/editorconfig-vim'

" surround.vim カッコや引用符で囲ったり削除したり
Plug 'tpope/vim-surround'

" 自動補完 deoplete
if has('nvim')
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plug 'Shougo/deoplete.nvim'
  Plug 'roxma/nvim-yarp'
  Plug 'roxma/vim-hug-neovim-rpc'
endif
" snippet
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'

" javascript plugin
Plug 'pangloss/vim-javascript'
Plug 'maxmellon/vim-jsx-pretty'

Plug 'leafgarland/typescript-vim'

Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'ryanolsonx/vim-lsp-typescript'

" golang plugin
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" resize window
Plug 'simeji/winresizer'

" lint
Plug 'w0rp/ale'

" Git Plugin
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

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
"  基本設定
" ---------------------------------
"エンコーディング
set encoding=utf-8
scriptencoding utf-8

"vi互換をオフ
set nocompatible

"カーソル位置表示
set ruler
"行番号表示
set number
" タイトル表示
set title
"ステータス業を常に表示
set laststatus=2

"色
set background=dark
syntax enable
colorscheme night-owl
let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors

"行番号の色や現在行の設定
autocmd ColorScheme * highlight LineNr ctermfg=12
highlight CursorLineNr ctermbg=4 ctermfg=0
set cursorline
hi clear CursorLine

"オートインデント
set autoindent

"インデント幅
set shiftwidth=2
set softtabstop=2
set tabstop=2

"タブをスペースに変換
set expandtab
set smarttab

"ピープ音をすべて無効にする
set visualbell t_vb=

"長い行の折り返し表示
set wrap

"想定される改行コードの指定をする
"set fileformats=unix,doc,mac

"検索設定
"インクリメンタルサーチ
set incsearch
"ハイライト
set hlsearch
" Esc2回押しで検索ハイライト消去
nnoremap <Esc><Esc> :nohlsearch<CR><CR>
"大文字と小文字を区別しない
set ignorecase
"大文字と小文字が混在した検索のみ大文字と小文字を区別する
set smartcase
"最後尾になったら先頭に戻る
set wrapscan
"置換の時gオプションをデフォルトで有効にする
set gdefault

" ウィンドウ分割時に右に展開
set splitright
"set splitbelow


"不可視文字の設定
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%

"コマンドラインモードのファイル補完設定
set wildmode=list:longest,full

"入力中のコマンドを表示
set showcmd

"クリップボードの共有
set clipboard=unnamed,autoselect

"カーソル移動で行をまたげるようにする
set whichwrap=b,s,h,l,<,>,~,[,]

"バックスペースを使いやすく
set backspace=indent,eol,start
set nrformats-=octal

set pumheight=10

"対応する括弧に一瞬移動
set showmatch
set matchtime=1
source $VIMRUNTIME/macros/matchit.vim " Vimの「%」を拡張する

"ウィンドウの最後の行もできるだけ表示
set display=lastline

"変更中のファイルでも保存しないで他のファイルを表示する
set hidden

"バックアップファイルを作成しない
set nobackup
"バックアップファイルのディレクトリ指定
set backupdir=$HOME/.vim/backup
"アンドゥファイルを作成しない
set noundofile
"アンドゥファイルのディレクトリ指定
set undodir=$HOME/.vim/backup
"スワップファイルを作成しない
set noswapfile

" filetypeによるプラグインon
filetype plugin indent on

""""""""""""""""""""""""""""""
" キーマッピング
""""""""""""""""""""""""""""""
"jjでノーマルモード
inoremap <silent> jj <ESC>

";;でノーマルモード
inoremap ;; <esc>

"; でコマンド
nnoremap ; :

"ノーマルモードのまま改行
"nnoremap <CR> A<CR><ESC>
"ノーマルモードのままスペース
"nnoremap <space> i<space><esc>

"rだけでリドゥ
"nnoremap r <C-r>

"Yで行末までヤンク
nnoremap Y y$

"tagsジャンプの時に複数ある時は一覧表示
nnoremap <C-]> g<C-]>

"垂直ジャンプ
nnoremap <C-h> :vsp<CR> :exe("tjump ".expand('<cword>'))<CR>
nnoremap <C-k> :split<CR> :exe("tjump ".expand('<cword>'))<CR>

"ESCキー2度押しでハイライトの切り替え
nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>

augroup MyXML
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END


"ペースト時に自動インデントで崩れるのを防ぐ
if &term =~ "xterm"
  let &t_SI .= "\e[?2004h"
  let &t_EI .= "\e[?2004l"
  let &pastetoggle = "\e[201~"

  function XTermPasteBegin(ret)
    set paste
    return a:ret
  endfunction

  inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
endif

" 画面分割
" 参考: https://qiita.com/tekkoc/items/98adcadfa4bdc8b5a6ca#s%E3%82%AD%E3%83%BC%E3%81%AE%E5%85%83%E3%80%85%E3%81%AE%E6%A9%9F%E8%83%BD%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6
nnoremap s <Nop>
nnoremap sj <C-w>j
nnoremap sk <C-w>k
nnoremap sl <C-w>l
nnoremap sh <C-w>h
nnoremap sJ <C-w>J
nnoremap sK <C-w>K
nnoremap sL <C-w>L
nnoremap sH <C-w>H
nnoremap sn gt
nnoremap sp gT
nnoremap sr <C-w>r
nnoremap s= <C-w>=
nnoremap sw <C-w>w
nnoremap so <C-w>_<C-w>|
nnoremap sO <C-w>=
nnoremap sN :<C-u>bn<CR>
nnoremap sP :<C-u>bp<CR>
" 新規タブ作成
nnoremap st :<C-u>tabnew<CR>
" タブ一覧
nnoremap sT :<C-u>Unite tab<CR>
" ウィンドウ分割
nnoremap ss :<C-u>sp<CR>
nnoremap sv :<C-u>vs<CR>
" ウィンドウを閉じる
nnoremap sq :<C-u>q<CR>
nnoremap sQ :<C-u>bd<CR>
" カレントタブのバッファ一覧
nnoremap sb :<C-u>Unite buffer_tab -buffer-name=file<CR>
" バッファ一覧
nnoremap sB :<C-u>Unite buffer -buffer-name=file<CR>

" ---------------------------------
" Plugin indent plugin
" ---------------------------------
"let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_auto_colors=0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd   ctermbg=241
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven  ctermbg=233
let g:indent_guides_start_level=2
let g:indent_guides_guide_size=1

" ---------------------------------
" Plugin airline
" 参考: https://original-game.com/vim-airline/
" ---------------------------------
let g:airline#extensions#tabline#enabled = 1

nmap <C-p> <Plug>AirlineSelectPrevTab
nmap <C-n> <Plug>AirlineSelectNextTab

set ttimeoutlen=50

let g:airline_theme = 'dark'
let g:airline#extensions#ale#error_symbol = ' '
let g:airline#extensions#ale#warning_symbol = ' '
let g:airline_section_z = '%3l:%2v %{airline#extensions#ale#get_warning()} %{airline#extensions#ale#get_error()}'

" ---------------------------------
" Plugin indent plugin
" ---------------------------------
let g:vim_tags_project_tags_command ='ctags -R  --fields=+aimS {OPTIONS} {DIRECTORY} 2>/dev/null &'
let g:vim_tags_auto_generate = 0

" ---------------------------------
" Plugin NERDTree
" ---------------------------------
" autocmd vimenter * NERDTree
nnoremap <C-e> :NERDTreeToggle<CR>

" ---------------------------------
" Plugin deoplete
" https://muunyblue.github.io/520bae6649b42ff5a3c8c58b7fcfc5a9.html
" ---------------------------------
" deoplete.vim
let g:deoplete#enable_at_startup = 1
" <TAB>: completion.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ deoplete#manual_complete()
function! s:check_back_space() abort "{{{
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction"}}}

" <S-TAB>: completion back.
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<C-h>"

" <BS>: close popup and delete backword char.
inoremap <expr><BS> deoplete#smart_close_popup()."\<C-h>"

" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function() abort
  return deoplete#cancel_popup() . "\<CR>"
endfunction

" neosnippet.vim
imap <C-k> <Plug>(neosnippet_expand_or_jump)
smap <C-k> <Plug>(neosnippet_expand_or_jump)
xmap <C-k> <Plug>(neosnippet_expand_target)
let g:neosnippet#enable_snipmate_compatibility = 1
let g:neosnippet#enable_completed_snippet = 1
let g:neosnippet#expand_word_boundary = 1

" ---------------------------------
"  Unite Setting
" 参考:  https://www.karakaram.com/unite
" ---------------------------------

"unite prefix key.
nnoremap [unite] <Nop>
nmap <C-u> [unite]

"unite general settings
"インサートモードで開始
" let g:unite_enable_start_insert = 1
"最近開いたファイル履歴の保存数
let g:unite_source_file_mru_limit = 50

"Unite grep
let g:unite_source_grep_command = 'ag'
let g:unite_source_grep_default_opts = '--nocolor --nogroup --ignore=''*.tags'' --ignore=''tags'' --ignore=''.svn'' --ignore=''.git'''
let g:unite_source_grep_recursive_opt = ''
let g:unite_source_grep_max_candidates = 200

"file_mruの表示フォーマットを指定。空にすると表示スピードが高速化される
let g:unite_source_file_mru_filename_format = ''

"現在開いているファイルのディレクトリ下のファイル一覧。
"開いていない場合はカレントディレクトリ
nnoremap <silent> [unite]<C-f> :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
"バッファ一覧
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
"レジスタ一覧
nnoremap <silent> [unite]r :<C-u>Unite -buffer-name=register register<CR>
"最近使用したファイル一覧
nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>
"ブックマーク一覧
nnoremap <silent> [unite]c :<C-u>Unite bookmark<CR>
"ブックマークに追加
nnoremap <silent> [unite]a :<C-u>UniteBookmarkAdd<CR>
"grep
nnoremap <silent> [unite]g :<C-u>Unite grep -no-quit<CR>
nnoremap <silent> <C-g> :<C-u>UniteWithCursorWord grep:./<CR>

"uniteを開いている間のキーマッピング
autocmd FileType unite call s:unite_my_settings()
function! s:unite_my_settings()"{{{
"ESCでuniteを終了
nmap <buffer> <ESC> <Plug>(unite_exit)
"入力モードのときjjでノーマルモードに移動
imap <buffer> jj <Plug>(unite_insert_leave)
"入力モードのときctrl+wでバックスラッシュも削除
  imap <buffer> <C-w> <Plug>(unite_delete_backward_path)
  "ctrl+jで縦に分割して開く
  nnoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
  inoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
  "ctrl+lで横に分割して開く
  nnoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
  inoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
  "ctrl+oでその場所に開く
  nnoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')
  inoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')
endfunction"}}}

" 現在のプロジェクト内のファイルを一望する
" 参考 : http://d.hatena.ne.jp/h1mesuke/20110918/p1
noremap <silent> [unite]<C-p> :<C-u>call <SID>unite_project('-start-insert')<CR>

function! s:unite_project(...)
  let opts = (a:0 ? join(a:000, ' ') : '')
  let dir = unite#util#path2project_directory(expand('%'))
  execute 'Unite' opts 'file_rec:' . dir
endfunction

" ---------------------------------
" Plugin vim-lsp-typescript
" ---------------------------------
if executable('typescript-language-server')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'typescript-language-server',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
        \ 'whitelist': ['typescript', 'typescript.tsx'],
        \ })
endif
