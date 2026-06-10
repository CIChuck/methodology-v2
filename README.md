# AI-Assisted Development Methodology Baseline

This repository is a seed baseline for building software products with AI-assisted coding agents
such as Codex, Claude Code, and similar tools.

The baseline is meant to be cloned, initialized for a specific product, and then evolved with a
human team member and one or more AI agents. The method emphasizes documented authority,
traceability, explicit phase boundaries, planned tests, code review, remediation, and as-built
documentation close-out.

## If You Read Three Files

For first orientation, read these files in order:

```text
AGENTS.md
docs/methodology/constitution/gendev.md
docs/practitioner-guide/README.md
```

`AGENTS.md` tells AI coding agents how to enter the repository. The constitution defines the
controlling method. The practitioner guide explains how humans and agents use the method in
practice.

## Repository Model

```text
docs/methodology/
  Reusable methodology authority, templates, and agent guidance.

docs/project/
  Active project authority after initialization. This directory is created by
  scripts/init-project.sh and should govern the product being built.

docs/project-template/
  Clone-time skeleton used by the initialization script.

docs/practitioner-guide/
  Field manual for technical practitioners using the methodology with AI coding agents.

docs/examples/
  Non-authoritative examples and future worked examples.
```

## Core Method

The controlling standard is:

```text
docs/methodology/constitution/gendev.md
```

For meaningful implementation, agents and humans should work through this chain:

```text
vision
PRD
architecture
governance/security
phase build plan
tactical implementation plan
construction directive
implementation and tests
code review
remediation
as-built close-out
traceability update
```

Small projects may combine artifacts, but the content still needs to exist.

## Initialize A Project

From a fresh clone:

```bash
./scripts/init-project.sh "My Product Name"
```

This creates `docs/project/` with starter authority documents copied from
`docs/methodology/templates/`.

If `docs/project/` already exists, the script stops unless `--force` is supplied:

```bash
./scripts/init-project.sh --force "My Product Name"
```

## Agent Entry Point

Root-level agent instructions live in:

```text
AGENTS.md
```

AI coding agents should read that file first, then follow the constitution and the active project
documents under `docs/project/`.

## Reusable Assets

- Constitution: `docs/methodology/constitution/gendev.md`
- Operating workflow: `docs/methodology/guides/agentic-development-workflow.md`
- Gate model: `docs/methodology/guides/gates.md`
- Collaboration modes: `docs/methodology/guides/collaboration-modes.md`
- Human-agent loop: `docs/methodology/guides/human-agent-collaboration-loop.md`
- Start/next-step protocol: `docs/methodology/guides/start-and-next-step-protocol.md`
- Gate transition protocol: `docs/methodology/guides/gate-transition-protocol.md`
- Amendment/regression protocol: `docs/methodology/guides/amendment-and-regression-protocol.md`
- Enforcement contract: `docs/methodology/guides/enforcement-contract.md`
- Human approval protocol: `docs/methodology/guides/human-approval-protocol.md`
- Sub-agent coordination protocol: `docs/methodology/guides/subagent-coordination-protocol.md`
- Artifact collaboration protocol: `docs/methodology/guides/artifact-collaboration-protocol.md`
- Production operations protocol: `docs/methodology/guides/production-operations-protocol.md`
- Orchestration validation: `docs/methodology/guides/orchestration-validation.md`
- Practitioner guide: `docs/practitioner-guide/`
- Templates: `docs/methodology/templates/`
- Dev-skill guidance: `docs/methodology/dev-skills/`
- Agent role playbooks: `docs/methodology/agents/roles/`
- Sample agent instructions: `docs/methodology/agents/sample-agents.md`
- Examples: `docs/examples/`
- Methodology checker: `scripts/check-methodology.sh`
- Methodology guard: `scripts/methodology-guard.sh`
- Methodology metrics: `scripts/methodology-metrics.sh`
- Optional hook installer: `scripts/install-hooks.sh`

## Validate The Methodology State

Before implementation, phase close-out, or handoff, run:

```bash
./scripts/check-methodology.sh
```

On an uninitialized baseline, the checker reports that `docs/project/` does not exist yet. After
initialization, it checks the active project structure, manifest paths, approval-state invariants,
ready/accepted artifact placeholders, phase planning sections, and traceability evidence signals.

For diff-aware enforcement, use the guard wrapper:

```bash
./scripts/methodology-guard.sh --staged
```

To install the optional local pre-commit hook:

```bash
./scripts/install-hooks.sh
```

The repository also includes a GitHub Actions reference binding at
`.github/workflows/methodology.yml`.

To generate an on-demand process and value metrics report for an initialized project:

```bash
./scripts/methodology-metrics.sh docs/project
```

## Orchestration Layer

The orchestration layer is procedural documentation. It tells a human team member, lead agent, and
sub-agents how to collaborate from `Let's begin` through production operation.

The core behaviors are:

```text
set collaboration mode
orient to project.yaml and current gate
ask material questions
draft the next artifact
review and revise with the human
record lightweight approvals
preserve gate history in docs/project/approvals/gate-log.md
coordinate bounded sub-agent work
advance gates only with required evidence
prepare deployment, rollback, monitoring, and runbook procedures
```

Tool-specific addenda for Codex, Claude Code, Cursor, or other systems may be added later. The core
methodology remains tool-agnostic.

## Current Status

This repository is a methodology baseline, not an implemented product. Product-specific source code,
tests, configuration, CI, deployment, and runtime commands should be added by the initialized project
as its architecture and phase plans mature.

Current methodology version: `0.1.0-baseline`

This is a pre-1.0 baseline. The hardening plan in `docs/assessment/gendev-hardening-plan.md`
identifies the work needed before a `1.0.0` methodology release.

## License

This repository uses a split license:

- Documentation is licensed under Creative Commons Attribution 4.0 International (`CC-BY-4.0`).
- Scripts and source code are licensed under the MIT License (`MIT`).

See `LICENSE`, `LICENSE-CC-BY-4.0`, and `LICENSE-MIT`.
