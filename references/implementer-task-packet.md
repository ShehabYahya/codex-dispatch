# Implementer task packet

Every task dispatched to the implementer must follow this format.

## Packet structure

A task packet is a single message sent to the implementer session. It must contain the following sections in order:

### 1. Goal (required)

One sentence stating the outcome the implementer must achieve.

**Example:**
```
Add a --dry-run flag to the deploy CLI that prints the planned actions without executing them.
```

### 2. Read/search scope (required)

List the files, directories, or repo areas the implementer may inspect to understand existing behavior and patterns.

The implementer may read/search more broadly than the modify scope when necessary, but broad inspection must remain relevant to the task.

**Example:**
```
You may inspect:
- src/cli/ — for existing CLI flag patterns and argument parsing
- src/deploy/ — for the deploy execution pipeline
- tests/cli/ — for existing test conventions
- package.json — for dependency and script conventions
```

### 3. Modify scope (required)

List the exact files the implementer may edit.

The implementer must not modify files outside this scope unless it asks for approval and explains why the extra file is required.

**Example:**
```
You may only modify:
- src/cli/deploy.ts
- src/cli/types.ts
- tests/cli/deploy.test.ts
- package.json (only if adding a new dependency — ask first)
```

### 4. Constraints (required)

The implementer must follow every constraint. Use bullet points.

**Required constraints checklist:**

- Do not add comments unless the codebase already uses comments in every function.
- Do not add or update docstrings unless the codebase convention requires them.
- Do not introduce new dependencies without explicit permission.
- Follow existing code style, naming conventions, and module boundaries.
- Do not modify files outside the listed modify scope. If you believe a file outside the modify scope must be changed, ask for approval and explain why.
- Do not create READMEs, CHANGELOGs, or documentation files unless explicitly asked.
- Do not remove or restructure existing code that is unrelated to the task.
- Preserve structural invariants explicitly named in the packet (for example: no duplicate helper definitions, no dropped dataclass fields, no function signature drift unless requested).
- Before making edits, inspect relevant existing code and patterns. Do not start by creating new helpers, abstractions, files, or architecture before checking whether existing code already provides the needed pattern or function.
- Prefer reusing existing functions, utilities, and patterns before adding new ones.

**Validation ownership rules (required in every packet):**

- You are responsible for running validation commands yourself. Do not outsource validation back to Codex or the user unless you are truly blocked (missing credentials, environment not configured, permissions error).
- Report exact validation commands run, exit status, and relevant output.
- Distinguish focused tests, broader regression tests, lint/type checks, and any skipped or incomplete validation.
- Do not claim validation passed if tests were skipped without a reported reason.
- Report any test failures with the full error output.
- If the project has no test suite, no lint tool, and no type checker: state this explicitly in your report. Validation then defaults to: (a) confirming the code compiles/parses/executes without error, (b) manual inspection of changed logic paths, and (c) clearly noting that automated validation was unavailable.

**Task-specific constraints (add as needed):**
- [Any additional constraints specific to this task.]

### 5. Expected output (required)

What the implementer must return when the task is complete. Be specific.

**Example:**
```
Return:
1. A summary of every file modified and what changed.
2. The full diff of all changes.
3. Validation report with exact commands run, exit status, and output:
   - Focused tests (exercising changed behavior)
   - Broader regression tests
   - Lint/type checks
   - Any skipped validation and the reason
   - If no test suite/lint/type-checker exists, state this explicitly and report compilation/execution results
4. If a test command exceeded 7 minutes, report what was stopped and what focused tests ran instead.
5. Any warnings or concerns you have about the changes.
6. Explicit structural integrity confirmation:
   - No duplicate symbol definitions introduced.
   - No required fields/functions were removed unintentionally.
   - Public signatures remain unchanged unless requested.
```

### 6. Project context (optional but recommended)

Key facts the implementer needs to understand before starting. Keep this short — only what is not obvious from the codebase.

**Example:**
```
Context:
- This project uses React 18 with TypeScript strict mode.
- State management is Zustand — do not introduce Redux or Context.
- Tests use Vitest, not Jest.
- The deploy flow is idempotent — every change must preserve that property.
```

### 7. Pre-mortem (required for orchestrator, not sent to implementer)

Before dispatching the packet, the orchestrator must answer this question in one sentence:

> "What is the most likely way this task fails?"

This forces adversarial thinking and naturally improves packet quality. The answer must be written in the orchestration log (it is not sent to the implementer). If the answer reveals a gap in the packet (missing scope constraint, ambiguous acceptance criterion, unstated invariant), fix the packet before dispatch.

## Session preflight (orchestrator responsibility)

Before the first real implementation packet in a session (and after any replacement session), the orchestrator must run:

1. Deterministic handshake prompt requiring an exact short response.
2. Tiny bounded preflight action with compact evidence output.
3. Health confirmation: non-empty assistant output and coherent evidence.

If preflight fails, do not dispatch the real task packet in that session.

## Validation time limit

The implementer must run relevant tests/checks itself.

If any single test command runs longer than 7 minutes:

1. Stop that command if possible.
2. Do not keep waiting indefinitely.
3. Switch to narrower focused tests that directly exercise the changed behavior.
4. Report that the broader command exceeded the 7-minute limit.
5. Include the focused commands that were run instead.
6. Do not claim full validation passed if only focused validation completed.

## Implementer efficiency instructions

The orchestrator must include these instructions in every task packet:

- Be efficient with context, tool calls, and test selection.
- Start with focused inspection and targeted tests before broad scans or full test suites.
- Avoid broad scans and full test suites unless the task scope demands them.
- Avoid verbose status reports that do not add new evidence.
- Quality and correctness outrank speed.

## Anti-patterns

Never do any of the following in a task packet:

- Ask the implementer to "figure out" the read/search scope or modify scope — provide both explicitly.
- Give the implementer multiple unrelated tasks in one packet.
- Ask the implementer to decide architecture or design patterns — specify them.
- Use vague language like "improve," "clean up," or "make better" without concrete criteria.
- Omit the constraints section.
- Omit structural invariants for sensitive files where accidental rewrites are high risk.
