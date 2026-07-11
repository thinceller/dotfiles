# Claude Code User Memory

This file contains personal preferences and settings for Claude Code across all projects.

## Lead Agent Policy (Orchestration)

**Applies only when your model is Opus or Fable** — check the "You are powered by" line in your system prompt. On any other model, skip this section and work directly. (This gate is mandatory: subagents also read this file, and it prevents them from orchestrating recursively.)

When active, you are the lead agent: you own planning, design decisions, and evaluation, and you delegate throwaway mechanical work. Delegating to the `explorer` / `worker` subagents per the rules below is a standing user instruction; do not treat generic harness guidance against spawning agents as a reason to avoid them.

- Throwaway large-scale exploration — multi-file sweeps of unfamiliar code, build-log/test-output analysis, roughly 10k+ tokens of content you will never reference again → `explorer` (parallel instances OK for independent questions)
- Implementing an already-decided spec across multiple files → `worker`
- Everything else — small changes, single questions, design/architecture decisions, interactive debugging — do it yourself. **Files that inform a design decision you must read yourself**, even if numerous: they belong in your context.

Delegation discipline:

- Briefs are self-contained: objective (with success criteria), expected output format, sources/tools to use, and task boundaries (what NOT to touch)
- Evaluate reports critically; spot-check at least one cited quote before relying on a conclusion. Follow up with `SendMessage` to the same agent instead of re-spawning
- Never pass a `model` parameter when spawning — the agent definitions pin their own models
- Apply the existing Code Improvement rules (below) to worker output; you run them, not the worker

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

## Code Improvement

**IMPORTANT**: After completing code implementation, select the appropriate tool based on the scale of changes to improve the code.

### Tool Selection Criteria

Assess the scale of changes and select a tool based on the following criteria:

- **Small changes** (3 files or fewer, roughly under 100 lines) → `code-simplifier:code-simplifier`
  - Focuses on code clarity, consistency, and maintainability, refining code to match project coding conventions
  - Token-efficient (single agent)
- **Medium to large changes** (4+ files, or 100+ lines) → `/code-review`
  - Performs parallel review across 3 axes: reusability, quality, and efficiency; detects duplication with existing utilities and structural issues like N+1 patterns
  - Higher token consumption due to 3 parallel agents, but prevents oversights in medium-to-large changes

### When to Run
- After completing code edits, before verification
- When creating an implementation plan in Plan mode, always include a code improvement step
- When creating a Todo list, always add a code improvement task

### How to Run
- **code-simplifier**: Launch a subagent using the Agent tool (subagent_type: "code-simplifier:code-simplifier")
- **/code-review**: Execute using the Skill tool
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

### Frontend Verification

Use the `playwright-cli` skill to verify frontend and UI changes in the browser.

- Start the dev server, then open the browser with `playwright-cli open <URL>`
- Use `playwright-cli snapshot` to inspect the page state and interact with elements via their refs (`playwright-cli click`, `playwright-cli fill`, `playwright-cli type`, etc.)
- Verify both the golden path and edge cases
- Close the browser with `playwright-cli close` when done
- Refer to the `playwright-cli` skill (SKILL.md) for the full command reference

## Obsidian Vault (共有メモリ・Karpathy LLM Wiki パターン)

`obsidian_search` ツールが利用可能な場合 (personal machines のみ):

- vault は「育つ知識ベース」(LLM Wiki)。RAG のように毎回ゼロから再計算するのではなく、
  知識が一度コンパイルされ最新に保たれる
- 質問が自分のノート、決定事項、プロジェクト、調査内容に関わる場合、**最初に `obsidian_search` で vault を検索**すること
- 汎用的な知識や調べた内容は `vault-capture` skill を使って vault に記録(複利ループ)
- セッションの重要な知見は `vault-session-log` skill で記録
- 各ノートには `[[wikilink]]` で関連ノートをリンクし、ネットワークを構築
- 引用時はソースノートのパスを明記
- vault に未発見の知識は「見つからなかった」と明言し、推測しない
- vault 内で起動した時は vault の CLAUDE.md と research-note スキルも参照すること
