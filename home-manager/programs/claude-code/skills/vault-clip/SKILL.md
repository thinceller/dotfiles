---
name: vault-clip
description: >-
  Web 記事を Obsidian vault の Clippings/ に Web Clipper 互換形式で保存するスキル。
  「この記事クリップして」「この URL を vault に保存して」「あとで読むから取っておいて」など、
  URL を原文のまま保存したい意図が見えたら発火する。Only invoke when the vault
  (~/src/github.com/thinceller/knowledge-base) is accessible (personal machines).
  記事を調べて裏取りノートにするのは research-note、知見の記録は vault-capture、
  未整理の思考は inbox-capture — このスキルは「原文の保存」だけを担当する。
---

# Vault Clip (エージェント経由の Web クリップ)

Web 記事を `Clippings/`(Layer 1: Raw sources)に保存する。保存されたクリップは
翌朝 07:00 の daily clippings-triage Routine が自動で検知し、Notes 化候補として
レポートに載る — 人間の Web Clipper と同じパイプラインに乗る。

## 手順

1. **本文取得**: raw の Markdown/テキストが直接取れるソース(GitHub gist・GitHub 上の
   ファイル・raw URL があるページ)は `curl -sL <raw URL>` を優先する — 完全な原文が
   取れる。それ以外は WebFetch で取得する。プロンプトは
   「記事の本文全体を、省略・要約せずそのまま Markdown で出力してください。
   タイトル・著者名・公開日もわかれば先頭に明記してください」とする。
   **注意: WebFetch は小型モデル経由のため、指示しても要約化されることがある。
   結果が三人称の説明文になっていたら原文ではない** — その場合は raw 経路を探すか、
   忠実性が落ちる旨をユーザーに伝えて判断を仰ぐ。
   長い記事で内容が途中で切れていると思われる場合は、その旨を保存ファイル末尾に
   `> [!note] この記事はエージェント経由のクリップで、末尾が欠けている可能性がある`
   と記す(完全な忠実性が必要なら人間の Web Clipper を使うのが正)

2. **ファイル名**: 記事タイトル準拠(既存 Clippings の規約)。
   `/` `:` `|` など macOS/Obsidian で使えない文字は全角か `-` に置換する

3. **frontmatter**: Web Clipper 互換 + エージェント識別子:

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

   `clipped_by: agent` は人間の Web Clipper 産と区別するためのマーカー(Clipper 産には無い)

4. **保存**:
   - 経路B(vault が CWD 外): `obsidian_create_note` で path `Clippings/<タイトル>.md`
   - 経路A(vault 内): Write で直接作成
   - commit は obsidian-git の自動コミットに任せてよい

5. **報告**: 保存パスと「翌朝の triage に乗る」ことを伝える。`log.md` への追記は不要
   (triage Routine が検知するため)

## してはいけないこと

- 既存の Clippings/ ファイルの変更・上書き(同名があればファイル名に ` (2)` を付ける)
- 本文の要約・意訳・編集(原文の Markdown 化に徹する。Layer 1 は真実の源泉)
- ペイウォール・ログイン必須で本文が取れないページの無理な保存
  (取れた範囲が断片なら保存せず、その旨をユーザーに伝える)
