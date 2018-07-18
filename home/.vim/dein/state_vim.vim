if g:dein#_cache_version !=# 100 || g:dein#_init_runtimepath !=# '/Users/kohei/.vim/dein/repos/github.com/Shougo/dein.vim/,/Users/kohei/.vim,/usr/share/vim/vimfiles,/usr/share/vim/vim80,/usr/share/vim/vimfiles/after,/Users/kohei/.vim/after' | throw 'Cache loading error' | endif
let [plugins, ftplugin] = dein#load_cache_raw(['/Users/kohei/.vimrc', '/Users/kohei/.vim/rc/dein.toml'])
if empty(plugins) | throw 'Cache loading error' | endif
let g:dein#_plugins = plugins
let g:dein#_ftplugin = ftplugin
let g:dein#_base_path = '/Users/kohei/.vim/dein'
let g:dein#_runtime_path = '/Users/kohei/.vim/dein/.cache/.vimrc/.dein'
let g:dein#_cache_path = '/Users/kohei/.vim/dein/.cache/.vimrc'
let &runtimepath = '/Users/kohei/.vim/dein/repos/github.com/Shougo/dein.vim/,/Users/kohei/.vim,/usr/share/vim/vimfiles,/Users/kohei/.vim/dein/.cache/.vimrc/.dein,/usr/share/vim/vim80,/Users/kohei/.vim/dein/.cache/.vimrc/.dein/after,/usr/share/vim/vimfiles/after,/Users/kohei/.vim/after'
