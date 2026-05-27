# Diff-review checklist

After every implementer task completes, Codex must run through every item on this checklist before accepting the output. If any item fails, the review gate is **blocked** and Codex must enter the correction loop (prompt fixes in the same session).

## Pre-review setup

1. Obtain the full diff of all changes made by the implementer.
2. Obtain the implementer's completion report (file list, summary, lint/type-check status, test results).
3. Verify that the file list in the completion report matches what the task packet's modify scope permitted. Reject immediately if any out-of-scope files were modified without prior approval.
4. Verify that the implementer's read/search activity was relevant to the task and not an indiscriminate scan of the entire repo.
5. Verify session-health evidence exists (no empty-output or malformed completion report for the accepted round).

## Checklist

### Scope compliance

- [ ] Were modifications limited to the allowed modify scope?
- [ ] Did the implementer ask for approval before modifying any file outside the modify scope?
- [ ] Was broad read/search activity relevant and focused on the task?

### Implementer-owned validation

- [ ] Did the implementer run validation itself (not outsource its required validation to Codex or the user)?
- [ ] Did the implementer report exact commands run, exit status, and relevant output?
- [ ] Are focused tests, broader regression tests, lint/type checks, and skipped validation clearly distinguished?
- [ ] If a test command exceeded 7 minutes, did the implementer stop it and switch to focused tests?
- [ ] Did the final report avoid claiming full validation when only focused tests ran?
- [ ] Did the focused tests actually exercise the target behavior?
- [ ] If Codex ran independent verification, was it in addition to (not instead of) implementer validation?
- [ ] If the project has no test suite, no lint tool, and no type checker: did the implementer state this explicitly and report at minimum that the code compiles/parses/executes?

### Correctness

- [ ] Does every modified file still compile / pass type checks?
- [ ] Do the existing tests pass? If any tests were broken, did the implementer fix them?
- [ ] Were new tests added for new behavior? If not, does the task packet require them?
- [ ] Is the logic correct? Check for off-by-one errors, null/undefined guards, race conditions, and incorrect conditionals.
- [ ] Are error paths handled? What happens on failure?

### Structural integrity

- [ ] No duplicate function/class/symbol definitions were introduced.
- [ ] No required dataclass/model fields were accidentally removed or renamed.
- [ ] No public signature drift occurred unless the task packet explicitly requested it.
- [ ] No broad structural rewrite happened in files that were expected to receive localized edits.

### Output quality

- [ ] Does the change fully satisfy the task goal as stated in the task packet?
- [ ] Are edge cases handled? What happens with empty input, maximum values, missing data, or boundary conditions?

### Efficiency

- [ ] No N+1 queries, redundant data passes, or unnecessary I/O.
- [ ] No synchronous blocking where async would be appropriate.
- [ ] No unnecessary re-renders or recomputation.

### Architectural consistency

- [ ] New code follows the project's existing patterns (module structure, naming, framework usage).
- [ ] No new abstractions introduced without justification.
- [ ] No deviation from established conventions (export style, import ordering, file naming).
- [ ] Did the implementer inspect existing code/patterns before editing?
- [ ] Did the implementer reuse existing functions/patterns before adding new ones?

### Overengineering

- [ ] No unnecessary abstraction layers, wrapper classes, or indirection.
- [ ] No unused code paths, dead code, or commented-out blocks.
- [ ] No premature generalization ("just in case" extensibility that the task did not ask for).

### Duplicated code / functions

- [ ] No copy-pasted blocks that should be extracted into a shared utility.
- [ ] No reimplementation of existing functions — the implementer must use what already exists in the codebase.

### Unrelated edits

- [ ] No files modified outside the task packet's modify scope without prior approval.
- [ ] Within permitted files, no unrelated lines changed (whitespace-only reformatting, import reordering, unrelated refactors).

### Maintainability risks

- [ ] No new dependencies added without explicit permission.
- [ ] The change is as easy to understand as (or easier than) the code it replaces.
- [ ] No commented-out code, TODO markers without a corresponding issue tracker reference, or debugging artifacts left in.

## Gate outcome

- **PASS**: All items checked. Accept the implementer's output. Report the accepted diff and summary to the user.
- **FAIL**: One or more items unchecked. Do NOT accept the output. Write a correction prompt (see below) and send it in the same session.

## Correction prompt format (canonical)

This is the single canonical structure for correction prompts. Do not use any other format.

A correction prompt must contain these sections in order:

1. **Problem** — Concise description of the defect.
2. **Evidence** — File, diff excerpt, validation output, or acceptance criterion showing the issue.
3. **Required fix** — Exact behavioral or structural correction required.
4. **Allowed files** — Modify scope for the correction (must be within or a subset of the original modify scope).
5. **Validation required** — Focused commands or checks that must be rerun after the fix.
6. **Do not change** — Explicit unrelated areas to avoid touching.
7. **Structural invariants** — Symbols, fields, or signatures that must remain present and non-duplicated after the fix.

**Example correction prompt:**

```
Problem: the --dry-run flag logs actions but still calls executeDeploy().

Evidence: src/cli/deploy.ts line 47 — executeDeploy() is called unconditionally before the dry-run guard on line 52.

Required fix: Move the dry-run check before any I/O calls. When options.dryRun === true, return plannedActions without calling executeDeploy().

Allowed files: src/cli/deploy.ts

Validation required: Run tests/cli/deploy.test.ts and confirm --dry-run produces log output without side effects.

Do not change: src/deploy/engine.ts, src/cli/types.ts

Structural invariants: The DeployOptions interface (src/cli/types.ts line 12) must retain all fields. Do not duplicate the executeDeploy function.
```

After sending the correction prompt, wait for the implementer's response, then run the full diff-review checklist again.
