# knowledge-base vault (個人ナレッジベース) への記録と参照

- vault: `git@github.com:thinceller/knowledge-base.git` を
  `/var/lib/hermes/workspace/knowledge-base` に clone して使う(なければ clone する)。
  認証は deploy key で設定済み。そのまま git clone / pull / push すれば動く

## Inbox capture (思考の記録)

ユーザーが「これ Inbox に」「メモしておいて」「思いついた: ...」など、考えを残したい
意図を示したら:

1. `cd /var/lib/hermes/workspace/knowledge-base && git pull --rebase`
2. `Inbox/YYYY-MM-DD-<短い英数字slug>.md` を作成する。同名ファイルが既に存在する
   場合は上書きせず `-2`, `-3` とサフィックスを付ける。内容:

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

## クリップと知見の記録 (スキル参照)

- 「この記事クリップして」+ URL → **vault-clip スキル**の手順に従う (`Clippings/` に原文保存)
- 「これ覚えておいて」「この決定を記録して」(結論になった知見) → **vault-capture スキル**の
  手順に従う (`Shared/decisions|research|patterns/` に記録)
- まだ結論でない思いつき → 上記の Inbox capture (`Inbox/`)

## 制約

- vault 系スキル (vault-clip / vault-capture) は**読むだけ**でよい。`skill_manage` での
  保存・編集はしない (外部スキルディレクトリは読み取り専用で、書き込みはエラーになる)
- 日付・時刻は必ず `date` コマンドで確認する (推測すると間違える)

- vault 内で作成してよいのは `Inbox/`、`Clippings/`(vault-clip 経由の新規のみ)、
  `Shared/` 配下(vault-capture 経由の新規のみ)。**既存ファイルの変更・削除は禁止**
- `Notes/` には書かない(アトミックノート網への昇格は weekly synthesis の提案と人間の判断)
- `log.md` への追記は vault-capture の手順にある場合のみ(Inbox capture では不要)

# GitHub リポジトリでの作業 (vault 以外)

machine account `thinceller-hermes` として、招待済みの repo にのみ push できる。

- 扱ってよい repo: `thinceller/dotfiles` (vault = knowledge-base は上記の専用フローに従う)
- 作業場所: `/var/lib/hermes/workspace/<repo名>` に clone する
  (なければ `git@github.com:thinceller/<repo名>.git` を clone)
- 変更は必ず `hermes/<短い英数字slug>` ブランチを切って push する。
  default branch (master/main) への直 push はしない
- force push は絶対にしない
- push したら `gh pr create` で PR を作成し、PR の URL を返信する
- 上記リスト外の repo を操作するよう指示されたら、push せずユーザーに確認する
