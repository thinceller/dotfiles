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

"色
set background=dark
"カラーテーマを入れる場合は以下を有効化する
let g:hybrid_use_iTerm_colors = 1
set termguicolors
colorscheme hybrid

"行番号の色や現在行の設定
autocmd ColorScheme * highlight LineNr ctermfg=12
highlight CursorLineNr ctermbg=4 ctermfg=0
set cursorline
highlight clear CursorLine

"シンタックスハイライト
syntax enable

"オートインデント
set autoindent

"インデント幅
set shiftwidth=4
set softtabstop=4
set tabstop=4

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
"インクリメンタルサーチしない
set noincsearch
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


"不可視文字の設定
set list
set listchars=tab:>-,eol:↲,extends:»,precedes:«,nbsp:%

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



""""""""""""""""""""""""""""""



"カーソル移動
"nnoremap j gj
"nnoremap k gk
"nnoremap gj j
"nnoremap gk k
"nnoremap <down> gj
"nnoremap <up> gk
"noremap <S-h> ^
"noremap <S-j> }
"noremap <S-k> {
"noremap <S-l> $

";;でノーマルモード
"inoremap ;; <esc>

"ノーマルモードのまま改行
"nnoremap <CR> A<CR><ESC>
"ノーマルモードのままスペース
"nnoremap <space> i<space><esc>

"rだけでリドゥ
"nnoremap r <C-r>

"Yで行末までヤンク
"nnoremap Y y$

"ESCキー2度押しでハイライトの切り替え
"nnoremap <silent><Esc><Esc> :<C-u>set nohlsearch!<CR>


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


filetype plugin indent on

