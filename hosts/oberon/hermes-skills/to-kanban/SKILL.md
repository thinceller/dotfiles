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

The command creates every ticket as a kanban task first, then wires up the
`Blocked by` edges with `hermes kanban link`. It exits non-zero and reports on
stderr if any dependency could not be resolved.

## Verification

After running:
- `hermes kanban --board <board-slug> list` should show the new tasks
- `hermes kanban --board <board-slug> show <id>` should show correct body and parents

## Notes

- Assignee is always `worker`
- Workspace is always `dir:<repo-path>`
- The `kanban-worker-impl` skill is force-loaded into every task via `--skill`
- Dependencies are created with `hermes kanban link` after all tasks exist, so a
  ticket may depend on a ticket that appears later in the file order
- Boards are declared in dotfiles (`hosts/oberon/hermes-agent.nix`, the
  `hermes-kanban-boards` unit) and created on activation — you should not need to
  create one by hand
- `**Blocked by:**` must reference tickets as `#01, #02` — a title-only reference is
  rejected with a non-zero exit rather than silently dropped
