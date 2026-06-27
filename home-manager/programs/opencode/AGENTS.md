# OpenCode User Memory

This file contains personal preferences and settings for OpenCode across all projects.

## Git Worktree Rules

**IMPORTANT**: When a session is started within a git worktree, all file exploration, reading, and editing MUST be performed within the worktree directory.

- Always use the CWD (current working directory) at session start as the project root
- To detect a worktree, check if `.git` is a file (not a directory) — this indicates a worktree
- NEVER resolve the git root from `.git` and operate on files there; stay within the CWD tree
- Project configuration files such as `CLAUDE.md` or `AGENTS.md` MUST be referenced and edited within the worktree

## Design Principle Priorities

Always keep the following priorities in mind when refactoring or designing code:

1. **Simplicity > Complexity**
   - Choose simple, easy-to-understand solutions
   - Avoid excessive abstraction or overuse of design patterns

2. **Clarity > Abstraction**
   - Prioritize code whose intent is clearly communicated
   - Prefer concrete, straightforward implementations over complexity for generality

3. **Practicality > Theory**
   - Focus on solving real problems
   - Avoid designs that are theoretically perfect but impractical

## Avoid Over-Engineering

**IMPORTANT**: Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.

- **Scope**: Do not add features, refactor code, or make "improvements" beyond what was asked
- **Documentation**: Do not add docstrings, comments, or type annotations to code you did not change
- **Defensive coding**: Do not add error handling, fallbacks, or validation for scenarios that cannot happen
- **Abstractions**: Do not create helpers, utilities, or abstractions for one-time operations
- **Future-proofing**: Do not design for hypothetical future requirements; three similar lines is better than a premature abstraction

## Refactoring Checklist

When improving code, always verify the following:

- **Appropriate call hierarchy between files**: Review hierarchies deeper than 3 layers
- **Each file has a clear responsibility**: Follows the single responsibility principle
- **Testability is ensured**: Design with dependency injection and mockability
- **No redundant intermediate layers**: Consider consolidating thin wrappers or meaningless relay layers

## Verification

**IMPORTANT**: After any code change, always perform verification regardless of the change size.

### When to Verify
- Immediately after implementing code changes
- When creating an implementation plan in Plan mode, always include a verification step
- When creating a Todo list, always add a verification task

### How to Verify
- Perform appropriate verification based on the changes (build, test, lint, actual behavior, etc.)
- If the project has tests or CI configuration, always run them
- Never mark a task as "completed" without verification

## Command Execution via Nix

When executing a command via the Bash tool that is not available on the system, use `nix run` to run it from nixpkgs instead of attempting to install it.

```bash
# Example: python3 is not installed
nix run nixpkgs#python3 -- script.py

# Example: jq is not installed
nix run nixpkgs#jq -- '.key' file.json
```

- Always use the `nix run nixpkgs#<package> -- <args>` format
- Do NOT attempt to install packages with `nix-env`, `brew install`, `apt install`, or similar commands
- If the command fails with `nix run`, inform the user rather than trying alternative installation methods

## Language

Please answer in Japanese.
