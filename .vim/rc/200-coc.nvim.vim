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
\ 'coc-tslint-plugin',
\ 'coc-tsserver',
\ 'coc-yaml'
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
command! -nargs=0 Format :call CocAction('format')
command! -nargs=? Fold :call     CocAction('fold', <f-args>)
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

" autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
autocmd FileType go nnoremap <leader>gtj :CocCommand go.tags.add json<CR>
autocmd FileType go nnoremap <leader>gty :CocCommand go.tags.add yaml<CR>
autocmd FileType go nnoremap <leader>gtd :CocCommand go.tags.add db<CR>
autocmd FileType go nnoremap <leader>gtx :CocCommand go.tags.clear<CR>
