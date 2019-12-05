function! SourceFile(file)
  if filereadable(expand(a:file))
    execute 'source ' . a:file
  endif
endfunction

call SourceFile('~/.vim/rc/basic.vim')

call SourceFile('~/.vim/rc/plugins.vim')
