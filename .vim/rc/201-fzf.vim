if empty(globpath(&rtp, 'plugged/fzf.vim'))
  finish
endif

" preview
" https://qiita.com/kompiro/items/a09c0b44e7c741724c80#%E3%83%97%E3%83%AC%E3%83%93%E3%83%A5%E3%83%BC%E3%82%A6%E3%82%A3%E3%83%B3%E3%83%89%E3%82%A6%E3%81%AE%E8%B5%B7%E5%8B%95%E6%96%B9%E6%B3%95
" command! -bang -nargs=? -complete=dir Files
"   \ call fzf#vim#files(
"   \   <q-args>,
"   \   {'options': ['--layout=reverse', '--preview', 'bat --color=always --style=header,grid --line-range :100 {}']},
"   \   <bang>0)

" command! -bang -nargs=? -complete=dir GitFiles
"   \ call fzf#vim#gitfiles(
"   \   <q-args>,
"   \   {'options': ['--layout=reverse', '--preview', 'bat --color=always --style=header,grid --line-range :100 {}']},
"   \   <bang>0)

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

nnoremap <C-g> :exec 'Rg' expand('<cword>')<CR>
nnoremap <leader>/ :Rg<Space>
nnoremap <leader>f :Files<CR>
nnoremap <leader>p :GitFiles<CR>
nnoremap <leader>F :GFiles?<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>l :BLines<CR>
nnoremap <leader>h :History<CR>
nnoremap <leader>c :Commands<CR>

if has('nvim')
  " https://github.com/neovim/neovim/issues/9718#issuecomment-559573308
  function! CreateCenteredFloatingWindow()
    let width = min([&columns - 4, max([80, &columns - 20])])
    let height = min([&lines - 4, max([20, &lines - 10])])
    let top = ((&lines - height) / 2) - 1
    let left = (&columns - width) / 2
    let opts = {'relative': 'editor', 'row': top, 'col': left, 'width': width, 'height': height, 'style': 'minimal'}

    let top = "╭" . repeat("─", width - 2) . "╮"
    let mid = "│" . repeat(" ", width - 2) . "│"
    let bot = "╰" . repeat("─", width - 2) . "╯"
    let lines = [top] + repeat([mid], height - 2) + [bot]
    let s:buf = nvim_create_buf(v:false, v:true)
    call nvim_buf_set_lines(s:buf, 0, -1, v:true, lines)
    call nvim_open_win(s:buf, v:true, opts)
    set winhl=Normal:Floating
    let opts.row += 1
    let opts.height -= 2
    let opts.col += 2
    let opts.width -= 4
    call nvim_open_win(nvim_create_buf(v:false, v:true), v:true, opts)
    au BufWipeout <buffer> exe 'bw '.s:buf
  endfunction

  let g:fzf_layout = { 'window': 'call CreateCenteredFloatingWindow()' }
" else
"   let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.8 } }
endif
