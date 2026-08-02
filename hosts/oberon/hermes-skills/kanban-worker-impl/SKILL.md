---
name: kanban-worker-impl
description: Implementation worker skill for Hermes kanban tasks. Reads the task, implements, verifies, commits, pushes, and creates a Draft PR.
disable-model-invocation: true
---

# Kanban Worker Implementation

You are an implementation worker spawned by the Hermes kanban dispatcher.
Your job is to take the assigned kanban task and implement it end-to-end.

## On spawn

1. Call `kanban_show()` to read your task.
2. Identify the workspace path from the task.
3. Move to the workspace directory.
4. Read the project's `CLAUDE.md` and `AGENTS.md`.

## Implementation loop

1. Understand the task body and acceptance criteria.
2. Identify the exact files to modify. **Do not create new files unless explicitly requested in the task.**
3. If you believe the task requires files not listed, call `kanban_block()` and wait for clarification.
4. Create a feature branch from the freshly fetched base branch — never from the
   current HEAD, because the workspace is a shared checkout that may still be on
   a previous task's branch:

   ```bash
   git fetch origin
   git checkout -B feat/<task-id>-<slug> origin/<base-branch>
   ```

   Base branch: `master` for dotfiles, `main` for thinceller.net.
5. Implement the change.
6. Run the project's verification commands.
7. If verification fails, fix the issue or block the task with `kanban_block()`.
8. `git add`, `git commit`, `git push origin <branch>`.
9. Create a Draft PR with `gh pr create --draft`.
10. Call `kanban_complete()` with summary, metadata, and PR URL.
11. Return the workspace to its base branch with `git checkout <base-branch>` so the
    next task does not branch off your work.

## Verification commands

### thinceller.net

```bash
nix develop -c pnpm lint && nix develop -c pnpm format && nix develop -c pnpm typecheck
```

Run E2E tests only if the task involves UI changes:

```bash
nix develop -c pnpm build
nix develop -c pnpm test:e2e
```

### dotfiles

```bash
nix fmt
nix eval --raw .#darwinConfigurations.kohei-m4-mac-mini.system.drvPath
nix eval --raw .#darwinConfigurations.SC-N-843.system.drvPath
nix build .#nixosConfigurations.oberon.config.system.build.toplevel --no-link
```

`git add` new files before running `nix build`.

## Constraints

- Do not merge without explicit user approval.
- Do not make changes outside the task scope.
- If blocked, call `kanban_block()` with a clear reason.
- Use Conventional Commits for commit messages and PR titles.
- Never `git push --force`.
- Never push directly to the default branch (`master` / `main`).
