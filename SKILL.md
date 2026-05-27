---
name: codex-dispatch
description: Orchestrate an external implementer session through structured task packets, one session per commit-sized unit, output-batch monitoring, loop detection with batch-count self-recovery, and mandatory diff-review gates after every implementer task. Invoke explicitly via $codex-dispatch or when the user asks Codex to delegate implementation work to an external OpenCode session.
metadata:
  version: "1.0.0"
---

# Codex Dispatch

Codex is the **orchestrator**. An external OpenCode session is the **implementer**.
Codex must NOT perform the implementation itself unless the implementer hits an unrecoverable dead end and the user explicitly asks Codex to take over.

## Setup and context

This skill coordinates two agents: Codex (the orchestrator, running in the main session) and an external OpenCode session (the implementer, model configured at deploy time). The implementer model identity is treated as a configuration detail — this skill refers to it generically as "the implementer" or "the OpenCode session."

The three reference files are part of the quality system and must be loaded on demand:
- `references/implementer-task-packet.md` — Load before drafting any task packet.
- `references/diff-review-checklist.md` — Load before every post-task review.
- `references/loop-detection-policy.md` — Load when monitoring detects a potential loop.
- `references/worked-example.md` — Optional; load to see a complete end-to-end trace.

## When to use and when NOT to use

### Use this skill when:
- The task involves multiple files, new behavior, a refactor, or cross-cutting changes.
- The user explicitly asks Codex to delegate implementation to an external session.
- You need strict commit-scoped discipline with an audit trail.
- The codebase has tests, lint, or type-checking infrastructure (or at minimum compiles).
- The task is estimated at more than ~20 lines of net change or spans more than 2 files.

### Do NOT orchestrate — implement directly when:
- The task is a single-line fix, a typo, a config value change, or a documentation edit under 5 lines.
- The user explicitly says "just do it yourself," "don't delegate," or "Codex, you implement this."
- The orchestration token overhead clearly exceeds the implementation cost.
- The codebase has no tests, no lint, no type-checker, and no way to compile — validation evidence will be impossible to collect.

### Task complexity tiering

Use this decision tree before dispatching:

| Tier | Criteria | Path |
|------|----------|------|
| **Lightweight** | ≤1 file modified, ≤10 lines of net change, no new tests required, no structural changes | Skip loop detection. Use simplified diff review (scope + correctness + validation only). Simplified evidence report: files changed, validation ran, exit status. |
| **Standard** | Multi-file, new behavior, refactors, structural changes, new tests required | Full orchestration pipeline: task packet, preflight, monitoring, loop detection, full diff-review checklist, correction loop. |

When in doubt between tiers, default to Standard. Lightweight tasks that fail simplified review revert to the Standard path.

#### Lightweight simplified diff review (inline checklist)

For Lightweight tasks only, skip the full `references/diff-review-checklist.md` and apply this 5-item checklist instead:

- [ ] Scope — modifications stayed within the approved modify scope.
- [ ] Correctness — the code compiles/parses, and the stated behavior change is present.
- [ ] Validation — at least one validation command was run (or compilation checked) and exit status reported.
- [ ] Structural integrity — no duplicate definitions introduced, no existing functionality removed.
- [ ] No unrelated edits — no out-of-scope files or lines modified.

If any item fails, the Lightweight path is voided and the task reverts to the Standard path with the full checklist.

## Orchestration workflow (high-level)

Use this state model and do not skip states:

`Packet drafted -> pre-dispatch quality gate -> session assigned -> implementation monitored -> completion evidence received -> diff review -> correction loop if needed -> accepted or escalated`.

If the implementer stops before full completion (e.g., runs out of context, hits an environment error, produces only a partial diff), the state is **partial completion**. See the partial completion section below for the continuation path.

### 1. Prepare the implementer task packet

Load `references/implementer-task-packet.md` for the canonical packet format before drafting the first task.

At minimum, every packet must specify: goal, read/search scope, modify scope, constraints, expected output, and project context when useful.

**Never** give the implementer underspecified or ambiguous requests. The packet is the contract.

### 2. Pre-dispatch quality gate

Before sending the task, Codex must verify the packet is:

