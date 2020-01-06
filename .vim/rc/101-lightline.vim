if empty(globpath(&rtp, 'plugged/lightline.vim'))
  finish
endif

let g:lightline = {
  \ 'colorscheme': 'material',
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ], [ 'filename' ] ],
  \   'right': [ [ 'lineinfo' ], [ 'percent' ], [ 'charvaluehex', 'fileformat', 'fileencoding', 'filetype' ] ]
  \ },
  \ 'tabline': { 'left': [ [ 'buffers' ] ], 'right': [ [ 'tabs' ] ]
  \ },
  \ 'component': {
  \   'charvaluehex': '0x%B'
  \ },
  \ 'component_function': {
  \   'filename': 'LightlineFilename',
  \   'fileformat': 'MyFileformat',
  \   'filetype': 'MyFiletype'
  \ },
  \ 'component_expand': {
  \   'buffers': 'lightline#bufferline#buffers',
  \ },
  \ 'component_type': {
  \   'buffers': 'tabsel',
  \ },
  \ 'separator': { 'left': ' ', 'right': ' ' },
  \ 'subseparator': { 'left': '  ', 'right': '  ' }
  \ }

let g:lightline#bufferline#show_number = 1
let g:lightline#bufferline#enable_devicons = 1

function! LightlineModified()
  return &ft =~ 'help\|vimfiler' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction
function! LightlineReadonly()
  return &ft !~? 'help\|vimfiler' && &readonly ? '⭤' : ''
endfunction
function! LightlineFilename()
  return ('' != LightlineReadonly() ? LightlineReadonly() . ' ' : '') .
  \ (&ft == 'vimfiler' ? vimfiler#get_status_string() :
  \  &ft == 'unite' ? unite#get_status_string() :
  \  &ft == 'vimshell' ? vimshell#get_status_string() :
  \ '' != expand('%:t') ? expand('%:t') : '[No Name]') .
  \ ('' != LightlineModified() ? ' ' . LightlineModified() : '')
endfunction

function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction
function! MyFileformat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction

