# Loop-detection policy

This policy defines how Codex detects and responds to implementer loops during an implementer session.

## Definition of a loop

The implementer is looping when it exhibits **repeated non-progress behavior** across two or more consecutive output batches. Indicators include:

- Repeating the same or nearly identical reasoning text across multiple outputs.
- Repeatedly writing to the same file with the same or trivially different content.
- Cycling between two or more states (e.g., writing then reverting, or toggling between two approaches).
- Generating output that does not advance the task state (no new files modified, no new tests passing, no new errors resolved) across consecutive output batches.
- Emitting error messages followed by retries that produce the same error.

A single repeated thought or a brief retry on an error is **not** a loop. The pattern must persist across at least two output batches before loop detection triggers.

## Immediate hard-failure conditions (bypass recovery window)

The self-recovery window applies to ordinary non-progress loops. It does **not** apply when the session appears unhealthy or non-functional.

Intervene immediately when any of these occur:

- Empty or near-empty assistant responses to normal prompts.
- Repeated malformed completion responses missing required evidence.
- Repeated structural corruption after explicit correction (for example duplicate symbols reintroduced).
- Runtime/tool behavior that indicates the session cannot reliably execute tasks.

## Loop-detection inspection interval

Codex reviews each batch of implementer output as it arrives. Each output batch is one inspection interval. Codex does not poll on a timer — it inspects the output that the session naturally produces.

## Loop timing

**Critical: loop timing starts from the first detected non-progress output batch, not from the first line of implementer reasoning output.**

This means:

1. Codex notices during output review that the implementer's latest batch has not progressed since the last batch.
2. This is `T=0` for loop-detection purposes.
3. Codex continues reviewing each subsequent output batch.
4. Each subsequent non-progress output batch increments the loop counter.

## Self-recovery window

After the first loop detection at `T=0`, the implementer is granted a **self-recovery window of 3 consecutive non-progress output batches**. This replaces any wall-clock time threshold — output batches arrive at unpredictable intervals, so counting batches is the only reliable measure.

During the self-recovery window:

- Codex continues reviewing output batches as they arrive.
- Codex does **not** interrupt, does **not** send correction prompts, and does **not** pause the session.
- Codex records each output batch's loop state and whether forward progress has resumed.

### Timestamp assistance

As a supplementary check (not a replacement): if Codex has access to wall-clock timestamps, a session idling with zero output for more than 5 real minutes since the last batch may be treated as equivalent to 3 non-progress batches and intervention may proceed. This is a fallback, not the primary rule — batch count is primary.

### Self-recovery is declared when:

- The implementer modifies a file that advances the task.
- The implementer resolves a previously stuck error.
- The implementer produces output that clearly moves the task toward completion.
- The implementer explicitly acknowledges the issue and describes a new approach.

If self-recovery is detected at any point during the 3-batch window, the loop counter resets. A subsequent loop detection starts a new `T=0` and a new 3-batch window.

## Intervention (after 3 non-progress batches without recovery)

If the implementer produces 3 consecutive non-progress output batches without self-recovery, Codex intervenes:

1. **Pause the implementer session.** Stop any in-progress work.
2. **Diagnose the blocking issue.** Determine the root cause:
   - Is the implementer stuck on an error it cannot resolve?
   - Is it confused by ambiguous instructions in the task packet?
   - Is it trying an approach that is fundamentally unsound?
   - Is it missing context that was not provided in the task packet?
3. **Issue a correction prompt.** Use the canonical correction prompt format defined in `references/diff-review-checklist.md`. The prompt must:
   - Describe the looping behavior Codex observed.
   - State the root cause diagnosis.
   - Give specific, actionable instructions to break out of the loop.
   - If the task packet was ambiguous, clarify the ambiguity.
4. **Reset the loop counter.** After intervention, start a new `T=0` if looping resumes.

## Escalation

If intervention does not break the loop within one additional 3-batch window, or if the implementer has required intervention three times for the same task, Codex escalates to the user:

> "The implementer is stuck on [task description]. I have intervened [N] times. Root cause appears to be [diagnosis]. Do you want me to take over implementation directly, rephrase the task, or try a fresh session?"

Do not escalate silently. Always provide the diagnosis and ask the user for direction.

## Abort thresholds

To avoid long unproductive correction loops, enforce these stop rules:

- Abort the current session after 1 confirmed empty-output response on a normal prompt.
- Abort after 2 consecutive malformed-diff correction rounds with no structural improvement.
- Abort after duplicate-symbol regression reappears after explicit invariant-based correction.

After aborting, start one replacement session and run preflight before real work. If replacement preflight fails, escalate immediately.