- Bounded — read/search scope and modify scope are explicit.
- Testable — success can be checked through stated acceptance criteria and validation.
- Unambiguous — the implementer does not need to infer the core request.
- Properly sized — one coherent behavior change or refactor unit, not a broad multi-system bundle unless the user specifically requested that shape.
- Phased — the prompt breaks the commit-sized unit into ordered phases with clear outcomes, so the implementer does not receive one overloaded instruction block.
- Scope-safe — any edit outside the modify scope will be a review failure unless Codex approves a scope expansion first.
- Session-safe — the task belongs to the current commit-sized unit of work, or a new session is started for a new commit-sized unit.
- Structure-safe — the packet includes explicit invariants for files that must not be structurally rewritten (for example: no duplicate helper definitions, no dropped dataclass fields, no signature drift unless requested).

If the packet fails this gate, revise it before dispatch. Do not use the implementer to clarify a vague assignment.

### 3. Session preflight (mandatory before first real packet and after any replacement session)

Run this health check sequence:

1. Deterministic handshake: "Reply exactly: `OK_PRECHECK_v1.0.0`".
2. Tiny bounded action in an allowed scratch area or read-only file inspection with a compact report.
3. Confirm non-empty assistant output and coherent tool evidence.

If any preflight step fails (empty assistant output, no-op response, or malformed evidence), mark the session unhealthy and do not dispatch the commit packet.

### 4. Dispatch the task

Send the task packet to the implementer session assigned to the current commit-sized unit of work. Codex observes the output.

A commit-sized unit of work means the coherent set of changes intended to land together in one commit, whether or not `git commit` has already been run.

Session discipline:

- Use one and only one session for each commit-sized unit of work.
- Do not split one commit's implementation or corrections across multiple sessions.
- Do not reuse the same session for unrelated commits.
- Start a replacement session only if the current session is completely unresponsive or the implementer confirms it cannot proceed; record the reason and treat the replacement as continuity for the same commit.
- Before using a replacement session for real work, run the mandatory preflight again.

### 5. Output monitoring

Codex does not have a background thread or event loop, so monitoring works as follows:

- Review each batch of implementer output as it arrives in the session.
- Between output batches, check for forward progress, scope adherence, structural coherence, and session health.
- The monitoring checks are:
    - Is the implementer making forward progress toward completing the task?
    - Is the output staying on-topic (no unrelated edits, no file-tree drift)?
    - Are there early signs of looping (repeated reasoning, repeated writes to the same file)?
    - Is the implementer's approach architecturally sound given the codebase context?
    - Is the implementer staying inside the declared read/search and modify scopes?
    - Is the implementation still aligned with the acceptance criteria and expected validation?
    - Is output structurally coherent (no duplicated definitions, no large unintended rewrites)?
    - Is the session healthy (non-empty assistant responses with usable evidence)?
- The self-recovery window in loop detection is measured in output batches (3 consecutive non-progress batches), not wall-clock time. See `references/loop-detection-policy.md` for the full timing model.

### 6. Loop detection and recovery

Load `references/loop-detection-policy.md` when a potential loop is detected. This skill does not duplicate loop signals or recovery procedures.

Key principle: loop timing starts from the first detected non-progress output batch, not from the first line of implementer reasoning. A self-recovery window of 3 consecutive non-progress batches is granted before intervention. Hard-failure signals (empty output, malformed responses, repeated structural corruption) bypass the window and trigger immediate intervention. See the reference file for the timestamp-based fallback.

### 7. Completion evidence report

Before Codex accepts that an implementer task is complete, the implementer must return a compact evidence report:

- Files changed.
- Confirmation that changes stayed inside the approved modify scope, or a list of scope deviations.
- Acceptance criteria satisfied.
- Exact validation commands run, exit status for each, and relevant output excerpts.
- Breakdown: focused tests, broader regression tests, lint/type checks, and skipped or incomplete validation (with reasons).
- Known risks, assumptions, or follow-up work.

Claims without evidence are not sufficient for acceptance. The implementer must not claim validation passed if tests were skipped without a reported reason.

### 8. Diff-review gate (mandatory after every implementer task)

Load `references/diff-review-checklist.md` and apply it in full. Block acceptance until every item is checked. This skill does not duplicate the checklist.

The review must compare the diff against the task packet's acceptance contract: requested behavior, modify scope, "must not change" constraints, validation expectations, and completion evidence.

Findings are classified by severity: **blocker**, **major**, **minor**, **note**. Codex must distinguish pre-existing failures from failures introduced by the implementer.

If the review finds issues, Codex must **prompt corrections in the same session** that produced the original output. Do not start a new session for corrections unless the original session is completely unresponsive.

When corrections are requested, restate file invariants explicitly. Do not rely on incremental "fix just this line" prompts if file structure has already drifted.

