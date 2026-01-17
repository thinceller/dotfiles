# .bashrcを読み込む
[[ -f ~/.bashrc ]] && source ~/.bashrc

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.bash 2>/dev/null || :
