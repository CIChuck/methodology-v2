# AI-Assisted Development Methodology Baseline

This repository is a seed baseline for building software products with AI-assisted coding agents
such as Codex, Claude Code, and similar tools.

The baseline is meant to be cloned, initialized for a specific product, and then evolved with a
human team member and one or more AI agents. The method emphasizes documented authority,
traceability, explicit phase boundaries, planned tests, code review, remediation, and as-built
documentation close-out.

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

## Validate The Methodology State

Before implementation, phase close-out, or handoff, run:

```bash
./scripts/check-methodology.sh
```

On an uninitialized baseline, the checker reports that `docs/project/` does not exist yet. After
initialization, it checks the active project structure, manifest paths, approval-state invariants,
ready/accepted artifact placeholders, phase planning sections, and traceability evidence signals.

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
