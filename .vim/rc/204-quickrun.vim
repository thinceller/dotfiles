if empty(globpath(&rtp, 'plugged/vim-quickrun'))
  finish
endif

let g:quickrun_config = {
      \ '_': {
      \   'outputter': 'buffered',
      \   'outputter/buffered/target': 'buffer',
      \   'outputter/buffer/split': '%{winwidth(0) * 2 < winheight(0) * 5 ? "" : "vertical"}'
      \ }
      \ }

let g:quickrun_config['ruby.rspec'] = {
      \ 'command': 'bundle',
      \ 'cmdopt': 'exec rspec'
      \ }

augroup my_rspec
  autocmd!
  autocmd BufEnter *_spec.rb set filetype=ruby.rspec
augroup END
