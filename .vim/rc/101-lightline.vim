if empty(globpath(&rtp, 'plugged/lightline.vim'))
  finish
endif

let g:lightline = {
  \ 'colorscheme': 'nightowl',
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'filename', 'modified', 'cocstatus', 'currentfunction' ] ],
  \   'right': [
  \     [ 'lineinfo' ],
  \     [ 'percent' ],
  \     [ 'fileformat', 'fileencoding', 'filetype' ]
  \   ]
  \ },
  \ 'tabline': { 'left': [ [ 'buffers' ] ], 'right': [ [ 'tabs' ] ]
  \ },
  \ 'component_function': {
  \   'filename': 'FilePath',
  \   'fileformat': 'MyFileformat',
  \   'filetype': 'MyFiletype',
  \   'cocstatus': 'coc#status',
  \   'currentfunction': 'CocCurrentFunction'
  \ },
  \ 'component_expand': {
  \   'buffers': 'lightline#bufferline#buffers',
  \ },
  \ 'component_type': {
  \   'buffers': 'tabsel',
  \ },
  \ 'separator': { 'left': "\ue0b0 ", 'right': " \ue0b2" },
  \ 'subseparator': { 'left': "\ue0b1 ", 'right': " \ue0b3" }
  \ }

let g:lightline#bufferline#show_number = 1
let g:lightline#bufferline#enable_devicons = 1

function! FilePath()
  if '' == expand('%:t')
    return '[No Name]'
  endif
  if winwidth(0) > 90
    return expand("%:s")
  else
    return expand("%:t")
  endif
endfunction

function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction
function! MyFileformat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction
