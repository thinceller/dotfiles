# Progressive Disclosure in Skills

This document explains progressive disclosure patterns for efficient context management in Claude Code skills.

## Overview

Skills use a three-level loading system to manage context efficiently:

| Level | What | When Loaded | Target Size |
|-------|------|-------------|-------------|
| 1. Metadata | name + description | Always in context | ~100 words |
| 2. SKILL.md body | Core instructions | When skill triggers | 1,500-2,000 words |
| 3. Bundled resources | Detailed content | As needed by Claude | Unlimited* |

*Scripts can be executed without loading into context, making them effectively unlimited.

## When to Split Content

### Move to references/ when:

- Detailed patterns exceed 500 words
- API documentation or schemas are involved
- Migration guides or advanced techniques are needed
- Content is only needed for specific subtasks
- Multiple alternative approaches exist
- Historical context or deprecated patterns need documentation

### Keep in SKILL.md when:

- Core workflow steps
- Essential quick reference
- Common use cases
- Resource pointers (links to references/)
- Critical warnings or gotchas

## Directory Structure Patterns

### Pattern 1: High-level guide with references

```
my-skill/
├── SKILL.md (main, ~1,500 words)
├── references/
│   ├── api-reference.md    (detailed API docs)
│   ├── patterns.md         (common patterns)
│   └── troubleshooting.md  (error handling)
└── examples/
    └── complete-example.sh
```

SKILL.md references:
```markdown
## Additional Resources

For detailed information, consult:
- **`references/api-reference.md`** - Complete API documentation
- **`references/patterns.md`** - Common patterns and examples
- **`references/troubleshooting.md`** - Error handling guide
```

### Pattern 2: Domain-specific organization

```
database-skill/
├── SKILL.md
└── references/
    ├── schemas/
    │   ├── users.md
    │   ├── orders.md
    │   └── products.md
    └── queries/
        ├── analytics.md
        └── reports.md
```

SKILL.md references:
```markdown
## Database Schemas

Schema documentation in `references/schemas/`:
- **users.md** - User and authentication tables
- **orders.md** - Order processing tables
- **products.md** - Product catalog tables
```

### Pattern 3: Conditional details (show basic, link to advanced)

```markdown
## Creating Documents

Use basic API for simple documents. See examples in `examples/`.

**For tracked changes**: See `references/advanced-editing.md`
**For templates**: See `references/templates.md`
```

## Referencing Resources in SKILL.md

### Explicit File References

Always explicitly reference bundled resources:

```markdown
## Additional Resources

### Reference Files

For detailed patterns and techniques:
- **`references/patterns.md`** - Common implementation patterns
- **`references/advanced.md`** - Advanced techniques and edge cases

### Example Files

Working examples in `examples/`:
- **`complete-workflow.sh`** - End-to-end workflow example
- **`config-example.json`** - Configuration template

### Utility Scripts

Automation scripts in `scripts/`:
- **`validate.sh`** - Validate configuration files
- **`setup.sh`** - Initialize project structure
```

### Contextual References

Reference resources where relevant in the workflow:

```markdown
## Step 3: Configure Authentication

Set up authentication tokens. For detailed options, see `references/auth-guide.md`.

Basic configuration:
```json
{ "auth": "bearer", "token": "..." }
```
```

## Best Practices

### Keep References One Level Deep

Avoid deeply nested references:

**Good (one level):**
- SKILL.md → references/guide.md

**Avoid (nested):**
- SKILL.md → references/guide.md → references/sub-guide.md

Claude may read incompletely with deep nesting.

### Structure Long Reference Files

For files over 100 lines, include a table of contents:

```markdown
# API Reference

## Contents

- [Authentication](#authentication)
- [Core Methods](#core-methods)
- [Error Handling](#error-handling)
- [Advanced Features](#advanced-features)

## Authentication
...
```

### Scripts: Execute, Don't Load

Scripts should be executed, not read into context:

```markdown
## Validation

Run the validation script:
```bash
python scripts/validate.py input.json
```

The script output shows validation results.
```

This keeps the script code out of context while getting the benefits.

## Word Count Guidelines

| Content Type | Location | Target Words |
|--------------|----------|--------------|
| Core workflow | SKILL.md | 1,500-2,000 |
| Detailed patterns | references/ | 2,000-5,000 each |
| API reference | references/ | 3,000-10,000 |
| Examples | examples/ | Varies |
| Scripts | scripts/ | N/A (executed) |

## Anti-Patterns to Avoid

### 1. Everything in SKILL.md

**Problem:**
```
skill/
└── SKILL.md  (8,000 words)
```

**Solution:**
```
skill/
├── SKILL.md  (1,800 words)
└── references/
    ├── detailed-guide.md  (3,000 words)
    └── api-reference.md   (3,200 words)
```

### 2. Unreferenced Resources

**Problem:** Files exist in references/ but SKILL.md never mentions them

**Solution:** Add explicit references:
```markdown
## Additional Resources

- **`references/guide.md`** - Detailed implementation guide
```

### 3. Duplicated Content

**Problem:** Same information in both SKILL.md and references/

**Solution:** Keep core concepts in SKILL.md, detailed elaboration in references/. Never duplicate.

### 4. Vague Resource Descriptions

**Problem:**
```markdown
See references/ for more info.
```

**Solution:**
```markdown
For OAuth2 implementation details, see `references/oauth2-guide.md`.
For error handling patterns, see `references/error-handling.md`.
```
