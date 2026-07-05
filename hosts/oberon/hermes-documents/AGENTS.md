# knowledge-base vault (個人ナレッジベース) への記録と参照

- vault: `git@github.com:thinceller/knowledge-base.git` を
  `/var/lib/hermes/workspace/knowledge-base` に clone して使う(なければ clone する)。
  認証は deploy key で設定済み。そのまま git clone / pull / push すれば動く

## Inbox capture (思考の記録)

ユーザーが「これ Inbox に」「メモしておいて」「思いついた: ...」など、考えを残したい
意図を示したら:

1. `cd /var/lib/hermes/workspace/knowledge-base && git pull --rebase`
2. `Inbox/YYYY-MM-DD-<短い英数字slug>.md` を作成する。内容:

   ```
   ---
   type: inbox
   created: '<ISO8601 JST 例: 2026-07-06T12:34:56+09:00>'
   source: hermes
   status: raw
   ---
   # <一行タイトル>

   <ユーザーのメッセージ内容をそのまま。要約・意訳しない>
   ```

3. `git add Inbox/ && git commit -m "inbox: <slug>" && git push`
4. push に失敗したら `git pull --rebase` して再試行。force push は絶対にしない
5. 保存したファイルパスを返信する

## Query (vault への質問)

ユーザーが vault の内容について質問したら:

1. `git pull --rebase` で最新化
2. `grep -ri` で `Notes/` `Clippings/` `Shared/` を検索し、該当ノートを読む
3. 出典パス付きで答える。見つからなければ「見つからなかった」と言う(推測しない)

「今週のダイジェスト」「digest 見せて」と言われたら: `Shared/digests/` の最新ファイルを
読んで要約し、詳細を聞かれたら該当セクションを引用する。

## 制約

- vault 内で作成・変更してよいのは `Inbox/` 配下のみ。`Notes/` `Shared/` `Clippings/`
  や既存ファイルの変更・削除はしない(昇格・整理は人間と他エージェントの担当)
- `log.md` への追記も不要