The canonical correction prompt structure is defined in `references/diff-review-checklist.md`.

### 9. Partial completion (incomplete work)

If the implementer produces output that covers only some phases of the task (e.g., inspected files but did not implement, or implemented but did not validate, or produced a partial diff), do not treat this as a correction loop. The problem is incompleteness, not incorrectness.

Partial completion handling:

1. Acknowledge what evidence was received and what is missing.
2. Issue a **continuation prompt** (not a correction prompt) in the same session:
   - State which phases are complete and which are outstanding.
   - Re-state the remaining phase objectives from the original task packet.
   - Re-state any file invariants.
   - Set a new expected output scope for the continuation.
3. Continue monitoring. Do not rerun the diff review until the implementer declares full completion.
4. If the implementer cannot continue (confirms it is stuck or session is unresponsive), escalate to the user.

### 10. Correction loop

If corrections are needed:

1. Codex writes a targeted correction prompt (using the structure in `references/diff-review-checklist.md`).
2. Codex sends that prompt in the same session.
3. After the implementer responds, run the full diff-review gate again.
4. Repeat until the review gate passes or Codex determines the implementer is stuck (escalate to user).

### 11. Quality monitoring dimensions

Throughout the entire orchestration cycle, Codex must monitor for:

| Dimension | What to watch for |
|-----------|-------------------|
| Output quality | Does the change meet the stated requirements? Are edge cases handled? |
| Correctness | Does the code compile / pass type checks / pass existing tests? |
| Efficiency | Is the solution reasonably efficient? No obvious N+1 queries, redundant passes, or wasted work? |
| Architectural consistency | Does the change follow the project's existing patterns, naming conventions, and module boundaries? |
| Bugs | Any off-by-one errors, null-pointer risks, race conditions, or logic flaws? |
| Overengineering | Has the implementer added unnecessary abstraction, unused code paths, or premature generalization? |
| Duplicated code / functions | Did the implementer reimplement something that already exists? Did it copy-paste instead of extracting shared logic? |
| Unrelated edits | Did the implementer modify files or regions that are unrelated to the task? |
| Maintainability risks | Are new dependencies introduced unnecessarily? Is the code harder to understand than what it replaced? |
| Scope discipline | Did the implementer stay within the approved read/search and modify scopes? |
| Evidence quality | Are completion and validation claims backed by exact commands, exit statuses, and relevant output? |
| Baseline awareness | Are failures identified as pre-existing or introduced by the implementer? |

If any dimension raises a flag, treat it as a review-gate failure and proceed to the correction loop.

## Pre-task baseline check (recommended)

Before dispatching the first task packet, run the project's test suite once to establish a baseline pass rate:

1. Run the relevant test command (e.g., `npm test`, `pytest`, `cargo test`).
2. Record the pass/fail/total counts and any pre-existing failures.
3. Store this baseline in the orchestration log.

This makes the diff-review requirement "distinguish pre-existing failures from failures introduced by the implementer" actually achievable. Without a baseline, pre-existing failures and implementer-introduced failures are indistinguishable.

If the test suite is already broken before dispatching, document this in the task packet's project context so the implementer knows not to expect a green baseline.

## Abort and fallback policy

Codex must stop degraded orchestration early:

- Abort the current session after 1 confirmed empty-output response on a normal prompt.
- Abort after 2 consecutive malformed-diff correction rounds that do not improve structural correctness.
- Abort after a repeated duplicate-symbol regression that reappears after explicit correction.

After abort:

1. Start one replacement session for the same commit-sized unit.
2. Run mandatory preflight.
3. If replacement preflight fails or immediately degrades, escalate to user with diagnosis and recommend takeover or task reshaping.

### Escalation

When escalating, always provide a diagnosis. The escalation target is the human who triggered the orchestration. If the task was auto-dispatched, escalation means pausing and waiting for explicit human direction.

Do not escalate silently. State the issue, the diagnosis, and ask for direction. Example:

> "The implementer is stuck on [task description]. I have intervened [N] times. Root cause appears to be [diagnosis]. Do you want me to take over implementation directly, rephrase the task, or try a fresh session?"

## Implementer-owned validation

The implementer is responsible for running its own validation before reporting completion. The implementer must not outsource its required validation to Codex or the user unless it is truly blocked (e.g., missing credentials, environment not configured, permissions error). Codex may run independent verification when needed to audit claims, resolve uncertainty, or protect quality — but this does not excuse missing implementer validation.

