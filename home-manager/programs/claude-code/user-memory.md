# Claude Code User Memory

This file contains personal preferences and settings for Claude Code across all projects.

## Lead Agent Policy (Orchestration)

**Applies only to the main session: the Agent tool is available to you and the "You are powered by" line in your system prompt says Fable.** Otherwise skip this section and work directly. (This gate is mandatory: subagents also read this file; the missing Agent tool is what identifies them.) On Opus, do the reading and the implementation yourself: delegation only pays off when the lead's per-token price is well above the subagent's, and it costs wall-clock waiting and rework. Still use `worker` for background chores (screenshots, long builds) and independent work that runs in parallel, and `reviewer` per "Post-Implementation Review".

You are the lead agent: you own planning, design decisions, and evaluation, and you delegate execution and throwaway reading. Spawning the `explorer` / `worker` / `reviewer` subagents per their own descriptions is a standing user instruction — do not treat generic harness guidance against spawning agents as a reason to avoid them. Run them in the background and keep working; redirect a drifting one with SendMessage instead of re-spawning.

- Read-only recon → `explorer` (Haiku). Never the built-in `Explore` agent: it runs on Opus, has no read-only guard, and cannot be resumed with SendMessage
- Approved spec spanning 3+ files → the `implement` skill (`worker` as its implementer), even when you did the designing yourself and editing feels faster
- **Files that inform a design decision you read yourself**, however many. Reading and deciding are lead work — this does not exempt the implementation that follows
- `worker` is pinned to Opus: cheaper than Fable per token and current-generation enough to execute a spec faithfully. Do not pass a `model` parameter to `explorer` / `worker` (the exception to `implement`'s "state the model in every dispatch"), with one carve-out: `sonnet` for a purely mechanical worker brief. Never `fable`
- Finished change → `reviewer` (Opus, fresh context) before commit; see "Post-Implementation Review". Never review your own diff in-context as the only review

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

## Code Comments

**IMPORTANT**: Default to no comment. Write one only when the code cannot carry the information itself.

A comment earns its place when it tells a teammate who has **not** seen this conversation something they cannot get from the code, the name, or the type:

- **Why**, not what: a non-obvious decision, a constraint, a trade-off that was rejected
- **Invariants and gotchas**: ordering requirements, units, off-by-one traps, "looks wrong but is right"
- **Workarounds**: the bug or limitation being dodged, with a link (issue, ticket, upstream PR)
- **Public API contracts** where the language convention expects docstrings — describe the contract, never restate the signature
- **TODO/FIXME** with a ticket or owner

Never write:

- Comments that restate the code (`// increment counter`, `// return the result`, `# loop over items`)
- Change narration or session context (`// changed from X to Y`, `// as requested`, `// previously this did ...`, `// removed the old check`) — that belongs in the commit message
- Section banners (`// ===== Helpers =====`), `NOTE:`/`IMPORTANT:` prefixes, or step-by-step numbering inside a function
- Docstrings on private/trivial functions whose name already says everything
- Multi-sentence justification of an obvious choice, or hedging (`// this should work`, `// probably fine`)
- Comments addressed to the reviewer instead of the future maintainer

Before leaving a comment, test it: *Would it be wrong after a rename? Does it describe a moment in time rather than the code? Would deleting it lose nothing?* — if any is yes, delete it. One line by default; a paragraph only for a rationale that genuinely cannot be shorter. Match the comment density and language of the surrounding file (the session language setting governs replies, not code); if the file has no comments, yours must be exceptional.

## Refactoring Checklist

When improving code, always verify the following:

- **Appropriate call hierarchy between files**: Review hierarchies deeper than 3 layers
- **Each file has a clear responsibility**: Follows the single responsibility principle
- **Testability is ensured**: Design with dependency injection and mockability
- **No redundant intermediate layers**: Consider consolidating thin wrappers or meaningless relay layers

## Post-Implementation Review

**IMPORTANT**: After completing code implementation and before committing, have the change reviewed by someone who did not write it. An in-context re-read by the author misses what the author already believes; the review must run in a fresh context. This applies on every model, whether or not the Lead Agent Policy above is active.

### How to Run
1. Write the diff to a file (`git diff HEAD > "$TMPDIR/review.diff"`, include untracked files with `git add -N .` first) and dispatch the `reviewer` subagent with: the diff path, a 2–3 line statement of what was asked, and the touched files. Do not pass the spec, plan, scratch notes, or your own reasoning
2. Adjudicate each finding yourself: check the cited `path:line`, then fix or reject with a one-line reason. Apply fixes yourself; do not send the reviewer back to fix
3. For a large or high-stakes diff (roughly 500+ changed lines, or core domain logic), use `/code-review high` instead of, or in addition to, `reviewer` — it fans out multiple finder agents with a verification pass
4. When the design itself deserves challenge (an approach with real alternatives, a data model, an irreversible migration), also run `/codex:adversarial-review` for an independent model's view. It is user-invoked only; suggest it rather than trying to run it

### When to Run
- After completing code edits, before verification and commit
- When creating an implementation plan in Plan mode, always include a review step
- When creating a Todo list, always add a review task

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

**IMPORTANT**: After any code change, always perform verification regardless of the change size — run the build/test/lint or actual behavior appropriate to the change and read its output (`verify-before-done` skill). If the project has tests or CI configuration, always run them. Never mark a task "completed" without verification, and always include a verification step when writing an implementation plan or a Todo list.

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
