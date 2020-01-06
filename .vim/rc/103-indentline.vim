if empty(globpath(&rtp, 'plugged/indentline'))
  finish
endif

let g:indentLine_char_list = ['|', '¦', '┆', '┊']
let g:indentLine_fileTypeExclude = ['startify', 'fzf']
let g:indentLine_bufTypeExclude = ['help', 'terminal']
