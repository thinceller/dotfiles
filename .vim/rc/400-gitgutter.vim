if empty(globpath(&rtp, 'plugged/vim-gitgutter'))
  finish
endif

let g:gitgutter_map_keys = 0
let g:gitgutter_sign_added = '▌'
let g:gitgutter_sign_modified = '▌'
let g:gitgutter_sign_removed = '▌'
let g:gitgutter_sign_modified_removed = '▌'
nmap ]g :GitGutterNextHunk<CR>
nmap [g :GitGutterPrevHunk<CR>]
