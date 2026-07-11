# Repository Guidelines

## Repository Role

This repository is a reusable baseline for AI-assisted product development. It is intended to be
cloned, initialized for a specific project, and evolved toward documented goals with a human team
member and AI coding agents.

Do not treat chat history as build authority when methodology or project authority documents apply.

## Methodology Authority

Follow `docs/methodology/constitution/gendev.md` for documentation-first development,
traceability, phase boundaries, test planning, review, remediation, and as-built close-out.

Use reusable templates from `docs/methodology/templates/` when creating project artifacts.

Use dev-skill guidance from `docs/methodology/dev-skills/` when creating or revising methodology
artifacts, including:

- `vision-framing.md`
- `prd-author.md`
- `architecture-spec-author.md`
- `governance-security-spec.md`
- `phase-build-planner.md`
- `tactical-implementation-planner.md`
- `ai-construction-directive-builder.md`
- `code-conformance-reviewer.md`
- `remediation-closeout.md`
- `traceability-matrix.md`

Use operating guides from `docs/methodology/guides/`:

- `agentic-development-workflow.md`
- `gates.md`
- `collaboration-modes.md`
- `human-agent-collaboration-loop.md`
- `start-and-next-step-protocol.md`
- `gate-transition-protocol.md`
- `amendment-and-regression-protocol.md`
- `enforcement-contract.md`
- `human-approval-protocol.md`
- `subagent-coordination-protocol.md`
- `artifact-collaboration-protocol.md`
- `production-operations-protocol.md`
- `orchestration-validation.md`

Use role playbooks from `docs/methodology/agents/roles/` when a task maps to a specific lifecycle
role.

## Orchestration Behavior

## Agent Start Contract

At the start of a task, the lead agent must establish repository state before
editing methodology or project artifacts:

```bash
./scripts/gendev-doctor.sh
```

If the project is initialized, also run:

```bash
./scripts/project-state.sh
```

Use the output to report the current gate, next artifact, required approver, and
recommended validation. If `docs/project/` is missing, initialize the project
before product implementation. If current state is unclear or authority is
missing, stop and ask for human disposition rather than inferring approval.

For canonical late-lifecycle artifacts, prefer the generator over ad hoc files:

```bash
./scripts/new-artifact.sh --kind deployment-readiness
```

The human may set the collaboration mode in plain language, such as:

```text
Lead proactively.
Use approval-gated mode.
Stay advisory.
Proceed execution-focused.
```

The lead agent must follow the selected mode while preserving required human approvals. Proactive
mode does not bypass gate approvals, security approvals, or production approval.

For short prompts such as `Let's begin`, `What's next?`, `Continue`, `Proceed`, `Pause`, and
`Resume`, follow `docs/methodology/guides/start-and-next-step-protocol.md`.

When coordinating sub-agents, follow `docs/methodology/guides/subagent-coordination-protocol.md`.
Sub-agent output is advisory until accepted into active project documents or approval records.

When accepted authority must change, follow
`docs/methodology/guides/amendment-and-regression-protocol.md`. Do not keep moving forward with
stale authority, and do not regress gates unless the amendment invalidates gate entry conditions.

When enforcement class, gate protection, or implementation-path controls matter, follow
`docs/methodology/guides/enforcement-contract.md`. Attested enforcement is valid at baseline, but
the active project must declare its class in `docs/project/project.yaml`.

When project scale, gate combination, or GenDev Lite matters, follow
`docs/methodology/guides/gates.md`. The active project must declare `scaling.blast_radius_class`
as `C1`, `C2`, or `C3` in `docs/project/project.yaml`. Enforcement class and blast-radius class are
different controls.

Use `docs/project/project.yaml` as the active project control-plane summary and
`docs/project/approvals/gate-log.md` as the durable approval history. Do not treat a gate as
approved unless the required approver, approval date, evidence, and risk disposition are recorded.

## Active Project Paths

For an initialized product, active authority belongs under `docs/project/`. Because
artifact names are canonical and project-independent (constitution Rule 14), these
pointers name the actual authority files, not just their directories:

```text
docs/project/vision/vision.md
docs/project/prd/prd.md
docs/project/architecture/architecture.md
docs/project/security-governance/governance-security-spec.md
docs/project/decisions/0001-technology-stack.md
docs/project/build-plan/phase-plan.md
docs/project/traceability/traceability-matrix.md
docs/project/approvals/gate-log.md
docs/project/project.yaml
```

Per-phase and multi-artifact authority lives in directories, one set per phase or
record:

```text
docs/project/build-plan/phases/
docs/project/testing/
docs/project/as-built/
docs/project/decisions/
```

If `docs/project/` does not exist, initialize it before product implementation:

```bash
./scripts/init-project.sh "Project Name"
```

## Authority Precedence

When documents conflict, use this precedence unless the active project explicitly defines a
different order:

1. `docs/methodology/constitution/gendev.md`
2. Active project governance/security specification
3. Active project architecture specification
4. Active project PRD
5. Active project phase build plan
6. Active project tactical implementation plan
7. Active project construction directive
8. Current user instruction, only within the documented scope above

If a user request changes scope, architecture, security behavior, acceptance criteria, or phase
boundaries, update the relevant authority document before implementation.

## Implementation Rules

Before meaningful code generation, confirm that the active project has enough documented authority
to answer:

- what is being built;
- why it is being built;
- who it is for;
- what is in scope;
- what is out of scope;
- what architecture governs it;
- what security and governance rules apply;
- what tests or UAT checks prove it works;
- what documentation must be reconciled afterward.

Do not implement deferred features, silently widen scope, weaken security/governance behavior,
or mark planned behavior as implemented unless it is actually implemented and verified.

## Examples Are Not Active Authority

`docs/resources/examples/` contains example methodology artifacts. It is not the active project for a new
clone. Do not cite example PRDs, architecture docs, traceability matrices, implementation evidence,
source paths, tests, or UAT claims as local project authority unless the active project explicitly
adopts that material and matching local source/test files exist.

## Verification and Close-Out

When implementing product code, follow the active project verification commands. If commands are not
yet defined, create or update the relevant phase plan before proceeding.

Run the methodology checker before implementation, phase close-out, and handoff when applicable:

```bash
./scripts/check-methodology.sh
```

For each completed phase, update:

- test or UAT evidence;
- code review findings or review status;
- remediation status, if applicable;
- as-built close-out;
- traceability matrix;
- deferred item list and known limitations.

Report skipped verification honestly with the reason.
