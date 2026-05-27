# codex-dispatch

A Codex skill that orchestrates an external implementer session with structured task packets, loop detection, and mandatory diff-review gates.

## What it does

Codex acts as the orchestrator. An external OpenCode session acts as the implementer. Every task goes through a pipeline: the orchestrator prepares a structured task packet with explicit scope, constraints, and acceptance criteria; runs a session preflight health check; dispatches the packet; monitors output batches for loops and scope creep; collects a completion evidence report with exact validation commands and exit codes; then runs a mandatory diff-review gate before accepting or escalating. Three reference files define the packet format, the diff-review checklist (including the canonical correction prompt structure), and the loop-detection policy. A fourth reference file provides a complete worked example trace.

## Installation

After installing, restart Codex so it reloads skill metadata.

### Manual (global)

```bash
git clone https://github.com/ShehabYahya/codex-dispatch.git
cp -r codex-dispatch ~/.codex/skills/codex-dispatch
```

### Per-project (local)

```bash
mkdir -p .codex/skills
cp -r codex-dispatch .codex/skills/codex-dispatch
```

### Via install script

```bash
./install.sh
```

### Via $skill-installer (if available)

```
$skill-installer ShehabYahya/codex-dispatch
```

## Configuration

The only configurable item is the implementer backend. Edit the `backend:` field in `agents/openai.yaml`:

```yaml
backend: "OpenCode (opencode-go/deepseek-v4-pro)"
```

Swap this line to point to a different model or session type. All other files are model-agnostic and require no changes.

## Usage

Invoke explicitly with `$codex-dispatch`, or implicitly by asking Codex to delegate implementation work to an external session. See `references/worked-example.md` for a full end-to-end trace from packet drafting through monitoring, evidence collection, diff review, and acceptance.

## Repository structure

```
codex-dispatch/
├── SKILL.md                                  — Orchestration workflow, tiering, and policies
├── LICENSE.txt                               — Apache 2.0
├── README.md                                 — This file
├── CHANGELOG.md                              — Version history
├── install.sh                                — POSIX install script
├── .gitignore                                — Git ignore rules
├── agents/
│   └── openai.yaml                           — UI metadata and backend configuration
├── assets/
│   ├── orchestrator.png                      — Small icon
│   └── orchestrator-small.svg                — Large icon
└── references/
    ├── implementer-task-packet.md             — Canonical task packet format and constraints
    ├── diff-review-checklist.md               — Post-task review procedure and correction prompt format
    ├── loop-detection-policy.md               — Loop definition, timing, and recovery rules
    └── worked-example.md                      — Complete annotated orchestration trace
```

## License

Apache 2.0. See [LICENSE.txt](LICENSE.txt).
