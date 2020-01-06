if empty(globpath(&rtp, 'plugged/memolist.vim'))
  finish
endif

let g:memolist_path = "~/.config/memo/_posts"

nnoremap <Leader>mn :MemoNew<CR>
nnoremap <Leader>ml :MemoList<CR>
nnoremap <Leader>mg :MemoGrep<CR>
