### 各種設定の読み込み
for f in $ZDOTDIR/rc/*.zsh
do
  source "$f"
done
