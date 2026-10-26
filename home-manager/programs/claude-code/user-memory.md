# Claude Code User Memory

This file contains personal preferences and settings for Claude Code across all projects.

## Git Worktree Rules

**IMPORTANT**: When a session is started within a git worktree, all file exploration, reading, and editing MUST be performed within the worktree directory.

- Always use the CWD (current working directory) at session start as the project root
- To detect a worktree, check if `.git` is a file (not a directory) — this indicates a worktree
- NEVER resolve the git root from `.git` and operate on files there; stay within the CWD tree
- CLAUDE.md and other configuration files MUST be referenced and edited within the worktree

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

## Frontend Verification

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
