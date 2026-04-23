---
description: Generate an OpenSpec proposal.md for a change by exploring the codebase
argument-hint: (no arguments - reads from workflow artifacts)
---

# Generate OpenSpec Proposal

**Workflow ID**: $WORKFLOW_ID

---

## Phase 1: LOAD

1. Read `$ARTIFACTS_DIR/change-dir.txt` to get the change directory path
2. Read `$ARTIFACTS_DIR/change-description.txt` to get the user's change description

Store these values — you'll need them throughout.

## Phase 2: EXPLORE

Analyze the codebase to deeply understand the context for this change:

1. **Project structure** — Use Glob and LS to understand the directory layout
2. **Relevant code** — Use Grep and Read to find code related to the change description
3. **Existing specs** — Check if `openspec/specs/` has any existing spec files (read them if so)
4. **Dependencies** — Identify which files, modules, and interfaces will be affected
5. **Patterns** — Note existing conventions, patterns, and testing approaches

Be thorough. The quality of the proposal depends on understanding the codebase.

### PHASE_2_CHECKPOINT
- [ ] Project structure understood
- [ ] Relevant code identified and read
- [ ] Existing specs checked
- [ ] Impact areas identified

## Phase 3: GENERATE

Write `proposal.md` to the change directory using the Write tool.

Follow this structure:

```markdown
# Proposal: <Change Name>

## Intent

What problem are we solving? Why does this matter? Who benefits?
Be specific — describe the observable pain, not just the assumed need.

## Current State

How does the system work today in the areas this change affects?
Reference specific files, modules, and behavior you discovered during exploration.

## Proposed Change

What specifically will change? Be concrete about the modifications:
- What will be added
- What will be modified
- What will be removed (if anything)

## Scope

### In Scope
- Specific deliverables and behaviors included in this change

### Out of Scope
- Items explicitly excluded to prevent scope creep
- Future work that could follow but is not part of this change

## Approach

High-level strategy for implementing this change.
Reference the actual codebase patterns and conventions you discovered.

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ... | Low/Medium/High | Low/Medium/High | ... |

## Success Criteria

How will we know this change is successful? List observable, verifiable outcomes.
```

### PHASE_3_CHECKPOINT
- [ ] proposal.md written to the change directory
- [ ] Intent clearly stated with concrete problem description
- [ ] Current state references actual codebase findings
- [ ] Scope boundaries defined (in-scope and out-of-scope)
- [ ] Approach grounded in actual codebase patterns
- [ ] Risks identified with mitigations
- [ ] Success criteria are verifiable

## Phase 4: REPORT

Provide a concise summary of the proposal:
- The problem being solved
- The approach chosen
- Key scope decisions
- Top risks

This output will be available to downstream nodes.
