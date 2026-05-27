## [1.0.0] — 2026-05-27

Initial release.

- Orchestration state machine: packet → preflight → dispatch → monitoring → completion evidence → diff review → correction loop → accepted/escalated.
- Lightweight and Standard task complexity tiers with defined review paths.
- Batch-count loop detection (3 consecutive non-progress batches) with timestamp fallback.
- Partial completion continuation path (distinct from correction loop).
- Pre-mortem requirement in task packet template.
- Pre-task baseline check before dispatch.
- Canonical correction prompt format (7-field structure).
- Reference fallback behavior when any reference file is unavailable.
- Orchestration log format with example entry.
