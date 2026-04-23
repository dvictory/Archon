---
description: Generate OpenSpec delta specifications with requirements and scenarios
argument-hint: (no arguments - reads from workflow artifacts)
---

# Generate OpenSpec Delta Specs

**Workflow ID**: $WORKFLOW_ID

---

## Phase 1: LOAD

1. Read `$ARTIFACTS_DIR/change-dir.txt` to get the change directory path
2. Read `proposal.md` from the change directory — this defines intent and scope
3. Check `openspec/specs/` for any existing spec files (source of truth)
   - If specs exist, read them to understand current behavior
   - Delta specs describe what's CHANGING relative to these

### PHASE_1_CHECKPOINT
- [ ] Change directory path loaded
- [ ] Proposal read and understood
- [ ] Existing specs checked

## Phase 2: ANALYZE

Based on the proposal:

1. **Identify affected domains** — Which areas of the system are touched?
   - Map each to a domain name (e.g., `auth`, `ui`, `payments`, `api`)
2. **Classify changes per domain**:
   - ADDED — New requirements that don't exist today
   - MODIFIED — Changes to existing behavior
   - REMOVED — Behavior being taken away
3. **Draft requirements** — Each requirement should be:
   - Observable (describes external behavior, not internal implementation)
   - Testable (you could write an automated test for it)
   - Atomic (one requirement = one concern)

## Phase 3: GENERATE

Create delta spec files in the change directory's `specs/` subdirectory, organized by domain:

```
<change-dir>/specs/
└── <domain>/
    └── spec.md
```

Each spec file MUST follow this format:

```markdown
# <Domain> Specification (Delta)

## Purpose

Brief description of what this spec covers in the context of this change.

## ADDED Requirements

### Requirement: <Descriptive Name>

The system SHALL <observable behavior description>.

#### Scenario: <Descriptive scenario name>
- GIVEN <precondition describing initial state>
- WHEN <action or event that triggers behavior>
- THEN <expected observable result>
- AND <additional assertion if needed>

#### Scenario: <Edge case or alternative path>
- GIVEN <precondition>
- WHEN <action>
- THEN <expected result>

## MODIFIED Requirements

### Requirement: <Name> (was: <brief description of old behavior>)

The system SHALL <new behavior description>.

**Changed from**: <previous behavior>
**Reason**: <why the change is needed>

#### Scenario: <Updated scenario>
- GIVEN <precondition>
- WHEN <action>
- THEN <new expected result>

## REMOVED Requirements

### Requirement: <Name>

**Removed**: <what behavior is being removed>
**Reason**: <why it's being removed>
```

### Spec Writing Rules

- Use **RFC 2119 keywords** for requirement strength:
  - **MUST / SHALL** — absolute requirement, no exceptions
  - **SHOULD** — recommended, but exceptions are allowed with justification
  - **MAY** — optional behavior
- **Specs are behavior contracts**, not implementation plans:
  - Describe WHAT the system does, not HOW it does it
  - No internal class names, library choices, or implementation details
  - Focus on inputs, outputs, observable state changes, and error conditions
- **Scenarios must be testable** — each one could become an automated test
- **Cover both happy and unhappy paths** — include edge cases and error scenarios
- Only include MODIFIED and REMOVED sections if applicable

### PHASE_3_CHECKPOINT
- [ ] Delta spec files created in `<change-dir>/specs/<domain>/spec.md`
- [ ] All requirements use Given/When/Then scenarios
- [ ] RFC 2119 keywords used consistently
- [ ] Requirements describe behavior, not implementation
- [ ] Both happy path and edge cases covered
- [ ] ADDED/MODIFIED/REMOVED sections used appropriately

## Phase 4: REPORT

List the spec files created, the domains covered, and a count of requirements per domain.
Highlight any particularly important or complex requirements.
