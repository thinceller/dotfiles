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

Run the helper script:

```bash
nix run nixpkgs#python3 -- /var/lib/hermes/.hermes/scripts/to-kanban.py <board-slug> <repo-path> <feature-slug>
```

If Python is not available directly, use the `execute_code` tool with the same script.

## Verification

After running:
- `hermes kanban --board <board-slug> list` should show the new tasks
- `hermes kanban --board <board-slug> show <id>` should show correct body and parents

## Notes

- Assignee is always `worker`
- Workspace is always `dir:<repo-path>`
- Parent/child relationships are set with `--parent` and `kanban_link`
- If the board does not exist, create it first with `hermes kanban boards create <board-slug>`

## See also

- `hermes-kanban-implementation` umbrella skill for full workflow templates, reference SOUL.md files, and project AGENTS.md examples.
