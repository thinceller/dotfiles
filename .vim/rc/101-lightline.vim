if empty(globpath(&rtp, 'plugged/lightline.vim'))
  finish
endif

let g:lightline = {
  \ 'colorscheme': 'material',
  \ 'active': {
  \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'filename', 'modified' ] ],
  \   'right': [
  \     [ 'lineinfo' ],
  \     [ 'percent' ],
  \     [ 'errorstatus', 'warnstatus', 'infostatus', 'fileformat', 'fileencoding', 'filetype' ]
  \   ]
  \ },
  \ 'tabline': { 'left': [ [ 'buffers' ] ], 'right': [ [ 'tabs' ] ]
  \ },
  \ 'component_function': {
  \   'filename': 'FilePath',
  \   'fileformat': 'MyFileformat',
  \   'filetype': 'MyFiletype',
  \   'infostatus': 'InfoStatusDiagnostic',
  \   'warnstatus': 'WarningStatusDiagnostic',
  \   'errorstatus': 'ErrorStatusDiagnostic'
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

" coc custom component
function! ErrorStatusDiagnostic() abort
  let info = get(b:, 'coc_diagnostic_info', {})
  if (empty(info) || info['error'] == 0)
    return ''
  endif
  return "\uf05e" . ' ' . info['error']
endfunction
function! WarningStatusDiagnostic() abort
  let info = get(b:, 'coc_diagnostic_info', {})
  if (empty(info) || info['warning'] == 0)
    return ''
  endif
  return "\uf071" . ' ' . info['warning']
endfunction
function! InfoStatusDiagnostic() abort
  let info = get(b:, 'coc_diagnostic_info', {})
  if (empty(info) || info['information'] == 0)
    return ''
  endif
  return "\uf7fc" . ' ' . info['information']
endfunction
