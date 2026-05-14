---
description: Run CodeRabbit AI review against the local feature branch (pre-push), fix findings, validate, and commit locally. No push, no PR.
argument-hint: (none - operates on the current local branch vs $BASE_BRANCH)
---

# CodeRabbit Review & Fix (Pre-Push)

---

## IMPORTANT: Output Behavior

This step runs **before any code is pushed to the remote** and before a PR exists. There is nowhere to post a GitHub comment yet. Keep working output minimal:
- Do NOT narrate each step
- Do NOT output verbose progress updates
- Only output the final structured report at the end
- Use the TodoWrite tool to track progress silently

---

## Your Mission

Run the CodeRabbit AI code review skill against the **local feature branch's diff vs the base branch**, fix all actionable findings, validate, and commit fixes **locally only**. This is a pre-push quality gate: the goal is to keep CodeRabbit churn out of the eventual PR history.

**Output artifact**: `$ARTIFACTS_DIR/review/coderabbit-report.md`
**Git action**: Commit fixes locally on the current branch. **Do NOT push. Do NOT open or comment on a PR.**

---

## Phase 1: LOAD - Confirm Local Branch Context

### 1.1 Identify Current Branch and Base

```bash
HEAD_BRANCH=$(git branch --show-current)
BASE_BRANCH="$BASE_BRANCH"
echo "Local branch: $HEAD_BRANCH"
echo "Base branch: $BASE_BRANCH"
```

`$BASE_BRANCH` is substituted by the workflow engine. If empty, fall back to `git symbolic-ref refs/remotes/origin/HEAD --short | sed 's@^origin/@@'` and stop with an error if that also fails.

### 1.2 Verify Working Tree State

```bash
git status --porcelain
```

The working tree should be clean (everything committed in earlier phases). If there are uncommitted changes, stop and report — the earlier `implement-tasks` / `validate` phases should have left a clean tree.

### 1.3 Confirm Diff vs Base

```bash
git fetch origin $BASE_BRANCH 2>/dev/null || true
git log --oneline origin/$BASE_BRANCH..HEAD 2>/dev/null || git log --oneline $BASE_BRANCH..HEAD
```

There must be at least one commit on the feature branch beyond base. If the diff is empty, write a `NO_FINDINGS` report and exit.

**PHASE_1_CHECKPOINT:**
- [ ] Branch identified
- [ ] Base branch identified
- [ ] Working tree clean
- [ ] Non-empty diff vs base confirmed (or exit with NO_FINDINGS)

---

## Phase 2: REVIEW - Run CodeRabbit

### 2.1 Run CodeRabbit Against Local Diff

Invoke the CodeRabbit skill against the committed feature-branch diff vs base:

```
/coderabbit:review --base $BASE_BRANCH
```

This analyzes the local commits on the feature branch against `$BASE_BRANCH` without requiring a pushed PR. It returns structured findings with file locations and severity levels.

### 2.2 Collect Findings

From the CodeRabbit output, compile all findings into a structured list:
- File location and line numbers
- Issue description
- Severity/priority
- Suggested fix (if provided)

**PHASE_2_CHECKPOINT:**
- [ ] CodeRabbit review completed
- [ ] All findings collected and categorized

---

## Phase 3: TRIAGE - Decide What to Fix

For each CodeRabbit finding, decide: **FIX** or **SKIP**.

### Fix if:
- It is a real bug, race condition, memory leak, logic error, or security issue
- It is a clear code quality problem (dead code, unused imports, wrong types)
- The fix is concrete and low-risk

### Skip (YAGNI / out-of-scope) if:
- The finding recommends speculative abstractions or refactoring beyond PR scope
- It suggests adding validation for inputs that cannot be invalid in context
- It recommends architectural changes outside the PR's concern

For each skipped finding, document **the specific reason**.

**PHASE_3_CHECKPOINT:**
- [ ] Every finding marked FIX or SKIP
- [ ] Skip reasons documented

---

## Phase 4: IMPLEMENT - Apply Fixes

### 4.1 For Each Finding Marked FIX

1. Read the relevant file(s)
2. Apply the fix
3. Run type-check after each fix: if nx → `bun nx affected -t typecheck`, else → `bun run type-check`
4. Note exactly what was changed

### 4.2 Handle Unfixable Findings

If a fix cannot be applied (code changed, fix is ambiguous, would break other things), mark as **BLOCKED** and document why. Do not force a broken fix.

### 4.3 Add Tests for Fixed Code

If CodeRabbit flagged missing test coverage for something you just fixed, add a targeted test:

```bash
bun test {file}
```

**PHASE_4_CHECKPOINT:**
- [ ] All FIX findings attempted
- [ ] Tests added where needed
- [ ] BLOCKED findings documented

---

## Phase 5: VALIDATE - Full Check

