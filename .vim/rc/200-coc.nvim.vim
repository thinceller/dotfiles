if empty(globpath(&rtp, 'plugged/coc.nvim'))
  finish
endif

let g:coc_global_extensions = [
\ 'coc-css',
\ 'coc-docker',
\ 'coc-emoji',
\ 'coc-eslint',
\ 'coc-go',
\ 'coc-html',
\ 'coc-json',
\ 'coc-marketplace',
\ 'coc-python',
\ 'coc-sh',
\ 'coc-snippets',
\ 'coc-solargraph',
\ 'coc-stylelint',
\ 'coc-tsserver',
\ 'coc-yaml',
\ 'coc-explorer',
\ 'coc-prettier'
\ ]

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
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nnoremap <silent> K :call <SID>show_documentation()<CR>

nmap <C-q> <Plug>(coc-fix-current)
" vmap <leader>a <Plug>(coc-codeaction-selected)
" nmap <leader>a <Plug>(coc-codeaction-selected)

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

autocmd CursorHold * silent call CocActionAsync('highlight')

" autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
autocmd FileType go nnoremap <leader>gtj :CocCommand go.tags.add json<CR>
autocmd FileType go nnoremap <leader>gty :CocCommand go.tags.add yaml<CR>
autocmd FileType go nnoremap <leader>gtd :CocCommand go.tags.add db<CR>
autocmd FileType go nnoremap <leader>gtx :CocCommand go.tags.clear<CR>

" coc-explorer
nnoremap <leader>e :CocCommand explorer<CR>

" coc-fzf-preview
let g:fzf_preview_command = 'bat --color=always --plain {-1}'
let g:fzf_preview_use_dev_icons = 1

nmap <Leader>f [fzf-p]
xmap <Leader>f [fzf-p]

nnoremap <silent> [fzf-p]f     :CocCommand fzf-preview.GitFiles<CR>
nnoremap <silent> [fzf-p]p     :<C-u>CocCommand fzf-preview.FromResources project_mru git<CR>
nnoremap <silent> [fzf-p]gs    :<C-u>CocCommand fzf-preview.GitStatus<CR>
nnoremap <silent> [fzf-p]ga    :<C-u>CocCommand fzf-preview.GitActions<CR>
nnoremap <silent> [fzf-p]b     :<C-u>CocCommand fzf-preview.Buffers<CR>
nnoremap <silent> [fzf-p]B     :<C-u>CocCommand fzf-preview.AllBuffers<CR>
nnoremap <silent> [fzf-p]o     :<C-u>CocCommand fzf-preview.FromResources buffer project_mru<CR>
nnoremap <silent> [fzf-p]<C-o> :<C-u>CocCommand fzf-preview.Jumps<CR>
nnoremap <silent> [fzf-p]g;    :<C-u>CocCommand fzf-preview.Changes<CR>
nnoremap <silent> [fzf-p]/     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'"<CR>
nnoremap <silent> [fzf-p]*     :<C-u>CocCommand fzf-preview.Lines --add-fzf-arg=--no-sort --add-fzf-arg=--query="'<C-r>=expand('<cword>')<CR>"<CR>
nnoremap          [fzf-p]gr    :<C-u>CocCommand fzf-preview.ProjectGrep<Space>
xnoremap          [fzf-p]gr    "sy:CocCommand   fzf-preview.ProjectGrep<Space>-F<Space>"<C-r>=substitute(substitute(@s, '\n', '', 'g'), '/', '\\/', 'g')<CR>"
nnoremap <silent> [fzf-p]q     :<C-u>CocCommand fzf-preview.QuickFix<CR>
nnoremap <silent> [fzf-p]l     :<C-u>CocCommand fzf-preview.LocationList<CR>
