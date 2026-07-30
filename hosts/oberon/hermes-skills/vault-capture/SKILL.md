---
name: vault-capture
description: "決定事項・調査結果・コードパターンなど「結論になった知見」を knowledge-base vault の Shared/ に記録する。「これ覚えておいて」「この決定を記録して」「このパターン残して」で使う。まだ結論でない思いつきは AGENTS.md の Inbox capture 手順 (Inbox/) を使う。URL の原文保存は vault-clip。"
version: 1.0.0
author: thinceller
platforms: [linux]
metadata:
  hermes:
    tags: [Mnemos, Vault, Capture, Knowledge]
    related_skills: [vault-clip]
---

# Vault Capture (Hermes / 経路C)

結論になった知見を vault の `Shared/` 配下に 1 トピック 1 ファイルで記録する。

## 保存先の選択

| 内容 | 保存先 |
|---|---|
| 技術的・個人的な決定事項 | `Shared/decisions/<topic>.md` |
| 調査結果 | `Shared/research/<topic>.md` |
| コードパターン・解決策 | `Shared/patterns/<topic>.md` |

**`Notes/` には書かない** — アトミックノート網への昇格は weekly synthesis Routine の提案と
人間の判断に任せる。迷ったら `Shared/research/` か、未整理なら Inbox capture に回す。

## 手順

1. `cd /var/lib/hermes/workspace/knowledge-base && git pull --rebase`
2. `<topic>` は内容を表す短い英数字ケバブケース。同名ファイルが既にあれば `-2` を付ける
   (既存ファイルは変更しない)
3. ファイルを作成する:

   ```markdown
   ---
   created: '<ISO8601 JST。必ず `date -Iseconds` を実行して確認する。推測しない>'
   tags:
     - <内容に合うタグ 1-3 個>
   type: decision | research | pattern
   agent: Hermes-Agent
   ---
   # <タイトル>

   <内容。ユーザーの言葉と文脈を保ちつつ、あとで読んでわかる形に>

   ## 関連ページ

   <grep -ri で Notes/ から関連しそうなページを探し、[[ページ名]] を 1-2 個。無ければ「なし」>
   ```

4. `git add Shared/ && git commit -m "capture: <topic>" && git push`
   (push 失敗時は `git pull --rebase` して 1 回だけ再試行。force push は絶対にしない)
5. 保存パスを Slack で返信する

## 禁止事項

- `Notes/` への書き込み、既存ファイルの変更・削除
- 内容の過度な要約 (再導出が面倒な固有名詞・数字・理由は必ず残す)