```bash
# Type check (monorepo-aware)
if [ -f nx.json ]; then bun nx affected -t typecheck; else bun run type-check; fi

# Lint (always root-level)
bun run lint

# Tests (monorepo-aware)
if [ -f nx.json ]; then bun nx affected -t test; else bun run test; fi
```

All must pass. If something fails after a fix:
1. Review the error
2. Adjust the fix or revert it and mark BLOCKED
3. Re-run until clean

**PHASE_5_CHECKPOINT:**
- [ ] Type check passes
- [ ] Lint passes
- [ ] Tests pass

---

## Phase 6: COMMIT LOCALLY (NO PUSH)

### 6.1 Stage and Commit

Only commit if there are actual changes to commit. If no fixes were applied (all findings were skipped or no findings at all), skip this phase.

```bash
git add {specific files}
git status
git commit -m "fix: address CodeRabbit pre-push review findings

$(echo "Fixed:"; echo "- {brief list}")
$(echo ""; echo "Skipped:"; echo "- {brief list if any}")"
```

### 6.2 Do NOT Push

This step runs **before** the PR exists. The next workflow phase (`finalize-pr`) is responsible for the first push and `gh pr create`. Do not run `git push` here.

**PHASE_6_CHECKPOINT:**
- [ ] Changes committed locally (or no changes needed)
- [ ] No push attempted

---

## Phase 7: GENERATE - Write Report

Write to `$ARTIFACTS_DIR/review/coderabbit-report.md`:

```markdown
# CodeRabbit Pre-Push Review Report

**Date**: {ISO timestamp}
**Status**: COMPLETE | PARTIAL | NO_FINDINGS
**Branch**: {HEAD_BRANCH}
**Base**: {BASE_BRANCH}
**Commit**: {commit hash or "no changes"}

---

## Summary

{2-3 sentences covering what CodeRabbit found, what was fixed, what was skipped}

---

## Findings Overview

| Total | Fixed | Skipped | Blocked |
|-------|-------|---------|---------|
| {N}   | {N}   | {N}     | {N}     |

---

## Fixes Applied

| Finding | Location | What Was Done |
|---------|----------|---------------|
| {title} | `file:line` | {description} |

*(none)* if nothing was fixed

---

## Skipped Findings

| Finding | Location | Reason Skipped |
|---------|----------|----------------|
| {title} | `file:line` | {reason} |

*(none)* if nothing was skipped

---

## Blocked (Could Not Fix)

| Finding | Reason |
|---------|--------|
| {title} | {why} |

*(none)* if nothing was blocked

---

## Validation

| Check | Status |
|-------|--------|
| Type check | pass/fail |
| Lint | pass/fail |
| Tests | pass/fail |
```

**PHASE_7_CHECKPOINT:**
- [ ] Report written

---

## Phase 8: OUTPUT - Final Summary

Output only this:

```
## CodeRabbit Pre-Push Review Complete

**Branch**: {HEAD_BRANCH}
**Base**: {BASE_BRANCH}
**Status**: {COMPLETE | PARTIAL | NO_FINDINGS}

Found: {n}
Fixed: {n}
Skipped: {n}
Blocked: {n}

Validation: All checks pass
Pushed: no (intentional — pre-push gate)

Report: $ARTIFACTS_DIR/review/coderabbit-report.md
```

The `workflow-summary` phase at the end of the workflow surfaces this artifact in the final PR comment.

---

## Error Handling

### CodeRabbit skill not available
If the `/coderabbit:review` skill is not installed or errors, output:
```
CodeRabbit skill not available. Skipping CodeRabbit review.
```
Write an artifact noting the skip and continue without failing the workflow.

### No findings
This is a success case — CodeRabbit found no issues. Write the report with `NO_FINDINGS` status and exit. No commit needed.

### Type check / tests fail after fix
1. Review the error
2. Adjust or revert the fix
3. If still failing, mark BLOCKED

### Empty diff vs base
Should not happen if `implement-tasks` produced commits, but if so: write `NO_FINDINGS` report and exit cleanly.

---

## Success Criteria

- **ON_LOCAL_BRANCH**: Working on the feature branch with a non-empty diff vs `$BASE_BRANCH`
- **REVIEW_RAN**: CodeRabbit review executed (or gracefully skipped if unavailable)
- **ALL_FINDINGS_ADDRESSED**: Every finding is fixed, skipped (with reason), or blocked (with reason)
- **VALIDATION_PASSED**: Type check, lint, and tests all pass
- **COMMITTED_LOCALLY**: Fixes committed on the local branch (if any fixes applied)
- **NOT_PUSHED**: No `git push` executed; no PR comment posted
- **REPORTED**: Report artifact written to `$ARTIFACTS_DIR/review/coderabbit-report.md`
