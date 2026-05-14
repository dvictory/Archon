---
description: Run CodeRabbit AI code review against PR branch, fix findings, validate, and push
argument-hint: (none - reads PR context from workflow artifacts)
---

# CodeRabbit Review & Fix

---

## IMPORTANT: Output Behavior

**Your output will be posted as a GitHub comment.** Keep working output minimal:
- Do NOT narrate each step
- Do NOT output verbose progress updates
- Only output the final structured report at the end
- Use the TodoWrite tool to track progress silently

---

## Your Mission

Run the CodeRabbit AI code review skill against the current PR changes, fix all actionable findings, validate, commit, push, and report results. This serves as an additional quality gate after the built-in review agents have already run and their fixes have been applied.

**Output artifact**: `$ARTIFACTS_DIR/review/coderabbit-report.md`
**Git action**: Commit AND push fixes to the PR branch
**GitHub action**: Post CodeRabbit fix report as a comment on the PR

---

## Phase 1: LOAD - Get PR Context

### 1.1 Get PR Number and Branch

```bash
PR_NUMBER=$(cat $ARTIFACTS_DIR/.pr-number)
HEAD_BRANCH=$(gh pr view $PR_NUMBER --json headRefName,baseRefName --jq '.headRefName + " " + .baseRefName')
echo "PR: $PR_NUMBER, Branch info: $HEAD_BRANCH"
```

Extract HEAD_BRANCH and BASE_BRANCH from the output.

### 1.2 Checkout PR Branch

```bash
git fetch origin $HEAD_BRANCH
git checkout $HEAD_BRANCH
git pull origin $HEAD_BRANCH
```

Verify:

```bash
git branch --show-current
git status --porcelain
```

**PHASE_1_CHECKPOINT:**
- [ ] PR number identified
- [ ] On the correct PR branch
- [ ] Base branch identified

---

## Phase 2: REVIEW - Run CodeRabbit

### 2.1 Run CodeRabbit Review

Invoke the CodeRabbit skill to review all committed changes against the base branch:

```
/coderabbit:review committed --base $BASE_BRANCH
```

This will analyze the diff between the base branch and the current PR branch, returning structured findings with file locations and severity levels.

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
- It duplicates an issue already addressed by the earlier review agents

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

## Phase 6: COMMIT AND PUSH

### 6.1 Stage and Commit

Only commit if there are actual changes to commit. If no fixes were applied (all findings were skipped or no findings at all), skip this phase.

```bash
git add {specific files}
git status
git commit -m "fix: address CodeRabbit review findings

$(echo "Fixed:"; echo "- {brief list}")
$(echo ""; echo "Skipped:"; echo "- {brief list if any}")"
```

### 6.2 Push

```bash
git push origin $HEAD_BRANCH
```

If push fails:

```bash
git pull --rebase origin $HEAD_BRANCH
git push origin $HEAD_BRANCH
```

**PHASE_6_CHECKPOINT:**
- [ ] Changes committed (or no changes needed)
- [ ] Pushed to PR branch (or nothing to push)

---

## Phase 7: GENERATE - Write Report

Write to `$ARTIFACTS_DIR/review/coderabbit-report.md`:

```markdown
# CodeRabbit Review Report: PR #{number}

**Date**: {ISO timestamp}
**Status**: COMPLETE | PARTIAL | NO_FINDINGS
**Branch**: {HEAD_BRANCH}
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

## Phase 8: POST - GitHub Comment

Post the results as a PR comment:

```bash
gh pr comment $PR_NUMBER --body "$(cat <<'EOF'
## CodeRabbit Review Report

**Status**: {COMPLETE | PARTIAL | NO_FINDINGS}
**Pushed**: {yes/no changes}

---

### Findings

| Total | Fixed | Skipped | Blocked |
|-------|-------|---------|---------|
| {N}   | {N}   | {N}     | {N}     |

{If fixes applied:}
### Fixes Applied

| Finding | Location |
|---------|----------|
| {title} | `file:line` |

{If skipped:}
### Skipped

| Finding | Reason |
|---------|--------|
| {title} | {reason} |

---

### Validation

Type check | Lint | Tests

---

*CodeRabbit review by Archon*
EOF
)"
```

**PHASE_8_CHECKPOINT:**
- [ ] GitHub comment posted

---

## Phase 9: OUTPUT - Final Summary

Output only this:

```
## CodeRabbit Review Complete

**PR**: #{number}
**Branch**: {HEAD_BRANCH}
**Status**: {COMPLETE | PARTIAL | NO_FINDINGS}

Found: {n}
Fixed: {n}
Skipped: {n}
Blocked: {n}

Validation: All checks pass
Pushed: {yes/no changes}

Report: $ARTIFACTS_DIR/review/coderabbit-report.md
```

---

## Error Handling

### CodeRabbit skill not available
If the `/coderabbit:review` skill is not installed or errors, output:
```
CodeRabbit skill not available. Skipping CodeRabbit review.
```
Write an artifact noting the skip and continue without failing the workflow.

### No findings
This is a success case - CodeRabbit found no issues. Write the report with NO_FINDINGS status and post a brief GitHub comment confirming the clean review.

### Type check / tests fail after fix
1. Review the error
2. Adjust or revert the fix
3. If still failing, mark BLOCKED

### Push fails
1. `git pull --rebase origin $HEAD_BRANCH`
2. Resolve conflicts if any
3. Push again

---

## Success Criteria

- **ON_CORRECT_BRANCH**: Working on PR's head branch
- **REVIEW_RAN**: CodeRabbit review executed (or gracefully skipped if unavailable)
- **ALL_FINDINGS_ADDRESSED**: Every finding is fixed, skipped (with reason), or blocked (with reason)
- **VALIDATION_PASSED**: Type check, lint, and tests all pass
- **COMMITTED_AND_PUSHED**: Changes committed and pushed (if any fixes applied)
- **REPORTED**: Report artifact written and GitHub comment posted
