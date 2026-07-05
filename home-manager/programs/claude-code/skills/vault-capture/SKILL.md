---
name: vault-capture
description: Record knowledge into the Obsidian vault without full web research. Only invoke when the `obsidian_search` MCP tool is available (personal machines). Use for session discoveries, decisions, patterns, or insights worth keeping. Lightweight companion to the vault-internal research-note skill (which does full source-verified web research). Unrefined ideas go to Inbox/ (no filing-criteria check needed).
---

# Vault Capture (Lightweight Record)

**Prerequisite**: This skill requires the `obsidian_create_note` MCP tool (enquire-mcp).
If MCP tools are not available, do not use this skill.

Record knowledge worth keeping into the Obsidian vault using enquire-mcp write tools.
This is the **lightweight** recording skill — no web research, just filing what you
already know or discovered in this session.

## When to Use

- You discovered a reusable insight during this session (not project-specific)
- A decision was made (technical, architectural, workflow)
- You found a code pattern or solution worth remembering
- The user explicitly asks you to "remember this" or "note this down"
- **Compounding loop**: a `vault-memory` query produced a valuable answer worth filing

## When NOT to Use

- Full web research with source verification → use `research-note` skill (vault-internal)
- Project-specific code changes → those live in the project repo, not the vault
- Ephemeral session context → use `vault-session-log` instead
- Trivial facts easily re-discovered

## Relationship to research-note (vault-internal)

| Aspect | `vault-capture` (this skill, dotfiles) | `research-note` (vault-internal) |
|---|---|---|
| Web research | No | Yes (multi-source, fact verification) |
| Source priority table | No | Yes (official docs > Wikipedia > blogs) |
| Sources section required | No | Yes (minimum 2 sources) |
| Use case | Session discoveries, decisions, quick capture | Deep research, term explanations, concept pages |
| Tools | enquire-mcp write tools (`obsidian_create_note` etc.) | Grep/Glob + WebSearch/WebFetch + file write |

**Boundary rule**: If you start `vault-capture` and realize you need `WebSearch` to
verify facts, **stop immediately** and switch to the `research-note` skill (which
requires running Claude Code inside the vault). `vault-capture` is for filing what
you already know — not for researching new information.

If the user asks for deep research with reliable sources, suggest they run Claude Code
inside the vault and use the `research-note` skill instead.

## Directory Structure

Choose the right location for the note:

| Content type | Path |
|---|---|
| Reusable concept / term (atomic) | `Notes/<topic>.md` |
| Agent-specific learnings | `Agents/<Claude-Code\|OpenCode>/learnings/<topic>.md` |
| Technical decisions | `Shared/decisions/<topic>.md` |
| Research results (session-discovered) | `Shared/research/<topic>.md` |
| Code patterns / solutions | `Shared/patterns/<topic>.md` |
| 未整理の思いつき・生煮えの思考 | `Inbox/YYYY-MM-DD-<slug>.md` |

> **Note**: `Notes/` follows the vault's existing atomic note convention (1 page 1 topic,
> flat structure, `[[wikilink]]` links). See the vault's `CLAUDE.md` for details.

## Inbox への振り分け

ファイル化基準(2 ソース統合・固有名詞・再質問可能性・非自明な接続)を**満たさない**が、
ユーザーが「残したい」「あとで考えたい」と言った内容は `Inbox/` に保存する。
frontmatter は `type: inbox` / `created` / `source: session` / `status: raw`。
`log.md` への追記は不要。基準を満たす結論は従来通り `Notes/` / `Shared/` へ。

## Frontmatter

Every new note must include frontmatter. **Get the current timestamp by running
`date -Iseconds` in Bash** (LLM does not have a built-in clock):

```bash
$ date -Iseconds
2026-06-28T14:30:00+09:00
```

```yaml
---
created: <output of `date -Iseconds`>
tags:
  - <relevant-tag>
type: <learning|decision|research|pattern|session-log>
agent: <Claude-Code|OpenCode|Hermes-Agent>
---
```

## Creating a Note

Use `obsidian_create_note`:

```
obsidian_create_note(
  path: "Shared/decisions/postgres-vs-mongo.md",
  content: "---\ncreated: 2026-06-28T...\ntags: [database, decision]\ntype: decision\nagent: Claude-Code\n---\n\n# PostgreSQL vs MongoDB\n\n<content with [[wikilinks]]>"
)
```

## Appending to a Note

Use `obsidian_append_to_note` when adding to an existing note.

## Wikilinks

Connect the new note to related notes using `[[wikilink]]` syntax in the body:

```markdown
We chose PostgreSQL for this project. See [[Notes/ROI (投資利益率)]] for the
cost analysis, and [[Shared/patterns/db-migration]] for the rollout pattern.
```

This builds the vault's knowledge graph. enquire-mcp's wikilink graph-boost will
surface well-connected notes in future searches.

## After Creating

1. Confirm the note path to the user
2. Append to `log.md`: `## [YYYY-MM-DD] capture | <short description>`
3. Update `index.md` if the note is a significant new entry