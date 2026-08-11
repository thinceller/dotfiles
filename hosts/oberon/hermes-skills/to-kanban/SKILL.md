---
name: to-kanban
description: Convert mattpocock/to-tickets local files into Hermes kanban tasks and link their dependencies on a project board.
disable-model-invocation: true
---

# To Kanban

Convert the local ticket files produced by `/to-tickets` into Hermes kanban tasks on a project board, then wire up blocking dependencies.

## When to use

After `/to-tickets` has written `.scratch/<feature-slug>/issues/*.md` and the user has approved the breakdown. Do not run this before the ticket breakdown is approved.

## Inputs

Ask the user for (or infer from context):
- `board-slug`: the Hermes kanban board for this project (e.g. `thinceller-net`, `dotfiles`)
- `repo-path`: absolute path to the repository workspace (e.g. `/var/lib/hermes/workspace/thinceller.net`)
- `feature-slug`: the feature directory name under `.scratch/`

## Execution

Run the helper command (provided on PATH by the NixOS module):

```bash
to-kanban <board-slug> <repo-path> <feature-slug>
```

The command validates every ticket first (numbering, unknown or circular
dependencies), then creates the tasks in dependency order, wiring each one's
blockers with `--parent` at creation time. It exits non-zero without creating
anything if validation fails.

## Verification

After running:
- `hermes kanban --board <board-slug> list` should show the new tasks
- `hermes kanban --board <board-slug> show <id>` should show correct body and parents

## Notes

- Assignee is always `worker`
- Workspace is always `dir:<repo-path>`
- The worker's procedure lives in its profile SOUL.md, which is always in the
  worker's prompt — nothing needs to be force-loaded per task
- Tasks are created in topological order with `--parent`, so a ticket may declare a
  blocker that appears later in the file order
- `**Blocked by:**` must reference tickets as `#01, #02` — a title-only reference is
  rejected with a non-zero exit rather than silently dropped, and a ticket with no
  `**Blocked by:**` line at all is rejected too
- Boards are declared in dotfiles (`hosts/oberon/hermes-agent.nix`, the
  `hermes-kanban-boards` unit) and created on activation — you should not need to
  create one by hand
