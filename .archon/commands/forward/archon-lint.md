---
description: Run lint check and fix all issues until bun run lint passes cleanly
argument-hint: (no arguments - operates on current working directory)
---

# Lint Fix Loop

---

## Your Mission

Run `bun run lint` against the codebase and fix ALL issues until it passes with zero errors and zero warnings. This project enforces `--max-warnings 0`, so warnings count as failures.

---

## Phase 1: INITIAL CHECK

Run lint to assess current state:

```bash
bun run lint
```

**If it passes (exit 0):** Skip to Phase 4 (report clean).

**If it fails:** Continue to Phase 2.

---

## Phase 2: AUTO-FIX

Try the built-in auto-fixer first:

```bash
bun run lint:fix
```

Then re-check:

```bash
bun run lint
```

**If it passes:** Skip to Phase 3 (validate).

**If still failing:** Continue to manual fixes below.

---

## Phase 3: MANUAL FIX LOOP

For each remaining lint error:

1. Read the error output carefully — note file, line, rule name
2. Open the file and fix the issue according to the rule
3. **Do NOT use `// eslint-disable` comments** unless:
   - External SDK types are incorrect (document which SDK and why)
   - Intentional type assertion after validation (must include comment explaining the validation)
4. After fixing a batch of issues, re-run:
   ```bash
   bun run lint
   ```
5. Repeat until `bun run lint` exits 0

**Common fixes:**
- `no-unused-vars`: Remove the unused import/variable, or prefix with `_` if it's a required parameter
- `no-explicit-any`: Add proper types
- `@typescript-eslint/no-floating-promises`: Add `await` or `void` operator
- Import order issues: Reorder imports per project convention

**Max iterations:** 5 rounds of fix-and-check. If still failing after 5 rounds, report the remaining issues.

---

## Phase 4: REPORT

### If Clean:

```
Lint: PASS - zero errors, zero warnings
```

### If Issues Remain (after 5 rounds):

```
Lint: PARTIAL - {N} issues remain after 5 fix rounds

Remaining issues:
- {file}:{line} - {rule}: {message}
```

---

## Success Criteria

- **LINT_PASS**: `bun run lint` exits 0 with zero errors and zero warnings
- **NO_DISABLE_ABUSE**: No `eslint-disable` comments added without documented justification
