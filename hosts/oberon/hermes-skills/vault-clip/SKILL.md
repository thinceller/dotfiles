---
name: vault-clip
description: "Web 記事を knowledge-base vault の Clippings/ に原文のまま保存する。「この記事クリップして」「この URL 取っておいて」など、URL を保存したい依頼で使う。記事の要約や考察の記録には使わない (それは vault-capture)。"
version: 1.0.0
author: thinceller
platforms: [linux]
metadata:
  hermes:
    tags: [Mnemos, Vault, Clipping, Web]
    related_skills: [vault-capture]
---

# Vault Clip (Hermes / 経路C)

Web 記事を vault の `Clippings/` (Layer 1: Raw sources) に保存する。保存されたクリップは
翌朝 07:00 の daily clippings-triage Routine が検知し、Notes 化候補としてレポートに載る。

## 手順

1. `cd /var/lib/hermes/workspace/knowledge-base && git pull --rebase`
2. **本文取得**:
   - GitHub gist・GitHub 上のファイル・raw URL が取れるページ → `curl -sL <raw URL>` で原文取得
   - 通常の記事ページ → web ツールで本文を取得し、**要約せず可能な限り原文のまま** Markdown 化する
   - 本文が断片しか取れない (ペイウォール・ログイン必須) 場合は保存せず、その旨を返信する
3. `Clippings/<記事タイトル>.md` を作成する。同名ファイルが既にあれば `<タイトル> (2).md` にする。
   ファイル名に `/` `:` `|` は使えないので `-` に置換する。frontmatter:

   ```yaml
   ---
   title: "<記事タイトル>"
   source: "<URL>"
   author: <わかれば。不明なら空>
   published: <YYYY-MM-DD、わかれば>
   created: <今日の日付 YYYY-MM-DD>
   description:
   tags:
     - "clippings"
   clipped_by: agent
   ---
   ```

4. `git add Clippings/ && git commit -m "clip: <タイトル>" && git push`
   (push 失敗時は `git pull --rebase` して 1 回だけ再試行。force push は絶対にしない)
5. 保存パスと「翌朝の triage に乗る」ことを Slack で返信する。`log.md` への追記は不要

## 禁止事項

- 既存の Clippings/ ファイルの変更・上書き
- 本文の要約・意訳・編集 (原文の Markdown 化に徹する)
- 途中までしか取れなかった本文を、欠けている旨の注記なしに保存すること
