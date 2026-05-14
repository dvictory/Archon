---
description: Verify type-check + test suite pass. Best-effort fix on failure (up to 3 attempts each). Commits fixes locally. Never pushes. Acts as a hard DAG gate after every code-mutating workflow step.
argument-hint: (none)
---

# Verify Types + Tests (Pre-Push Gate)

---

## IMPORTANT: Output Behavior

This step is a **hard gate** the workflow inserts after every code-mutating phase. Keep working output minimal:
- Do NOT narrate each step
- Only output the final structured summary at the end
- Use the TodoWrite tool to track progress silently
- Final failure here **blocks the workflow** — do not paper over real regressions to make the gate pass

---

## Your Mission

Run `bun run type-check` and the test suite. On failure, apply best-effort fixes following the discipline below, up to 3 attempts each. Commit any fixes locally. **Never push.** If the suite cannot be made green within 3 attempts, exit with status `BLOCKED` and let the workflow halt.

**Git action**: Commit any verification-driven fixes locally. Do NOT push.
**Output artifact**: `$ARTIFACTS_DIR/verify/verify-types-tests-report.md`

---

## CRITICAL: Fixing Discipline (Best-Effort, Not Best-Looking)

When a test fails, the default assumption is: **the implementation is wrong, the test is right**. Modifying tests to pass is a regression hazard the user explicitly accepted when enabling best-effort fix mode — keep that contract honest:

