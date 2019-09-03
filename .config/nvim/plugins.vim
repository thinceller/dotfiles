call plug#begin('~/.config/nvim/plugged')

" Plug 'vim-jp/vimdoc-ja'
Plug 'mhinz/vim-startify'

Plug 'scrooloose/nerdtree'
Plug 'vwxyutarooo/nerdtree-devicons-syntax'

Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-ragtag'
Plug 'cohama/lexima.vim'
Plug 'tpope/vim-endwise'

Plug 'tpope/vim-commentary'
" Plug 'tpope/vim-surround'
Plug 'machakann/vim-sandwich'
Plug 'simeji/winresizer'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'qpkorr/vim-bufkill'

Plug 'zxqfl/tabnine-vim', { 'branch': 'master', 'for': ['ruby', 'go'] }
Plug 'neoclide/coc.nvim', {'do': 'yarn install --frozen-lockfile'}
Plug 'szw/vim-tags'

Plug 'bronson/vim-trailing-whitespace'
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'othree/es.next.syntax.vim', { 'for': ['javascript', 'javascript.jsx', 'typescript', 'typescript.jsx'] }
Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
Plug 'tpope/vim-rails', { 'for': 'ruby' }
Plug 'tpope/vim-rbenv', { 'for': 'ruby' }
Plug 'tpope/vim-bundler', { 'for': 'ruby' }
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries', 'for': 'go' }

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

Plug 'haishanh/night-owl.vim'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'

call plug#end()

" ==================================================================
"   night-owl.vim
" ==================================================================
" night-owl pluginを読み込んでからcolorschemeの設定を行う
colorscheme night-owl

" ==================================================================
"   vim-airline
"   参考: https://original-game.com/vim-airline/
" ==================================================================
set ttimeoutlen=50

nmap <C-p> <Plug>AirlineSelectPrevTab
nmap <C-n> <Plug>AirlineSelectNextTab

let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1

let g:airline_theme = 'dark'

let g:airline#extensions#coc#enabled = 1
let airline#extensions#coc#error_symbol = ' '
let airline#extensions#coc#warning_symbol = ' '
let airline#extensions#coc#stl_format_err = '%E{[%e(#%fe)]}'
let airline#extensions#coc#stl_format_warn = '%W{[%w(#%fw)]}'

" ==================================================================
"   nerdtree
" ==================================================================
nnoremap <leader>e :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" ==================================================================
"   vim-startify
"   参考: http://mjhd.hatenablog.com/entry/recommendation-of-vim-startify
" ==================================================================
let g:startify_files_number = 5
let g:startify_bookmarks = [
  \ '~/.config/nvim/basic.vim',
  \ '~/.config/nvim/plugins.vim'
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

" ==================================================================
"   vim-indent-guides
" ==================================================================
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2
let g:indent_guides_exclude_filetypes = ['help', 'nerdtree', 'startify', 'terminal', 'fzf']

nnoremap <space>in :IndentGuidesToggle<CR>

" ==================================================================
"   vim-polyglot
" ==================================================================
let g:polyglot_disabled = ['css']

" ==================================================================
"   vim-bufkill
" ==================================================================
let g:BufKillCreateMappings = 0

" ==================================================================
"   vim-gitgutter
" ==================================================================
let g:gitgutter_map_keys = 0

" ==================================================================
"   coc.nvim
" ==================================================================
set cmdheight=2
set updatetime=300
set signcolumn=yes

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

inoremap <silent><expr> <c-space> coc#refresh()
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

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

autocmd CursorHold * silent call CocActionAsync('highlight')

nmap <leader>rn <Plug>(coc-rename)

" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" ==================================================================
"   fzf.vim
" ==================================================================
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

