# if disable deno cache command when plugin loaded
# export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1

# if enable fzf-tmux
export ZENO_ENABLE_FZF_TMUX=1

# if setting fzf-tmux options
# export ZENO_FZF_TMUX_OPTIONS="-p"

# if disable builtin completion
# export ZENO_DISABLE_BUILTIN_COMPLETION=1

# default
# export ZENO_GIT_CAT="cat"
# git file preview with color
export ZENO_GIT_CAT="bat --color=always"

# default
# export ZENO_GIT_TREE="tree"
# git folder preview with color
export ZENO_GIT_TREE="exa --tree"

bindkey ' '  zeno-auto-snippet
bindkey '^m' zeno-auto-snippet-and-accept-line
bindkey '^i' zeno-completion

bindkey '^r'   zeno-history-selection
bindkey '^x^s' zeno-insert-snippet
bindkey '^g' zeno-ghq-cd