1. **First, classify each failure** as one of:
   - **Implementation bug** — the code under test produces wrong output → fix the implementation
   - **Test bug** — the test asserts something the prior phase intentionally changed (and the change is correct per the workflow's plan/review artifacts) → update the test
   - **Type drift** — a type was renamed/narrowed → update both the type and any tests that referenced the old shape
   - **Flaky** — non-deterministic; not your problem to fix in this gate → mark as `BLOCKED` and report

2. **Bias toward fixing implementation, not tests.** A test rewrite "just to make it pass" is a regression hidden in plain sight. Only modify a test if you can articulate, in one sentence, why the original assertion is wrong *given the work done in the prior phase*.

3. **Document every test change** in the report below — file:line, original assertion, new assertion, one-sentence justification.

4. **Never** delete a test, skip it (`test.skip`, `xit`, `.only` to exclude others), or weaken assertions to "approximately equal" without a clear reason — that is detection evasion, not a fix.

5. **Never** disable type-checking with `// @ts-ignore`, `// @ts-expect-error`, or `any` casts to make type-check pass. Use them only when:
   - An external SDK type is genuinely incorrect (document which SDK + why)
   - An intentional type assertion follows runtime validation (document the validation)

---

## Phase 1: BASELINE - Capture Starting State

### 1.1 Record Context

```bash
HEAD_BRANCH=$(git branch --show-current)
git status --porcelain
git rev-parse HEAD
```

The working tree should be clean (the prior code-mutating phase should have left it clean). If there are uncommitted changes, stop and report — do not silently commit pre-existing dirt.

### 1.2 Detect Monorepo Runner

```bash
if [ -f nx.json ]; then RUNNER="nx-affected"; else RUNNER="bun-root"; fi
echo "Runner: $RUNNER"
```

- `nx-affected`: use `bun nx affected -t typecheck` and `bun nx affected -t test`
- `bun-root`: use `bun run type-check` and `bun run test`

**PHASE_1_CHECKPOINT:**
- [ ] Branch identified
- [ ] Working tree clean
- [ ] Runner mode detected

---

## Phase 2: TYPE-CHECK LOOP - Up to 3 Attempts

### 2.1 Initial Type-Check

```bash
# nx-affected:
bun nx affected -t typecheck
# OR bun-root:
bun run type-check
```

Capture exit code as `TYPECHECK_EXIT`.

- If `TYPECHECK_EXIT == 0`: skip to Phase 3.
- If `TYPECHECK_EXIT != 0`: enter the fix loop.

### 2.2 Fix Loop (Attempt N = 1, 2, 3)

For each attempt:

1. Read the type errors carefully. Group them: cascading from one root cause, vs. independent.
2. Apply minimal fixes following the discipline above. Prefer:
   - Fixing the actual type (struct/interface) over casting at every call site
   - Updating one root type over chasing 50 downstream errors
3. Re-run type-check.
4. If exit 0: break loop, proceed to Phase 3.
5. If exit != 0 and N < 3: increment N and retry.
6. If exit != 0 and N == 3: mark status `BLOCKED` with remaining errors and proceed to Phase 5 (no commit needed if no fixes were applied).

**PHASE_2_CHECKPOINT:**
- [ ] Type-check exits 0, OR status is BLOCKED with documented errors
- [ ] No `@ts-ignore` / `@ts-expect-error` / `any` added without justification

---

## Phase 3: TEST LOOP - Up to 3 Attempts

Only enter if Phase 2 ended green (or if Phase 2 was already green on first run).

### 3.1 Initial Test Run

```bash
# nx-affected:
bun nx affected -t test
# OR bun-root:
bun run test
```

Capture exit code as `TEST_EXIT`.

- If `TEST_EXIT == 0`: proceed to Phase 4.
- If `TEST_EXIT != 0`: enter the fix loop.

### 3.2 Fix Loop (Attempt N = 1, 2, 3)

For each failing test:

1. **Classify** per the discipline above (implementation bug / test bug / type drift / flaky).
2. Apply a minimal, scoped fix.
   - Run the single failing file first: `bun test {file}` — faster iteration, clearer signal.
   - If the fix is to the implementation, re-run type-check too (a code change can re-break types).
3. Document the change in your in-memory tally for the report.

After each pass through the failing set, re-run the full test command:

```bash
# nx-affected:
bun nx affected -t test
# OR bun-root:
bun run test
```

- If exit 0: break loop, proceed to Phase 4.
- If exit != 0 and N < 3: re-classify the remaining failures (some may now be different from the original set) and retry.
- If exit != 0 and N == 3: mark unresolved failures as `BLOCKED` and proceed to Phase 5.

### 3.3 Re-Run Type-Check After Test Fixes

If you modified any non-test source files during Phase 3, re-run type-check once more to confirm you didn't break types:

```bash
# nx-affected:
bun nx affected -t typecheck
# OR bun-root:
bun run type-check
```

If this re-introduces type errors, return to Phase 2 (counts as a fresh attempt). After 6 total attempts across Phase 2 + 3, escalate to `BLOCKED` — endless ping-pong between type-check and tests means something deeper is wrong.

**PHASE_3_CHECKPOINT:**
- [ ] Tests exit 0, OR status is BLOCKED with documented failures
- [ ] No tests skipped, deleted, or weakened without one-sentence justification
- [ ] Type-check still passes after any code edits

---

## Phase 4: COMMIT LOCALLY (NO PUSH)

### 4.1 Detect Changes

```bash
git status --porcelain
```

If empty, no fixes were applied — skip to Phase 5 with status `PASS_NO_FIXES`.

### 4.2 Stage and Commit

```bash
git add -A
git status
git commit -m "fix: verify-types-tests gate auto-fixes

$(echo "Type fixes:"; echo "- {brief list}")
$(echo ""; echo "Test fixes:"; echo "- {brief list}")
$(echo ""; echo "Test modifications:"; echo "- {file:line — justification}")"
```

### 4.3 Do NOT Push

This is a gate, not a publishing step. The downstream `finalize-pr` (or the `implement-review-fixes` push) is responsible for pushing. Do not run `git push` here.

**PHASE_4_CHECKPOINT:**
- [ ] Fixes committed locally (or nothing to commit)
- [ ] No push attempted

---

## Phase 5: REPORT - Write Artifact

Write to `$ARTIFACTS_DIR/verify/verify-types-tests-report.md`:

```markdown
# Verify Types + Tests Report

**Date**: {ISO timestamp}
**Status**: PASS | PASS_NO_FIXES | BLOCKED
**Branch**: {HEAD_BRANCH}
**Commit**: {commit hash or "no changes"}
**Runner**: nx-affected | bun-root
**Type-check attempts**: {1..3}
**Test attempts**: {1..3}

---

## Summary

{1-2 sentences: what failed initially, what was fixed, final state.}

---

## Type-Check

| Attempt | Exit | Errors Remaining |
|---------|------|------------------|
| 1       | {n}  | {n}              |
| 2       | {n}  | {n}              |
| 3       | {n}  | {n}              |

### Type Fixes Applied

| File:line | What Was Changed | Why |
|-----------|------------------|-----|
| {path}    | {description}    | {one sentence} |

*(none)* if Phase 2 was green on first try

---

## Tests

| Attempt | Exit | Failing |
|---------|------|---------|
| 1       | {n}  | {n}     |
| 2       | {n}  | {n}     |
| 3       | {n}  | {n}     |

### Implementation Fixes (Phase 3)

| File:line | Failing Test | What Was Changed |
|-----------|--------------|------------------|
| {path}    | {test name}  | {description}    |

### Test Modifications (Phase 3)

| File:line | Original Assertion | New Assertion | Justification |
|-----------|---------------------|---------------|---------------|
| {path}    | {summary}           | {summary}     | {one sentence — why the original assertion was wrong given prior phase's work} |

*(none)* if no test files were modified

---

## Blocked Failures

| File:line | Test or Type Error | Why Not Fixed |
|-----------|---------------------|---------------|
| {path}    | {summary}           | {reason}      |

*(none)* if status is PASS or PASS_NO_FIXES
```

**PHASE_5_CHECKPOINT:**
- [ ] Report written

---

## Phase 6: OUTPUT - Final Summary

Output only this:

```
## Verify Types + Tests Complete

**Branch**: {HEAD_BRANCH}
**Status**: {PASS | PASS_NO_FIXES | BLOCKED}

Type-check attempts: {n} (exit: {0 | non-zero})
Test attempts: {n} (exit: {0 | non-zero})

Type fixes: {n}
Implementation fixes: {n}
Test modifications: {n}
Blocked: {n}

Committed: {yes / no changes}
Pushed: no (intentional — gate, not publishing step)

Report: $ARTIFACTS_DIR/verify/verify-types-tests-report.md
```

If status is `BLOCKED`, the workflow engine will halt downstream nodes. Do not exit 0.

---

## Error Handling

### `bun run type-check` or `bun run test` missing
If the runner script does not exist in `package.json` and `nx.json` is also absent, stop with a clear error. Do not invent a fallback command.

### Persistent failure after 3 attempts (per loop) or 6 attempts total
Exit with status `BLOCKED`. Do **not** disable rules, skip tests, weaken assertions, or `@ts-ignore` to force green. The downstream push step is responsible for deciding whether to halt the workflow.

### Working tree dirty on entry
Stop and report. The gate expects to start from a clean tree so any commit it produces is isolated to gate-driven fixes.

### Ping-pong between type-check and tests
If fixing a test re-breaks types, fixing the type re-breaks the test, and this oscillates: stop after 6 total attempts. The disagreement is real and needs human attention — report both sides in the BLOCKED section.

---

## Success Criteria

- **CLEAN_START**: Working tree was clean coming in
- **TYPECHECK_GREEN**: Final `type-check` exits 0, OR status is `BLOCKED` with documented errors
- **TESTS_GREEN**: Final test run exits 0, OR status is `BLOCKED` with documented failures
- **NO_SUPPRESSION**: No new `@ts-ignore` / `@ts-expect-error` / `any` / `test.skip` without justification documented in the report
- **TEST_CHANGES_JUSTIFIED**: Every test-file modification has a one-sentence justification in the report
- **COMMITTED_LOCALLY**: Fixes (if any) committed on the local branch
- **NOT_PUSHED**: No `git push` executed
- **REPORTED**: Report artifact written to `$ARTIFACTS_DIR/verify/verify-types-tests-report.md`
