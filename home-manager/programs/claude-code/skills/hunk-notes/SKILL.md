---
name: hunk-notes
description: Read the inline review notes the user wrote in a live Hunk session and act on them. Use when the user says they reviewed the diff or left notes/comments in hunk, or asks you to check, read, or address their review — e.g. "hunk でレビューしたから見て", "note 書いた", "レビューコメント読んで", "指摘に対応して", "review タブ見て". For driving the Hunk TUI itself (navigate, reload, leave agent notes), use the bundled hunk-review skill instead.
allowed-tools: Bash(hunk:*)
---

# Hunk Notes: Reading the User's Review

The herdr launcher (`configs/bin/herdr-launch`) opens a `review` tab running
`hunk diff --watch` in every workspace. The user reviews your changes there and
writes inline notes on the diff (`c` to start a note, `ctrl+s` to save).

Those notes are review feedback addressed to you. Read them from the CLI — never
open the TUI yourself.

## Read the notes

```bash
hunk session comment list --repo . --type user --json
```

- `--repo` matches the session by its loaded repo root. In a worktree, pass the
  worktree path (`--repo .` from your cwd is normally right).
- `--type user` is what selects human-written notes. Without it you get the
  legacy live-agent-comment view, which is *not* the user's review.
- Empty `{"comments": []}` means the user has not written anything yet. Say so
  instead of guessing what they meant.

Each entry:

| field | meaning |
| --- | --- |
| `noteId` | stable id for this note |
| `source` | `user` (human) / `agent` / `ai` |
| `filePath` | path relative to the repo root |
| `newRange` / `oldRange` | `[start, end]` line range on the new / old side |
| `hunkIndex` | 0-based hunk index, when the note targets a whole hunk |
| `title` / `body` | the note itself (`body` is the main text) |
| `createdAt` / `updatedAt` | ISO timestamps — use to spot notes added since your last read |

To see notes together with the file/hunk structure they hang off:

```bash
hunk session review --repo . --include-notes --json
```

## Act on them

1. Read every note before touching code — later notes often revise earlier ones.
2. For each note, open the file at `newRange` (or `oldRange` for deleted lines)
   and read enough surrounding code to understand the point.
3. Fix what should be fixed. If a note is a question or you disagree, answer it
   in chat rather than silently changing the code.
4. Report back per note: which file/line, what the note asked, what you did.
   Group them if there are many, but do not drop any silently.

`--watch` reloads the diff as you edit, so the user sees your fixes without
touching anything.

## Replying inside Hunk

When a response is more useful pinned to the code than in chat, leave an agent
note next to theirs (syntax lives in the hunk-review skill):

```bash
hunk session comment add --repo . --file src/App.tsx --new-line 42 --summary "Fixed: ..."
```

Do this only when the user asks for inline replies — chat is the default.

## Do not

- Do not delete or clear the user's notes. `hunk session comment clear --include-user`
  destroys their review; if cleanup seems needed, ask first.
- Do not `hunk session reload` the review tab unprompted — it swaps what the user
  is looking at mid-review.
- Do not run `hunk diff` / `hunk show` yourself; those are the user's TUI.

## Troubleshooting

- **"No active Hunk sessions"** — the review tab may be closed (ask the user), or
  the sandbox is blocking the local daemon socket; retry unsandboxed.
- **"Multiple active sessions match"** — several worktrees have a session open.
  Pass an absolute `--repo /path/to/this/worktree`, or the exact session id from
  `hunk session list --json`.
