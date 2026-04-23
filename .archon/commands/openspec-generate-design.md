---
description: Generate OpenSpec technical design document
argument-hint: (no arguments - reads from workflow artifacts)
---

# Generate OpenSpec Technical Design

**Workflow ID**: $WORKFLOW_ID

---

## Phase 1: LOAD

1. Read `$ARTIFACTS_DIR/change-dir.txt` to get the change directory path
2. Read `proposal.md` from the change directory — this defines the approach
3. Read `$ARTIFACTS_DIR/change-description.txt` for the original request

### PHASE_1_CHECKPOINT
- [ ] Change directory path loaded
- [ ] Proposal read and understood

## Phase 2: EXPLORE

Deep-dive into the technical landscape relevant to the proposed change:

1. **Architecture** — Understand how the codebase is structured
   - Directory layout, module boundaries, package dependencies
   - Key abstractions, interfaces, and patterns in use
2. **Affected files** — Identify specific files that will need to change
   - Use Grep and Glob to find relevant code
   - Read the files to understand current implementation
3. **Integration points** — Where does this change touch other parts of the system?
   - Imports/exports, API contracts, database schemas
   - Shared state, event systems, messaging
4. **Testing patterns** — How are similar features tested?
   - Test frameworks, test file conventions, test utilities
5. **Performance considerations** — Any hot paths or bottlenecks to watch?

### PHASE_2_CHECKPOINT
- [ ] Architecture patterns understood
- [ ] Specific files to modify identified and read
- [ ] Integration points mapped
- [ ] Testing patterns noted

## Phase 3: GENERATE

Write `design.md` to the change directory using the Write tool.

Follow this structure:

```markdown
# Technical Design: <Change Name>

## Overview

Brief technical summary of the approach (2-3 sentences).

## Architecture

### Current State

How the system is structured today in the affected areas.
Include specific file paths and module relationships.

### Target State

How the system will look after this change.
Describe the structural changes clearly.

## Implementation Details

### Components to Create

| Component | Location | Purpose |
|-----------|----------|---------|
| <name> | `<file-path>` | <what it does> |

### Components to Modify

| Component | Location | Change |
|-----------|----------|--------|
| <name> | `<file-path>` | <what changes> |

### Data Flow

Describe how data flows through the system with this change.
If complex, use a step-by-step description:

1. User triggers <action>
2. <Component A> receives and validates
3. <Component B> processes
4. Result is returned via <mechanism>

## API / Interface Changes

Any new or modified:
- Public APIs or routes
- TypeScript interfaces or types
- Database schema changes
- Configuration changes

## Testing Strategy

### Unit Tests
- What to test and where

### Integration Tests
- What to test and where

### Manual Validation
- Steps to manually verify the change works

## Migration / Rollback

- **Deploy**: How to ship this change safely
- **Rollback**: How to revert if something goes wrong

## Open Questions

Any unresolved technical decisions that may need discussion.
```

### PHASE_3_CHECKPOINT
- [ ] design.md written to the change directory
- [ ] Components mapped with actual file paths from the codebase
- [ ] Data flow clearly described
- [ ] Testing strategy defined using the project's existing patterns
- [ ] API/interface changes documented
- [ ] Rollback approach considered

## Phase 4: REPORT

Summarize the technical approach:
- Key design decisions made
- Number of files to create vs modify
- Any open questions that need resolution
