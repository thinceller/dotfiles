if empty(globpath(&rtp, 'plugged/preview-markdown.vim'))
  finish
endif

let g:preview_markdown_vertical = 1
let g:preview_markdown_parser = 'mdcat'
