# ホームディレクトリにある .env.sh に設定した環境変数を読み取る
source $HOME/.env.sh

### 各種設定の読み込み
for f in $ZDOTDIR/rc/*.zsh
do
  source "$f"
done
