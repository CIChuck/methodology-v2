# Repository Guidelines

Use this file as a starting point for a product repository `AGENTS.md`. Replace bracketed
placeholders and project-specific commands after initialization.

## Repository Role

This repository contains an AI-assisted product development project governed by the local
methodology baseline. Agents collaborate with a human team member to envision, specify, design,
build, test, review, remediate, document, and deploy the product.

Do not treat chat history as build authority when methodology or active project documents apply.

## Methodology Authority

Follow `docs/methodology/constitution/gendev.md` for documentation-first development,
traceability, phase boundaries, test planning, review, remediation, and as-built close-out.

When creating or revising project documents, use the relevant guidance in
`docs/methodology/dev-skills/`:

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

Use reusable templates from `docs/methodology/templates/`.

Use lifecycle and orchestration guides from `docs/methodology/guides/`:

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

Use role playbooks from `docs/methodology/agents/roles/`.

## Active Project Authority

Active project authority belongs under `docs/project/`.

Expected structure:

```text
docs/project/vision/
docs/project/approvals/
docs/project/prd/
docs/project/architecture/
docs/project/security-governance/
docs/project/decisions/
docs/project/build-plan/
docs/project/build-plan/phases/
docs/project/testing/
docs/project/traceability/
docs/project/as-built/
```

The project manifest should live at:

```text
docs/project/project.yaml
```

The durable gate approval history should live at:

```text
docs/project/approvals/gate-log.md
```

Do not treat a gate as approved unless the required approver, approval date, evidence, and risk
disposition are recorded in durable project authority.

If `docs/project/` does not exist, initialize it before product implementation:

```bash
./scripts/init-project.sh "[Project Name]"
```

## Collaboration Mode

The human team member may set the operating mode in plain language:

```text
Lead proactively.
Use approval-gated mode.
Stay advisory.
Proceed execution-focused.
```

The selected mode should be reflected in `docs/project/project.yaml` when it should persist beyond
the current interaction. Required approvals still apply in every mode.

## Authority Precedence

Unless the active project defines a different order, use this precedence:

1. `docs/methodology/constitution/gendev.md`
2. `docs/project/security-governance/`
3. `docs/project/architecture/`
4. `docs/project/prd/`
5. `docs/project/build-plan/`
6. `docs/project/build-plan/phases/`
7. `docs/project/testing/`
8. `docs/project/traceability/`
9. Current user instruction, only within documented scope

If a request changes scope, architecture, governance/security behavior, acceptance criteria, or
phase boundaries, update the relevant authority document before implementation.

## Build, Test, And Development Commands

Replace this section with project-specific commands after the technology stack is accepted in
`docs/project/decisions/0001-technology-stack.md`.

Common command categories to define:

```bash
# install dependencies
[package-manager] install

# lint
[lint-command]

# typecheck
[typecheck-command]

# unit/integration tests
[test-command]

# build
[build-command]

# user acceptance or smoke test
[uat-command]
```

Do not invent verification commands. If commands are missing, update the phase plan or tactical
implementation plan before claiming verification.

## Coding Style And Scope

Follow the active architecture specification and technology stack decision.

Implementation must preserve:

- documented file/module ownership;
- phase scope and non-goals;
- deferred-feature boundaries;
- schema and migration instructions;
- security and governance rules;
- test and UAT expectations;
- documentation close-out requirements.

Do not remove unrelated code, silently broaden scope, weaken security checks, or mark planned
behavior as implemented without evidence.

## Testing Guidelines

Tests should trace to active requirements, architecture rules, or review findings.

Each phase plan or tactical implementation plan should identify:

- required unit tests;
- integration tests;
- negative tests;
- security/governance tests;
- migration tests;
- CLI/API/UAT checks, if applicable;
- fixtures and expected outputs;
- manual verification steps when automation is not practical.

Skipped verification must be reported with a concrete reason.

## Security And Governance

Any behavior involving users, agents, tools, automation, external APIs, file access, secrets,
persistent state, sensitive data, deployment, or irreversible side effects must conform to the
active governance/security specification under `docs/project/security-governance/`.

Security-sensitive requirements need positive and negative tests.

## Examples

Example artifacts may exist under `docs/examples/`. They are reference material only. Do not use
their implementation evidence, source paths, tests, CLI commands, or traceability statuses as local
project evidence unless the active project explicitly adopts them and matching implementation files
exist.

## Methodology Checks

Run the checker at major lifecycle transitions:

```bash
./scripts/check-methodology.sh
```

If the checker reports a missing `docs/project/`, initialize the active project before
implementation.

## Close-Out

A phase is not done until:

- required tests and UAT evidence are recorded;
- code review is complete or findings are tracked;
- remediation is complete or explicitly accepted;
- as-built documentation reflects what was actually built;
- the traceability matrix is updated;
- deferred items and known limitations are current.
