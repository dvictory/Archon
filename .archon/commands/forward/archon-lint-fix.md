---
description: Run `bun run lint:fix` in a loop until lint passes, then commit any fixes locally. Pre-push guardrail; never pushes.
argument-hint: (none)
---

# Lint Fix Loop (Pre-Push Guardrail)

---

## IMPORTANT: Output Behavior

This is a guardrail step that runs before every push in the workflow. Keep working output minimal:
- Do NOT narrate each step
- Only output the final structured summary at the end
- Use the TodoWrite tool to track progress silently

---

## Your Mission

Run `bun run lint:fix` to auto-correct lint violations, then verify `bun run lint` passes with **zero warnings** (the repo enforces `--max-warnings 0`). Loop up to 3 attempts. If auto-fix cannot resolve everything, hand-edit the remaining violations using the lint output, then re-run. Commit any resulting changes locally. **Never push.**

**Git action**: Commit lint fixes locally (if any). Do NOT push.
**Output artifact**: `$ARTIFACTS_DIR/lint/lint-fix-report.md`

---

## Phase 1: BASELINE - Capture Starting State

### 1.1 Record Current State

```bash
HEAD_BRANCH=$(git branch --show-current)
git status --porcelain
git rev-parse HEAD
```

The working tree should be clean. If there are uncommitted changes, stop and report — earlier phases should have left a clean tree.

### 1.2 Initial Lint Check

```bash
bun run lint
```

Capture the exit code. If exit code is 0 and there is no output, lint already passes — skip directly to **Phase 4: REPORT** with status `NO_FIXES_NEEDED`.

**PHASE_1_CHECKPOINT:**
- [ ] Branch identified
- [ ] Working tree clean
- [ ] Initial lint state captured

---

## Phase 2: AUTO-FIX LOOP - Up to 3 Attempts

### Loop semantics

Repeat the following block up to **3 times**. After each attempt, re-run `bun run lint`. If it exits 0, break out of the loop. If after 3 attempts lint still fails, fall through to Phase 3 (manual fix).

### Attempt N (N = 1, 2, 3)

```bash
echo "Lint fix attempt $N"
bun run lint:fix
LINT_FIX_EXIT=$?

bun run lint
LINT_EXIT=$?
```

- `LINT_FIX_EXIT` non-zero is informational (the autofixer may itself flag unfixable rules) — what matters is `LINT_EXIT`.
- If `LINT_EXIT == 0`: lint passes — exit loop, proceed to Phase 4.
- If `LINT_EXIT != 0` and N < 3: increment N and retry (the previous pass may have changed code that the next pass can further fix).
- If `LINT_EXIT != 0` and N == 3: proceed to Phase 3.

**PHASE_2_CHECKPOINT:**
- [ ] `bun run lint:fix` invoked up to 3 times
- [ ] Lint result captured after the final attempt

---

## Phase 3: MANUAL FIX - Resolve What Auto-Fix Cannot

Only reached if Phase 2 ended with `LINT_EXIT != 0`.

### 3.1 Identify Remaining Violations

```bash
bun run lint
```

Capture the failing rules and locations from the output.

### 3.2 Apply Targeted Fixes

For each remaining violation, read the file, apply a minimal, scoped fix:
- Prefer fixing the underlying issue (rename a variable, remove dead code, narrow a type) over disabling the rule.
- **Inline `// eslint-disable-next-line` is almost never acceptable** (see `CLAUDE.md` — ESLint Guidelines). Use only when:
  1. An external SDK type is genuinely incorrect (document which SDK + why)
  2. An intentional type assertion follows runtime validation (document the validation)
- **Never** bulk-disable at file level or disable `no-explicit-any` without justification.

After hand-edits, run lint once more:

```bash
bun run lint
```

Lint must now exit 0. If it does not, the remaining violations are blockers — stop and report `BLOCKED` with the unresolved rule names and locations.

**PHASE_3_CHECKPOINT:**
- [ ] Manual fixes applied (if needed)
- [ ] Final `bun run lint` exits 0, OR status is `BLOCKED` with documented reason

