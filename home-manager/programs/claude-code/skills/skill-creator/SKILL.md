---
name: skill-creator
description: This skill should be used when the user asks to "create a skill", "add a new skill", "write a skill", "make a skill", "skill template", "scaffold a skill", "skill directory structure", "SKILL.md format", "skill frontmatter", or needs guidance on skill structure, trigger descriptions, progressive disclosure, or skill validation for Claude Code.
---

# Skill Creator

This skill provides guidance for creating Claude Code skills.

## Quick Start

1. Create directory: `.claude/skills/<skill-name>/`
2. Create `SKILL.md` with YAML frontmatter and markdown body
3. Optionally add `references/`, `examples/`, or `scripts/` subdirectories

## Skill Location

- **User-level**: `~/.claude/skills/` (available across all projects)
- **Project-level**: `<project>/.claude/skills/` (project-specific)

## Directory Structure

```
skill-name/
├── SKILL.md           # Required: metadata + core instructions
├── references/        # Optional: detailed documentation
├── examples/          # Optional: working examples
└── scripts/           # Optional: utility scripts
```

## SKILL.md Structure

### YAML Frontmatter (Required)

```yaml
---
name: Skill Name
description: This skill should be used when the user asks to "phrase 1", "phrase 2", "phrase 3", or needs guidance on specific-topic.
---
```

**Constraints:**
- `name`: Max 64 characters, title case
- `description`: Max 1024 characters, third-person, include specific trigger phrases

### Markdown Body (Required)

Write in imperative/infinitive form:

```markdown
# Correct
Create the directory structure first.
Validate the frontmatter before deployment.

# Incorrect (avoid second person)
You should create the directory structure first.
You need to validate the frontmatter.
```

## Skill Creation Workflow

### Step 1: Define Purpose and Triggers

Answer before creating:
- What tasks will this skill help with?
- What phrases would trigger this skill? (3-5 examples)
- What resources (scripts, references, examples) would be helpful?

### Step 2: Create Directory Structure

```bash
mkdir -p .claude/skills/<skill-name>
```

Create subdirectories only as needed.

### Step 3: Write SKILL.md

1. **Frontmatter**: Name and description with trigger phrases
2. **Overview**: 1-2 sentences on skill purpose
3. **Core workflow**: Essential steps and procedures
4. **Resource references**: Pointers to bundled files

**Target length:** 1,500-2,000 words for the body. Move detailed content to `references/` if exceeding.

### Step 4: Test

Test with queries that should trigger the skill:
- "Help me create a [skill-topic]"
- "How do I [skill-action]?"

## Best Practices

**DO:**
- Use third-person in description ("This skill should be used when...")
- Include 3-5 specific trigger phrases in quotes
- Keep SKILL.md lean (1,500-2,000 words)
- Write body in imperative form
- Reference supporting files explicitly

**DON'T:**
- Use second person ("You should...")
- Have vague trigger conditions
- Put everything in SKILL.md (use references/)
- Leave resources unreferenced

## Additional Resources

### Reference Files

For detailed guidance, consult:
- **`references/validation-checklist.md`** - Complete validation checklist, common mistakes, skill types
- **`references/progressive-disclosure.md`** - When to split content, directory patterns, word count guidelines

### Example Skills

Working examples in `examples/`:
- **`minimal-skill/`** - Knowledge-only skill (~150 words)
- **`standard-skill/`** - Skill with references (~300 words + references)

### Comprehensive Reference

For extensive guidance including complete skill anatomy, advanced patterns, and script best practices, invoke the plugin skill:

```
/plugin-dev:skill-development
```
