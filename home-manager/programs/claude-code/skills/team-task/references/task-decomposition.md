# Task Decomposition Guide

Patterns and guidelines for breaking complex requests into well-structured parallel tasks.

## File Ownership Strategy

### Core Rule

Each task MUST own a distinct set of files. Two tasks must never modify the same file concurrently.

### Handling Shared Files

Some files are naturally shared across tasks (type definitions, configuration, constants). Handle these with a dedicated task:

```
Task 1: "Define shared types" (types.ts)
  ↓ blocks
Task 2: "Implement module A" (moduleA.ts) -- uses types from types.ts
Task 3: "Implement module B" (moduleB.ts) -- uses types from types.ts
```

### File Splitting Strategies

When a single file needs changes from multiple tasks:

1. **Extract shared code first**: Create a task that extracts shared interfaces/types into a separate file. Block implementation tasks on it.
2. **Sequential ownership**: If extraction is impractical, assign the file to one task and make the other depend on it.
3. **Never split a file between concurrent tasks**: This guarantees merge conflicts.

## Dependency Patterns

### Linear

Tasks execute one after another. Use when each task builds on the previous output.

```
Task 1 → Task 2 → Task 3 → Review → QA
```

Best for: Sequential refactoring, migration scripts, ordered feature buildout. Minimal parallelism -- consider whether a team is warranted.

### Fan-out

One task produces output consumed by many parallel tasks.

```
        ┌→ Task 2a ─┐
Task 1 ─┼→ Task 2b ─┼→ Review → QA
        └→ Task 2c ─┘
```

Best for: Interface-first design where a planner defines contracts and coders implement against them.

### Diamond

Fan-out followed by convergence. Multiple parallel tasks feed into a single integration task.

```
        ┌→ Task 2a ─┐
Task 1 ─┤           ├→ Task 3 → Review → QA
        └→ Task 2b ─┘
```

Best for: Feature implementation where components are built in parallel then integrated.

### Fan-out with Independent Review

Each parallel track has its own review, then a final QA pass.

```
        ┌→ Task 2a → Review 2a ─┐
Task 1 ─┤                       ├→ QA
        └→ Task 2b → Review 2b ─┘
```

Best for: Large changes where reviewing all at once would be overwhelming.

## Task Size Guidelines

### Good Size

- **Implement user login endpoint**: 2-3 files (route, controller, tests). Clear acceptance criteria. Testable outcome.
- **Add validation to order form**: One component and its test file. Well-scoped.
- **Refactor database queries to use connection pool**: 3-4 repository files following the same pattern.

### Too Small

- **Add an import statement**: Not worth the overhead of a separate task.
- **Rename a variable**: Single-line change. Handle inline.
- **Add a type annotation**: Trivial. Fold into a larger task.

### Too Large

- **Implement the entire authentication system**: Covers registration, login, sessions, password reset, OAuth. Break into 4-6 tasks.
- **Refactor the codebase**: Unbounded scope. Define specific goals and split each into a task.
- **Build the frontend**: Entire application layer. Decompose by page or feature.

### Sizing Heuristic

A well-sized task should:
- Touch **1-5 files**
- Have **3 or fewer** acceptance criteria
- Be describable in **2-3 sentences**
- Produce a **testable, verifiable** result

## Anti-patterns

### 1. Over-decomposition

**Problem**: So many small tasks that coordination overhead exceeds the work itself.

```
# Bad: 10 tasks for what should be 3
Task: Create types file
Task: Add User type
Task: Add Session type
Task: Create login function signature
Task: Implement login function body
...
```

**Fix**: Combine related micro-tasks into meaningful units of work.

### 2. Monolithic Tasks

**Problem**: A single task does too much, eliminating parallelism.

```
# Bad
Task: Implement authentication (login, registration, password reset, session management, tests)
```

**Fix**: Split by logical boundary. Each subtask should be independently implementable and testable.

### 3. File Ownership Violations

**Problem**: Two tasks modify the same file concurrently.

