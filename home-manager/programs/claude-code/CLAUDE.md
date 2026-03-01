# Claude Code User Memory

This file contains personal preferences and settings for Claude Code across all projects.

## Git Worktree Rules

**IMPORTANT**: When a session is started within a git worktree, all file exploration, reading, and editing MUST be performed within the worktree directory.

- Always use the CWD (current working directory) at session start as the project root
- To detect a worktree, check if `.git` is a file (not a directory) — this indicates a worktree
- NEVER resolve the git root from `.git` and operate on files there; stay within the CWD tree
- CLAUDE.md and other configuration files MUST be referenced and edited within the worktree

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

## Refactoring Checklist

When improving code, always verify the following:

- **Appropriate call hierarchy between files**: Review hierarchies deeper than 3 layers
- **Each file has a clear responsibility**: Follows the single responsibility principle
- **Testability is ensured**: Design with dependency injection and mockability
- **No redundant intermediate layers**: Consider consolidating thin wrappers or meaningless relay layers

## Code Improvement

**IMPORTANT**: After completing code implementation, select the appropriate tool based on the scale of changes to improve the code.

### Tool Selection Criteria

Assess the scale of changes and select a tool based on the following criteria:

- **Small changes** (3 files or fewer, roughly under 100 lines) → `code-simplifier:code-simplifier`
  - Focuses on code clarity, consistency, and maintainability, refining code to match project coding conventions
  - Token-efficient (single agent)
- **Medium to large changes** (4+ files, or 100+ lines) → `/simplify`
  - Performs parallel review across 3 axes: reusability, quality, and efficiency; detects duplication with existing utilities and structural issues like N+1 patterns
  - Higher token consumption due to 3 parallel agents, but prevents oversights in medium-to-large changes

### When to Run
- After completing code edits, before verification
- When creating an implementation plan in Plan mode, always include a code improvement step
- When creating a Todo list, always add a code improvement task

### How to Run
- **code-simplifier**: Launch a subagent using the Agent tool (subagent_type: "code-simplifier:code-simplifier")
- **/simplify**: Execute using the Skill tool
- Target: recently changed code files

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