---

## Phase 4: COMMIT LOCALLY (NO PUSH)

### 4.1 Detect Changes

```bash
git status --porcelain
```

If the output is empty, no changes were made (lint passed on first try, or autofix changed nothing). Skip to Phase 5 with status `NO_FIXES_NEEDED`.

### 4.2 Stage and Commit Lint Fixes Only

```bash
git add -A
git status
git commit -m "chore: lint:fix auto-corrections"
```

If the autofix changes overlap unfinished work (they shouldn't, since the tree was clean coming in), stop and report — never use destructive commands to "clean up."

### 4.3 Do NOT Push

The next workflow step (`finalize-pr` for the first push, or the push step inside `implement-review-fixes`) is responsible for pushing. Do not run `git push` here.

**PHASE_4_CHECKPOINT:**
- [ ] Lint fixes committed locally (or nothing to commit)
- [ ] No push attempted

---

## Phase 5: REPORT - Write Artifact

Write to `$ARTIFACTS_DIR/lint/lint-fix-report.md`:

```markdown
# Lint Fix Report

**Date**: {ISO timestamp}
**Status**: PASS | NO_FIXES_NEEDED | BLOCKED
**Branch**: {HEAD_BRANCH}
**Commit**: {commit hash or "no changes"}
**Auto-fix attempts**: {1..3}
**Manual fixes applied**: {yes/no}

---

## Summary

{1-2 sentences: how many auto-fix passes ran, what manual edits were needed, final lint status.}

---

## Auto-Fix Passes

| Attempt | `lint:fix` exit | `lint` exit |
|---------|-----------------|-------------|
| 1       | {n}             | {n}         |
| 2       | {n or n/a}      | {n or n/a}  |
| 3       | {n or n/a}      | {n or n/a}  |

---

## Manual Fixes

| File:line | Rule | Action |
|-----------|------|--------|
| {path}    | {rule} | {what was changed} |

*(none)* if Phase 3 was not entered

---

## Blocked Violations

| File:line | Rule | Why Not Fixed |
|-----------|------|---------------|
| {path}    | {rule} | {reason} |

*(none)* if status is PASS or NO_FIXES_NEEDED
```

**PHASE_5_CHECKPOINT:**
- [ ] Report written

---

## Phase 6: OUTPUT - Final Summary

Output only this:

```
## Lint Fix Complete

**Branch**: {HEAD_BRANCH}
**Status**: {PASS | NO_FIXES_NEEDED | BLOCKED}

Auto-fix passes: {n}
Manual fixes: {n}
Blocked: {n}

Committed: {yes / no changes}
Pushed: no (intentional — pre-push guardrail)

Report: $ARTIFACTS_DIR/lint/lint-fix-report.md
```

---

## Error Handling

### `bun run lint` doesn't exist
If the script is missing from `package.json`, stop with a clear error — this command assumes the standard Archon validate scripts. Do not invent a fallback command.

### Persistent failure after manual fixes
If after Phase 3 lint still fails, exit with status `BLOCKED`. Do **not** loosen rules, suppress with `// eslint-disable-*` without justification, or bypass via `--max-warnings`. The downstream push step is responsible for deciding whether to proceed.

### Working tree dirty on entry
Stop and report. The lint-fix step expects to start from a clean tree so its commit isolates lint changes from feature changes.

---

## Success Criteria

- **CLEAN_START**: Working tree was clean coming in
- **LINT_PASSES**: Final `bun run lint` exits 0 with zero warnings, OR status is `BLOCKED` with documented unresolved violations
- **NO_RULE_SUPPRESSION**: No new `eslint-disable` lines unless they meet the CLAUDE.md exception bar
- **COMMITTED_LOCALLY**: Lint fixes (if any) committed on the local branch
- **NOT_PUSHED**: No `git push` executed
- **REPORTED**: Report artifact written to `$ARTIFACTS_DIR/lint/lint-fix-report.md`
