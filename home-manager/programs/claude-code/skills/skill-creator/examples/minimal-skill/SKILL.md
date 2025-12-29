---
name: Git Commit Guidelines
description: This skill should be used when the user asks to "write a commit message", "format commit", "commit message style", or needs guidance on conventional commit format.
---

# Git Commit Guidelines

This skill provides guidance for writing conventional commit messages.

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

| Type | Description |
|------|-------------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation only |
| style | Formatting, no code change |
| refactor | Code change, no feature/fix |
| test | Adding tests |
| chore | Maintenance tasks |

## Rules

1. Subject line max 50 characters
2. Use imperative mood ("Add feature" not "Added feature")
3. No period at end of subject
4. Blank line between subject and body
5. Body explains what and why, not how

## Examples

**Good:**
```
feat(auth): add OAuth2 login support

Implement Google and GitHub OAuth providers.
Closes #123
```

**Bad:**
```
Updated the login page to support OAuth
```

## Quick Reference

- `feat`: New functionality for users
- `fix`: Bug fix for users
- `docs`: Documentation changes
- `refactor`: Code restructuring
- `test`: Test additions/changes
- `chore`: Build, CI, dependencies