```
# Bad: Both tasks modify api/routes.ts
Task A: Add user routes (modifies api/routes.ts, controllers/user.ts)
Task B: Add order routes (modifies api/routes.ts, controllers/order.ts)
```

**Fix**: Restructure so each task touches distinct files:

```
# Good: Separate route files
Task A: Add user routes (routes/user.ts, controllers/user.ts)
Task B: Add order routes (routes/order.ts, controllers/order.ts)
Task C: Register route modules in api/routes.ts (blocked by A, B)
```

### 4. Missing Dependencies

**Problem**: Tasks consume outputs from other tasks without `blockedBy` relationships.

```
# Bad: Task B uses types from Task A but isn't blocked
Task A: Define API types
Task B: Implement API client (uses types from Task A) -- no blockedBy!
```

**Fix**: Always add `blockedBy` when one task's output is another task's input.

### 5. Review/QA Not Blocked

**Problem**: Review or QA tasks run before implementation is complete.

```
# Bad: Review runs in parallel with implementation
Task: Implement feature
Task: Review feature -- no blockedBy!
```

**Fix**: Review and QA tasks MUST be blocked by all implementation tasks they evaluate.

## Worked Example

### Request

> "Add a comments feature to the blog. Users should be able to create, read, and delete comments on blog posts. Include API endpoints and frontend components."

### Decomposition

**Task 1: Define comment types and database schema** (no blockers)
- Files: `src/types/comment.ts`, `prisma/schema.prisma`
- Acceptance criteria:
  - Comment type includes id, postId, authorId, content, createdAt
  - Prisma schema has Comment model with relations to Post and User

**Task 2: Implement comment API endpoints** (blocked by Task 1)
- Files: `src/routes/comments.ts`, `src/controllers/commentController.ts`, `src/services/commentService.ts`
- Acceptance criteria:
  - POST /posts/:postId/comments -- create comment
  - GET /posts/:postId/comments -- list comments for post
  - DELETE /comments/:id -- delete comment (author only)

**Task 3: Implement comment frontend components** (blocked by Task 1)
- Files: `src/components/CommentList.tsx`, `src/components/CommentForm.tsx`, `src/components/CommentItem.tsx`
- Acceptance criteria:
  - CommentList fetches and displays comments for a post
  - CommentForm allows creating a new comment
  - CommentItem shows comment with delete button for the author

**Task 4: Add API integration to frontend** (blocked by Tasks 2, 3)
- Files: `src/api/comments.ts`, `src/hooks/useComments.ts`
- Acceptance criteria:
  - API client functions for create, list, delete
  - useComments hook manages state and API calls

**Task 5: Write API tests** (blocked by Task 2)
- Files: `tests/api/comments.test.ts`
- Acceptance criteria:
  - Tests for create, list, delete endpoints
  - Tests for authorization (only author can delete)
  - Tests for validation (empty content, invalid postId)

**Task 6: Write component tests** (blocked by Task 3)
- Files: `tests/components/CommentList.test.tsx`, `tests/components/CommentForm.test.tsx`
- Acceptance criteria:
  - Tests for rendering, user interaction, loading states

**Task 7: Code review** (blocked by Tasks 2, 3, 4, 5, 6)
- Review all implementation and test changes

**Task 8: QA verification** (blocked by Task 7)
- Run full test suite, verify build, check integration

### Dependency Graph

```
Task 1 (types/schema)
  ├→ Task 2 (API) ──→ Task 5 (API tests) ────┐
  ├→ Task 3 (components) → Task 6 (comp tests)├→ Task 7 (review) → Task 8 (QA)
  └→ Task 2 + Task 3 ──→ Task 4 (integration) ┘
```

### Team Composition

- **coder-backend**: Tasks 1, 2, 5 (subagent_type: general-purpose)
- **coder-frontend**: Tasks 3, 4, 6 (subagent_type: general-purpose)
- **code-reviewer**: Task 7 (subagent_type: general-purpose)
- **qa**: Task 8 (subagent_type: general-purpose)

Total: 4 teammates, 8 tasks, clear ownership boundaries, no file conflicts.
