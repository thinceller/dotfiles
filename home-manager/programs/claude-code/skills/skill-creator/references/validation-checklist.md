# Skill Validation Checklist

This document provides a comprehensive checklist for validating Claude Code skills before deployment.

## Structure Validation

- [ ] `SKILL.md` exists in skill directory
- [ ] YAML frontmatter starts on line 1 with `---`
- [ ] Frontmatter ends with `---`
- [ ] `name` field is present (max 64 characters, title case)
- [ ] `description` field is present (max 1024 characters)
- [ ] All files referenced in SKILL.md exist
- [ ] No broken links to references/, examples/, or scripts/

## Description Quality

- [ ] Uses third person ("This skill should be used when...")
- [ ] Includes 3-5 specific trigger phrases in quotes
- [ ] Lists concrete scenarios ("create X", "configure Y", "troubleshoot Z")
- [ ] Not vague or generic
- [ ] Under 1024 characters

### Good Description Examples

```yaml
description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook", "validate tool use", or mentions hook events (PreToolUse, PostToolUse, Stop).
```

```yaml
description: This skill should be used when the user asks to "process PDF files", "extract PDF text", "fill PDF forms", or needs guidance on PDF manipulation.
```

### Bad Description Examples

```yaml
# Too vague, no trigger phrases
description: Helps with hooks.

# Not third person
description: Use this skill when working with hooks.

# No specific triggers
description: Provides guidance for document processing.
```

## Content Quality

- [ ] SKILL.md body uses imperative/infinitive form (verb-first)
- [ ] No second person ("You should...", "You need to...")
- [ ] Body is focused (target 1,500-2,000 words, max 5,000)
- [ ] Detailed content moved to references/ if SKILL.md exceeds 3,000 words
- [ ] Examples are complete and working
- [ ] Scripts are executable with proper shebang

### Writing Style Examples

**Correct (imperative form):**
```markdown
Create the directory structure first.
Validate the frontmatter before deployment.
Include specific trigger phrases in descriptions.
```

**Incorrect (second person - avoid):**
```markdown
You should create the directory structure first.
You need to validate the frontmatter.
You must include trigger phrases.
```

## Progressive Disclosure

- [ ] Core concepts in SKILL.md (always loaded)
- [ ] Detailed documentation in references/ (loaded on demand)
- [ ] Working examples in examples/ (loaded on demand)
- [ ] Utility scripts in scripts/ (executed, not loaded)
- [ ] SKILL.md explicitly references these resources

## Testing Checklist

- [ ] Skill triggers on expected user queries
- [ ] Skill does NOT trigger on unrelated queries
- [ ] Content is helpful for intended tasks
- [ ] No duplicated information across files
- [ ] References load when Claude determines they're needed

### Test Queries Template

For a skill named "my-skill", test with:
1. Direct triggers: "Help me create a my-skill", "I need my-skill guidance"
2. Indirect triggers: Related domain questions
3. Negative tests: Unrelated queries should NOT trigger the skill

## Common Skill Types

### Minimal Skill (knowledge only)

```
skill-name/
└── SKILL.md
```

**Use when:**
- Simple domain knowledge
- No complex workflows
- Under 2,000 words total

### Standard Skill (with references)

```
skill-name/
├── SKILL.md
└── references/
    └── detailed-guide.md
```

**Use when:**
- Detailed documentation needed
- Multiple workflows or patterns
- 2,000-5,000 words total

### Complete Skill (with utilities)

```
skill-name/
├── SKILL.md
├── references/
│   ├── patterns.md
│   └── advanced.md
├── examples/
│   └── working-example.sh
└── scripts/
    └── validate.sh
```

**Use when:**
- Complex domain with validation needs
- Reusable scripts benefit users
- Extensive documentation required

## Quick Validation Commands

Check skill structure:
```bash
# List skill contents
ls -la .claude/skills/skill-name/

# Check frontmatter
head -20 .claude/skills/skill-name/SKILL.md

# Count words in SKILL.md body
tail -n +5 .claude/skills/skill-name/SKILL.md | wc -w
```

## Common Mistakes

### 1. Weak Trigger Description

**Problem:** Vague description with no specific trigger phrases
**Solution:** Add 3-5 quoted trigger phrases users would actually say

### 2. Too Much in SKILL.md

**Problem:** SKILL.md over 3,000 words, context bloat
**Solution:** Move detailed content to references/

### 3. Second Person Writing

**Problem:** "You should...", "You need to..." throughout
**Solution:** Use imperative form: "Create...", "Validate...", "Include..."

### 4. Missing Resource References

**Problem:** references/ exists but SKILL.md doesn't mention it
**Solution:** Add "Additional Resources" section with explicit file references

### 5. Incomplete Examples

**Problem:** Examples missing imports, error handling, or context
**Solution:** Provide complete, runnable examples
