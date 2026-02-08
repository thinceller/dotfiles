---
name: team-task
description: Decompose complex tasks into parallel subtasks executed by a coordinated team of specialized agents. Use when asked to "create a team", "spawn teammates", "work in parallel", or similar.
disable-model-invocation: true
---

# Team Task

Decompose complex tasks into parallel subtasks and execute them using a coordinated team of specialized agents with mandatory code review and QA.

## Prerequisites

Create a team only when:

- The task involves **3 or more independent subtasks** that can run in parallel
- Multiple files or modules need changes simultaneously
- The task benefits from **specialized roles** (e.g., research + implementation + testing)

Do NOT create a team for single-file changes, inherently sequential tasks, or simple research.

## Phase 1 - Request Analysis

Analyze the user's request to determine:

1. **Scope**: What files, modules, or systems are affected?
2. **Nature**: Is this a new feature, refactor, bug fix, or research task?
3. **Parallelism**: Which parts can run independently vs. which have dependencies?
4. **Risks**: Are there shared files or interfaces that could cause conflicts?

Summarize the analysis before proceeding. If the scope is unclear, ask the user for clarification.

## Phase 2 - Task Decomposition

Break the request into discrete tasks following these rules:

### File Ownership

- Each task MUST own a distinct set of files. No two tasks should modify the same file.
- If a shared file needs changes, create a dedicated task for it and block dependent tasks on it.

### Granularity

- Each task should represent **1-3 hours of focused work** -- large enough to be meaningful, small enough to be reviewable.
- Prefer tasks that produce a testable, verifiable outcome.

### Dependencies

- Define explicit `blockedBy` relationships using TaskUpdate.
- Tasks that consume interfaces or types from other tasks MUST be blocked by those tasks.
- Review and QA tasks MUST be blocked by all implementation tasks they evaluate.

For detailed decomposition patterns and examples, see **`references/task-decomposition.md`**.

## Phase 3 - Team Composition

### Mandatory Rule

**When any coding teammate exists, ALWAYS create both a `code-reviewer` and a `qa` teammate.** This is non-negotiable.

### Available Roles

| Role | Subagent Type | Purpose |
|------|---------------|---------|
| coder | `general-purpose` | Implement features, fix bugs, write code |
| code-reviewer | `general-purpose` | Review changes for correctness, style, and architecture |
| qa | `general-purpose` | Run tests, verify builds, validate integration |
| researcher | `Explore` | Investigate codebase, gather context, analyze patterns |
| planner | `Plan` | Design interfaces, define module boundaries, create specs |

### Team Size Guidelines

- **Small** (1-2 coding tasks): 1 coder + 1 code-reviewer + 1 qa = **3 teammates**
- **Medium** (3-4 coding tasks): 2-3 coders + 1 code-reviewer + 1 qa = **4-5 teammates**
- **Large** (5+ coding tasks): 3-4 coders + 1 code-reviewer + 1 qa + optional researcher/planner = **5-7 teammates**
- **Maximum**: 8 teammates. If more seem needed, reduce task granularity.

### When to Spawn Optional Roles

- **researcher**: When the codebase is unfamiliar or the task requires understanding existing patterns first. Block coding tasks on the researcher's output.
- **planner**: When interface design or architectural decisions are needed before coding. Block coding tasks on the planner's output.

For spawn prompt templates, see **`references/role-templates.md`**.

## Phase 4 - Team Creation

Execute these steps in order:

### 1. Create the Team

Use TeamCreate with a descriptive `team_name` (e.g., `auth-feature`, `api-refactor`).

### 2. Create All Tasks

Use TaskCreate for each task with:
- `subject` in imperative form
- `description` with acceptance criteria, target files, and constraints
- `activeForm` in present continuous tense

### 3. Set Dependencies

Use TaskUpdate with `addBlockedBy`:
- Research/planning tasks: no blockers (run first)
- Implementation tasks: blocked by research/planning if applicable
- Review tasks: blocked by all implementation tasks they review
- QA tasks: blocked by all implementation tasks they verify

### 4. Spawn Teammates

Use the Task tool to spawn each teammate with `team_name`, `name`, `subagent_type`, and `prompt` (see `references/role-templates.md`). Spawn in parallel when possible.

### 5. Assign Initial Tasks

Use TaskUpdate with `owner` to assign unblocked tasks. Teammates will also self-assign when idle.

## Phase 5 - Coordination

### Communication

- Use **SendMessage** `type: "message"` for direct communication with individuals.
- Use **SendMessage** `type: "broadcast"` only for critical team-wide announcements. Broadcasting is expensive -- prefer direct messages.
- When a teammate goes idle, check TaskList for newly unblocked tasks and assign them.

### Progress Monitoring

- After each teammate message, check TaskList to assess progress.
- If a teammate is blocked, provide guidance via SendMessage or reassign the task.
- If new tasks emerge, create them with TaskCreate and set dependencies.

### Conflict Resolution

- If two teammates need to modify the same file, restructure tasks to eliminate the conflict.
- If an unplanned dependency is discovered, add it with TaskUpdate `addBlockedBy` before the dependent task starts.

## Phase 6 - Review and QA

### Review Process

1. When implementation tasks complete, the code-reviewer's tasks become unblocked.
2. The reviewer checks correctness, conventions, architecture, and test coverage.
3. If issues are found, create fix tasks assigned to the original coder and a re-review task blocked by fixes.

### QA Process

1. When implementation and review fixes complete, QA tasks become unblocked.
2. QA runs test suites, build verification, and integration checks.
3. If failures are found, create fix tasks and a re-verification task blocked by fixes.

### Iteration

Repeat the review-fix-recheck cycle until both code-reviewer and QA approve. Only proceed to shutdown after all tasks are completed.

## Phase 7 - Shutdown

1. Verify all tasks in TaskList are completed.
2. Send `shutdown_request` to each teammate via SendMessage.
3. Wait for shutdown confirmations.
4. Call TeamDelete to clean up.
5. Report to the user: what was accomplished, files changed, and any issues resolved.

## Error Recovery

### Teammate Not Responding

1. Send a follow-up message asking for status.
2. Check if their assigned task is blocked.
3. As a last resort, reassign the task or handle it directly.

### File Conflicts

1. Pause both teammates via SendMessage.
2. Determine which changes take priority.
3. Have one teammate revert and rebase on the other's work.
4. Restructure remaining tasks to prevent recurrence.

### Build Failures

1. Identify which task caused the failure.
2. Create a fix task assigned to the responsible coder.
3. Block the QA re-verification task on the fix.
4. Do not shut down until the build is green.

### Scope Changes

1. Broadcast the change to all teammates.
2. Pause affected in-progress tasks.
3. Re-decompose affected portions and create new tasks.
4. Update dependencies as needed.
