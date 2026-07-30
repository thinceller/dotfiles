---
name: vault-session-log
description: Record a session summary into the Obsidian vault at the end of a productive session. Only invoke when the `obsidian_create_note` MCP tool is available (personal machines). Use when the session produced meaningful changes, decisions, or learnings worth referencing later.
---

# Vault Session Log

**Prerequisite**: This skill requires the `obsidian_create_note` MCP tool (enquire-mcp).
If MCP tools are not available, do not use this skill.

Write a structured session summary to the vault at session end (or when the user
asks you to "log this session").

## When to Use

- The session produced non-trivial code changes or architectural decisions
- Research or investigation worth referencing in future sessions
- The user explicitly requests a session log
- You learned something about the user's environment or preferences

## When NOT to Use

- Trivial sessions (quick Q&A, single-file edits)
- Sessions where nothing reusable was learned
- The user did not ask for a log and nothing significant happened

## File Path

```
Agents/<Claude-Code|OpenCode>/sessions/YYYY-MM-DD_HH-MM_<short-description>.md
```

Example: `Agents/Claude-Code/sessions/2026-06-28_14-30_obsidian-vault-mcp-setup.md`

Use 24-hour JST timestamp. Keep the description short (kebab-case, 3-5 words).
**Get the current timestamp by running `date -Iseconds` in Bash** (LLM does not
have a built-in clock):

```bash
$ date -Iseconds
2026-06-28T14:30:00+09:00
```

## Frontmatter

```yaml
---
created: <output of `date -Iseconds`>
tags:
  - session-log
type: session-log
agent: Claude-Code
---
```

## Content Structure

```markdown
# <Session Title>

## Summary
<2-3 sentence overview of what was accomplished>

## Changes
- <file or system changed, with brief context>

## Decisions
- [[<decision-note>]]: <one-line decision rationale>
  (create a separate decision note in Shared/decisions/ if the decision is reusable)

## Learnings
- [[<learning-note>]]: <one-line insight>
  (create a separate learning note in Agents/<agent>/learnings/ if reusable)

## Follow-ups
- [ ] <action item for a future session>
```

## Workflow

1. Create the session log note with `obsidian_create_note`
2. For each Decision and Learning, if it's reusable beyond this session, create a
   separate note in the appropriate directory and link to it with `[[wikilink]]`
   (use `vault-capture` skill for the independent notes)
3. Confirm the session log path to the user