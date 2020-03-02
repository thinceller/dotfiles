if empty(globpath(&rtp, 'plugged/vim-quickrun'))
  finish
endif

let g:quickrun_config = {
  \ '_': {
  \   'outputter': 'buffered',
  \   'outputter/buffered/target': 'buffer',
  \   'outputter/buffer/split': ''
  \ }
  \ }
