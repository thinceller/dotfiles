# bashからfishを起動（完全版）
# 参考: https://wiki.archlinux.jp/index.php/Fish
#
# 条件:
# - 親プロセスがfishでない（無限ループ防止）
# - BASH_EXECUTION_STRING が空（bash -c "command" 実行時のループ防止）
if [[ $(ps -o comm= -p $PPID) != "fish" && -z ${BASH_EXECUTION_STRING} ]]; then
    shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
    exec fish $LOGIN_OPTION
fi
