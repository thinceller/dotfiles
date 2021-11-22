if empty(globpath(&rtp, 'plugged/denops.vim'))
  finish
endif

let g:denops_disable_version_check = 1