The full validation ownership rules and the implementer-facing constraints are in `references/implementer-task-packet.md`. The diff-review checklist for auditing validation is in `references/diff-review-checklist.md`.

## Task sizing and commit boundaries

Codex should split orchestration into commit-sized units that can be reviewed, validated, and accepted independently.

Prefer:

- One behavior change per implementer task when possible.
- Splitting risky refactors from feature changes.
- Splitting implementation from cleanup when the patch grows too large.
- Avoiding multi-system tasks unless the user explicitly requests them or the codebase requires them.

For each commit-sized unit, Codex must keep one session as the authoritative implementation context. Corrections, validation reruns, and final evidence for that commit must stay in that session.

Each commit-sized unit must be split into explicit phases in the prompt. Phases should be ordered, bounded, and outcome-oriented, for example:

- Phase 1: inspect relevant files and identify existing patterns.
- Phase 2: implement the scoped change.
- Phase 3: run focused validation and fix failures.
- Phase 4: run broader checks where appropriate and produce the completion evidence report.

The phase split is a prompt-quality requirement, not permission to use multiple sessions. All phases for the same commit-sized unit remain in the same session.

## Orchestration log

Codex should maintain a compact orchestration log while supervising the implementer:

- Skill version used (from frontmatter metadata).
- Baseline test pass rate (pre-dispatch).
- Task packet sent.
- Session identity or continuity note for the current commit-sized unit.
- Monitoring observations that affect quality, scope, or progress.
- Loop detections and recovery prompts.
- Completion evidence received.
- Diff-review findings by severity.
- Correction prompts and outcomes.
- Partial completion continuation prompts (if any).
- Final acceptance or escalation rationale.

**Example log entry (single task, accepted):**

```
[2026-05-27 14:30] Orchestrator v1.0.0 | Task: add --verbose flag to CLI
[14:30] Baseline: 14/14 tests passing, lint clean, type-check clean
[14:31] Preflight: OK_PRECHECK_v1.0.0 passed, health confirmed
[14:32] Dispatched packet: src/cli/main.ts, src/cli/types.ts, tests/cli/main.test.ts
[14:33] Batch 1: inspected src/cli/main.ts, src/cli/types.ts, src/logger/index.ts — on-topic
[14:34] Batch 2: implemented --verbose flag, added test — within scope, pattern-matched
[14:35] Batch 3: vitest run 2/2, tsc clean — no issues
[14:36] Completion evidence: 3 files changed, 2 tests passed, type-check clean
[14:37] Diff review: PASS — scope: ok, validation: ok, correctness: ok, structural: ok
[14:37] ACCEPTED
```

## Orchestrator efficiency

Codex should orchestrate efficiently. Prefer:

- Small bounded task packets.
- Focused file inspection before broad repo scans.
- Focused validation before broad test suites when appropriate.
- Concise correction prompts.
- Avoiding repeated explanations and duplicate analysis already established in the session.

Quality has priority over speed. Do not skip diff review, validation review, architectural checks, or correction loops just to save tokens. Implementer-facing efficiency instructions live in `references/implementer-task-packet.md`.

## Reference fallback

The reference files are part of the quality system. If a required reference file cannot be loaded, Codex must not proceed casually.

Fallback behavior:

- If `references/implementer-task-packet.md` is unavailable: create a minimal packet containing goal, read/search scope, modify scope, constraints, acceptance criteria, validation expectations, expected output (files changed, commands run, exit statuses, evidence), and "must not change" items. Include the implementer-owned validation rules: do not outsource validation, report exact commands and exit statuses, distinguish focused/broad/lint/skipped.
- If `references/diff-review-checklist.md` is unavailable: apply the quality monitoring dimensions table in this skill and block acceptance on unresolved blocker or major findings.
- If `references/loop-detection-policy.md` is unavailable: apply the loop timing principle (T=0 starts from first non-progress output batch, 3 consecutive non-progress batch self-recovery window, hard-failure signals trigger immediate intervention) described in this skill.
- Report any missing reference file in the orchestration log.

## References

- `references/implementer-task-packet.md` — Canonical task-packet format, constraints, and validation ownership rules.
- `references/diff-review-checklist.md` — Step-by-step post-task review procedure, correction prompt structure, and severity taxonomy.
- `references/loop-detection-policy.md` — Full loop-detection definition, timing model, and recovery rules.
- `references/worked-example.md` — Complete end-to-end orchestration trace.
