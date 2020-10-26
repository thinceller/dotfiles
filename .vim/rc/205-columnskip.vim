if empty(globpath(&rtp, 'plugged/columnskip.vim'))
  finish
endif

nmap tj <Plug>(columnskip:nonblank:next)
omap tj <Plug>(columnskip:nonblank:next)
xmap tj <Plug>(columnskip:nonblank:next)
nmap tk <Plug>(columnskip:nonblank:prev)
omap tk <Plug>(columnskip:nonblank:prev)
xmap tk <Plug>(columnskip:nonblank:prev)
