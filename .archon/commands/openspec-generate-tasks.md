---
description: Generate OpenSpec implementation task checklist
argument-hint: (no arguments - reads from workflow artifacts)
---

# Generate OpenSpec Implementation Tasks

**Workflow ID**: $WORKFLOW_ID

---

## Phase 1: LOAD

1. Read `$ARTIFACTS_DIR/change-dir.txt` to get the change directory path
2. Read `proposal.md` from the change directory — scope and approach
3. Read `design.md` from the change directory — technical plan and file paths
4. Read all spec files from `<change-dir>/specs/` — requirements to satisfy

### PHASE_1_CHECKPOINT
- [ ] All artifacts loaded
- [ ] Scope, design, and specs understood

## Phase 2: ANALYZE

Map the design and specs to concrete, ordered implementation tasks:

1. **Sequence dependencies** — What must be built first?
   - Core data structures and types before consumers
   - Database changes before application code
   - Utilities before features that use them
2. **Size tasks appropriately** — Each task should be:
   - Completable in one focused session (15-30 minutes of AI work)
   - Independently verifiable (you can check it works)
   - Small enough to produce a clean diff
3. **Include validation** — Each phase should end with verification:
   - Type-checking after structural changes
   - Tests after feature implementation
   - Integration checks after wiring things together
4. **Map to specs** — Every requirement in the specs should be covered by at least one task

## Phase 3: GENERATE

Write `tasks.md` to the change directory using the Write tool.

Follow this structure:

```markdown
# Implementation Tasks: <Change Name>

> Generated from proposal, specs, and design artifacts.
> Each task should be checked off `[x]` as it's completed during implementation.

## Phase 1: <Foundation / Setup / Core>

- [ ] 1.1 <Specific, actionable task description>
  - **Files**: `path/to/file.ts`
  - **Details**: What specifically to create or change
  - **Validates**: <which requirement this satisfies, if applicable>

- [ ] 1.2 <Specific, actionable task description>
  - **Files**: `path/to/file.ts`, `path/to/other.ts`
  - **Details**: What specifically to do
  - **Validates**: <requirement reference>

## Phase 2: <Feature Implementation>

- [ ] 2.1 <Specific, actionable task description>
  - **Files**: `path/to/file.ts`
  - **Details**: What specifically to do

- [ ] 2.2 <Specific, actionable task description>
  - **Files**: `path/to/file.ts`
  - **Details**: What specifically to do

## Phase 3: <Integration / Wiring>

- [ ] 3.1 <Specific, actionable task description>
  - **Files**: `path/to/file.ts`
  - **Details**: How components connect

## Phase 4: Testing & Validation

- [ ] 4.1 <Write unit tests for X>
  - **Files**: `path/to/file.test.ts`
  - **Details**: What scenarios to test

- [ ] 4.2 <Write integration tests for Y>
  - **Files**: `path/to/file.test.ts`
  - **Details**: What flows to test

- [ ] 4.3 Run full validation
  - **Details**: Run type-check, lint, and tests to verify everything passes
```

### Task Writing Rules

- **Be concrete** — "Add `ThemeContext` provider to `src/context/theme.tsx`" not "Add theme support"
- **Include file paths** — Reference actual files from the codebase where known
- **One concern per task** — Don't combine unrelated changes
- **Order by dependency** — Tasks within a phase can be done in order
- **Phases are sequential** — Phase 2 depends on Phase 1 completing
- **Always end with testing** — Include explicit test and validation tasks
- **Link to specs** — Use the "Validates" field to trace tasks back to spec requirements

### PHASE_3_CHECKPOINT
- [ ] tasks.md written to the change directory
- [ ] Tasks are concrete with file paths
- [ ] Tasks grouped into logical phases
- [ ] Dependencies flow correctly (no forward references)
- [ ] Testing and validation tasks included
- [ ] Every spec requirement is covered by at least one task

## Phase 4: REPORT

Summarize the implementation plan:
- Total number of tasks
- Number of phases
- Estimated complexity (small/medium/large)
- Confirm the change is ready for human review
