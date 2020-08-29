if empty(globpath(&rtp, 'plugged/vim-startify'))
  finish
endif

" 参考: http://mjhd.hatenablog.com/entry/recommendation-of-vim-startify
let g:startify_files_number = 5
let g:startify_bookmarks = [
  \ '~/.vim/vimrc',
  \ '~/.zsh/.zshenv',
  \ '~/.zsh/.zshrc',
  \ '~/.tmux.conf'
  \ ]

function! s:center(lines) abort
  let longest_line   = max(map(copy(a:lines), 'strwidth(v:val)'))
  let centered_lines = map(copy(a:lines),
        \ 'repeat(" ", (&columns / 2) - (longest_line / 2)) . v:val')
  return centered_lines
endfunction

let g:startify_custom_header = s:center([
  \'   __  __    _                 ____',
  \'  / /_/ /_  (_)___  ________  / / /__  _____',
  \' / __/ __ \/ / __ \/ ___/ _ \/ / / _ \/ ___/',
  \'/ /_/ / / / / / / / /__/  __/ / /  __/ /',
  \'\__/_/ /_/_/_/ /_/\___/\___/_/_/\___/_/',
  \'',
  \'             _    ___',
  \'            | |  / (_)___ ___',
  \'            | | / / / __ `__ \',
  \'            | |/ / / / / / / /',
  \'            |___/_/_/ /_/ /_/',
  \'',
  \])
