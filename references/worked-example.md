# Worked example: end-to-end orchestration trace

This is a complete trace of a realistic orchestration session, annotated with decision points.

## Scenario

Task: Add a `--verbose` flag to the project CLI that controls log level output.

Task packet sent is annotated. Monitoring observations, correction, and acceptance are shown inline.

---

## Phase 1: Task packet (drafted and quality-gated)

```
Goal: Add a --verbose flag to the CLI (src/cli/main.ts) that, when set,
enables debug-level logging output via the existing Logger utility.

Read/search scope:
- src/cli/main.ts — for CLI argument parsing patterns
- src/cli/types.ts — for existing CLI option interface
- src/logger/index.ts — for Logger API and log levels
- tests/cli/ — for existing test conventions
- package.json — for script conventions

Modify scope:
- src/cli/main.ts
- src/cli/types.ts (only if the CLI options interface needs extension)
- tests/cli/main.test.ts (only if test file already exists; create otherwise)

Constraints:
[Standard constraint checklist from implementer-task-packet.md]
- Do not change the Logger API in src/logger/index.ts.
- The --verbose flag must be a boolean; no --verbosity=<level> alternative.
- Default log level when --verbose is absent must remain unchanged.

Expected output:
- Files changed, summary, full diff.
- Validation: focused tests (verbose flag behavior), broader tests (any existing CLI tests),
  lint/type checks, skipped validation with reasons.
- Structural integrity: no duplicate definitions, no Logger API changes, no unintended CLI option
  removals.

Project context:
- TypeScript project using yargs for CLI argument parsing.
- Logger uses a singleton pattern; log level is set via Logger.setLevel().
- Tests use Vitest.
- The existing --help flag pattern in main.ts is the reference for adding new flags.

Phases:
1. Inspect src/cli/main.ts, src/cli/types.ts, src/logger/index.ts, tests/cli/main.test.ts.
2. Implement the --verbose flag following existing patterns.
3. Run focused tests and fix any failures.
4. Run broader CLI tests and lint, then produce the completion evidence report.
```

Preflight: `OK_PRECHECK_v1.0.0` ✓, file inspection of src/cli/main.ts ✓, health confirmed ✓

Pre-mortem (orchestrator internal): "Most likely failure: the implementer tries to modify src/logger/index.ts to add a verbose() method instead of calling the existing setLevel() API. Mitigation: the Logger API constraint in the packet explicitly forbids this."

---

## Phase 2: Monitoring (output batch reviews)

**Batch 1:** Implementer reads src/cli/main.ts, src/cli/types.ts, src/logger/index.ts. Output is focused and on-topic. ✓

**Batch 2:** Implementer adds `verbose: boolean` to CLI options interface, adds `--verbose` flag to yargs config, adds `if (argv.verbose) Logger.setLevel('debug')` after argument parsing. Stays within modify scope. ✓

**Batch 3:** Implementer runs `npx vitest run tests/cli/main.test.ts`. Reports 2/2 passing (one existing test, one new test for verbose behavior). Runs `npx tsc --noEmit` — passes. ✓

**Batch 4:** Implementer produces completion evidence report. No loop signals detected. ✓

---

## Phase 3: Completion evidence received

```
Files changed:
- src/cli/main.ts: Added --verbose flag and log level adjustment (lines 45-51)
- src/cli/types.ts: Added verbose: boolean to CliOptions interface (line 12)
- tests/cli/main.test.ts: Added test for verbose flag behavior (lines 78-92)

Scope compliance: All changes within approved modify scope.

Acceptance criteria satisfied:
- --verbose flag added ✓
- Debug logging enabled when flag set ✓
- Default behavior unchanged when flag absent ✓

Validation:
- Focused test: npx vitest run tests/cli/main.test.ts — 2/2 passed (exit 0)
  Output: "verbose flag enables debug logging" ✓, "default log level unchanged" ✓
- Broader tests: npx vitest run — 14/14 passed (exit 0)
- Type check: npx tsc --noEmit — no errors (exit 0)
- Lint: npx eslint src/cli/ --ext .ts — no errors (exit 0)
- Skipped: none

Structural integrity:
- No duplicate definitions introduced.
- Logger API unchanged (confirmed via diff).
- No existing CLI options removed or altered.
```

---

## Phase 4: Diff review

Checklist applied from `references/diff-review-checklist.md`.

Scope compliance: ✓ | Validation: ✓ | Correctness: ✓ | Structural integrity: ✓ |
Output quality: ✓ | Efficiency: ✓ | Architectural consistency: ✓ | Overengineering: ✓ |
Duplicated code: ✓ | Unrelated edits: ✓ | Maintainability: ✓

**Gate outcome: PASS.** Accepted. Reported to user.

---

## Decision point annotations

1. **Why this task was Standard tier, not Lightweight:** though only 3 files changed and ~10 net lines, it touched a public interface (CLI options type), required a new test, and modified behavior that could regress. Lightweight would have been appropriate if it were purely a variable rename.

2. **Why monitoring was unobtrusive here:** the implementer produced 4 clean output batches over ~2 minutes. No loops, no scope creep, no structural corruption. This is the expected happy path — monitoring is insurance, not overhead.

3. **Why no correction loop was needed:** the implementer followed the observe-before-editing principle, matched existing patterns, ran all validation, and produced a complete evidence report. The diff review found nothing to correct.

4. **What would trigger correction in a similar task:** adding the flag without the interface change (TypeScript compile error), calling Logger.debug() directly instead of setLevel('debug'), modifying src/logger/index.ts, shipping without a test, or claiming validation passed without running commands.

---

## Orchestration log (matching the log format defined in SKILL.md)

```
[2026-05-27 14:30] Orchestrator v1.0.0 | Task: add --verbose flag to CLI
[14:30] Baseline: 14/14 tests passing, lint clean, type-check clean
[14:31] Preflight: OK_PRECHECK_v1.0.0 passed, health confirmed
[14:31] Pre-mortem: Logger API misuse — mitigated by constraint in packet
[14:32] Dispatched packet: src/cli/main.ts, src/cli/types.ts, tests/cli/main.test.ts
[14:33] Batch 1: inspected main.ts, types.ts, logger/index.ts — on-topic
[14:34] Batch 2: implemented --verbose flag, added test — within scope, pattern-matched
[14:35] Batch 3: vitest run 2/2, tsc clean — no issues
[14:36] Completion evidence: 3 files changed, 2 tests passed, type-check clean, lint clean
[14:37] Diff review: PASS — scope: ok, validation: ok, correctness: ok, structural: ok
[14:37] ACCEPTED
```
