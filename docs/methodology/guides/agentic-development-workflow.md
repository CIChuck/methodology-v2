# Agentic Development Workflow

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`  
Audience: Human product owners, engineering leads, AI coding operators, implementation agents,
review agents, and deployment reviewers

## Purpose

This guide defines how a human team member and AI-assisted coding agents move a cloned baseline from
an idea to a tested, reviewed, documented, and deployable product.

The workflow turns the methodology into an operating loop:

```text
initialize
  -> frame vision
     -> specify requirements
        -> design architecture and governance
           -> plan a bounded phase
              -> implement and test
                 -> review and remediate
                    -> close out as-built docs
                       -> prepare deployment
```

The goal is not to slow development. The goal is to make agent-assisted work explicit enough that
agents do not invent scope, lose traceability, or treat chat history as build authority.

## Related Orchestration Guides

Use this guide with:

- `docs/methodology/guides/collaboration-modes.md`;
- `docs/methodology/guides/human-agent-collaboration-loop.md`;
- `docs/methodology/guides/start-and-next-step-protocol.md`;
- `docs/methodology/guides/gate-transition-protocol.md`;
- `docs/methodology/guides/amendment-and-regression-protocol.md`;
- `docs/methodology/guides/human-approval-protocol.md`;
- `docs/methodology/guides/subagent-coordination-protocol.md`;
- `docs/methodology/guides/artifact-collaboration-protocol.md`;
- `docs/methodology/guides/production-operations-protocol.md`;
- `docs/methodology/guides/orchestration-validation.md`.

The workflow defines the lifecycle. The orchestration guides define how humans, lead agents, and
sub-agents collaborate inside that lifecycle.

## Repository Layers

The baseline separates reusable methodology from active project authority.

```text
docs/methodology/
  Stable reusable method, templates, guides, and agent role playbooks.

docs/project-template/
  Starter skeleton used by initialization.

docs/project/
  Active project authority after initialization.

docs/examples/
  Non-authoritative examples.
```

Agents must treat `docs/project/` as the active authority only after it exists. Example artifacts do
not govern active work unless they are explicitly copied into `docs/project/` and reconciled.

## Lifecycle Overview

### 1. Project Initialization

Start a new product instance with:

```bash
./scripts/init-project.sh "Project Name"
```

Initialization creates:

- `docs/project/project.yaml`;
- starter vision, PRD, architecture, governance/security, traceability, phase, test, and close-out
  documents;
- the active project folder structure.

After initialization, the human owner and agent should inspect `docs/project/project.yaml` and update
owner, required approver, status, current gate, evidence, risk, blast-radius class, and
next-handoff fields.

The human should also set or confirm collaboration mode:

```text
proactive
approval-gated
advisory
execution-focused
```

If no mode is selected, use `approval-gated`.

Stop if:

- `docs/project/` is missing;
- `docs/project/project.yaml` points to files that do not exist;
- the product owner is unknown;
- the agent cannot identify the current gate.
- the agent cannot identify the blast-radius class.

### 2. Vision Loop

Use `docs/methodology/templates/vision-template.md` and
`docs/methodology/dev-skills/vision-framing.md`.

The vision loop answers:

- what problem is being solved;
- who the product is for;
- what success looks like;
- what is explicitly not being built;
- what risks, assumptions, and open questions matter.

Agents may infer wording and structure from discussion. Agents must stop for human input if missing
information would materially change scope, user identity, success criteria, or non-goals.

Human approval is required before moving from vision to PRD.

### 3. Requirements Loop

Use `docs/methodology/templates/prd-template.md` and
`docs/methodology/dev-skills/prd-author.md`.

The PRD loop turns vision into stable, testable requirements. Each requirement needs:

- a stable ID;
- observable acceptance criteria;
- testability notes;
- status: baseline, deferred, optional, or open.

Agents may organize and refine requirements. Agents must stop if a requirement is untestable,
contradicts the vision, changes the product audience, or requires unresolved business approval.

Human approval is required before architecture starts.

### 4. Architecture And Governance Loop

Use:

- `docs/methodology/templates/architecture-template.md`;
- `docs/methodology/templates/governance-security-template.md`;
- `docs/methodology/templates/0001-technology-stack-template.md`;
- `docs/methodology/dev-skills/architecture-spec-author.md`;
- `docs/methodology/dev-skills/governance-security-spec.md`.

Architecture defines system structure, ownership, lifecycle, interfaces, data model, failure
behavior, extension points, and deferred architecture.

Governance/security defines actors, authorization, audit, secrets, trust boundaries, tool access,
stop conditions, and security tests.

Agents must not begin implementation if architecture or governance leaves security-sensitive
behavior implicit.

Human approval is required for:

- technology stack;
- external services;
- data sensitivity classification;
- agent/tool permissions;
- irreversible or production-affecting architecture choices.

### 5. Build Planning Loop

Use:

- `docs/methodology/templates/phase-build-plan-template.md`;
- `docs/methodology/templates/tactical-implementation-template.md`;
- `docs/methodology/templates/test-uat-plan-template.md`;
- `docs/methodology/dev-skills/phase-build-planner.md`;
- `docs/methodology/dev-skills/tactical-implementation-planner.md`.

The phase plan (certified at G5) partitions the build into ordered, independently
testable phases. The build loop then runs one phase at a time: a phase build plan
defines what that phase may and may not build, a tactical implementation plan
defines how it will be built, tested, verified, and documented, and a
construction directive and build prompt drive the implementation. See
docs/methodology/guides/phase-loop.md.

Every phase must state:

- in-scope work;
- out-of-scope work;
- deferred items;
- required files/modules or ownership boundaries;
- migration and compatibility behavior;
- required tests and UAT checks;
- acceptance criteria;
- documentation close-out.

Agents must stop if a phase is too broad, lacks tests, lacks ownership boundaries, or requires a
deferred feature to succeed.

Human approval is required before producing a construction directive.

### 6. Construction Directive Loop

Use:

- `docs/methodology/templates/build-instructions-templates.md`;
- `docs/methodology/dev-skills/ai-construction-directive-builder.md`.

The construction directive is the implementation authority for an AI coding agent. It should cite
the tactical plan and supporting project authority, list allowed scope, list non-goals, name required
tests, and state verification/reporting requirements.

The implementation agent is subordinate to the construction directive. If implementation appears to
need broader scope, the agent must stop and request a planning update.

### 7. Implementation And Test Loop

Implementation follows the active construction directive and the current project architecture.

Agents should:

- keep changes scoped to authorized files/modules;
- add or update required tests;
- preserve phase boundaries;
- run documented verification commands;
- report skipped verification honestly.

Agents must stop before:

- destructive data migration;
- production deployment;
- adding a new external service;
- changing authentication, authorization, audit, secrets, or data retention behavior beyond the
  approved plan;
- implementing deferred features.

### 8. Code Review And Remediation Loop

Use:

- `docs/methodology/templates/code-review-report-template.md`;
- `docs/methodology/dev-skills/code-conformance-reviewer.md`;
- `docs/methodology/dev-skills/remediation-closeout.md`.

Review evaluates conformance to documented authority, not just code quality.

Review must check:

- requirement conformance;
- architecture conformance;
- governance/security conformance;
- test and UAT completeness;
- deferred-feature leakage;
- documentation drift;
- engineering quality.

Each finding must map to a concrete remediation action and required verification. Remediation must
not introduce unrelated scope.

### 9. As-Built Close-Out Loop

Use `docs/methodology/templates/as-built-closeout-template.md`.

A phase is not complete until documentation reflects what was actually built.

Close-out updates:

- implemented behavior;
- deferred behavior;
- changed assumptions;
- docs and examples;
- schema/API/CLI/config references;
- known limitations;
- test evidence;
- traceability matrix.

Agents must not mark planned behavior as implemented without evidence.

### 10. Deployment Readiness Loop

Deployment readiness happens only after acceptance-ready status.

Production includes deployment and post-deployment operation. Before deployment, confirm:

- architecture and governance still match implementation;
- environment and secret requirements are documented;
- migration and rollback behavior is approved;
- operational checks exist;
- security-sensitive behavior has positive and negative tests;
- human deployment approval is recorded;
- post-deployment validation is defined;
- monitoring and alert checks are defined;
- incident and rollback decision procedures are documented.

Production release must remain a human control point unless the active project explicitly authorizes
automated release behavior.

## Agent Inference Rules

Agents may infer:

- document formatting;
- cross-references between existing authority documents;
- obvious placeholder replacement after initialization;
- task ordering within an approved phase;
- test names and fixture organization that match the project conventions.

Agents must stop and ask when inference would affect:

- product scope;
- user identity or user workflow;
- acceptance criteria;
- architecture boundaries;
- security/governance behavior;
- tool or external-system access;
- data sensitivity;
- deployment or migration behavior;
- whether a deferred item becomes active scope.

## Human Control Points

Human approval is required for:

- vision acceptance;
- PRD acceptance;
- technology stack acceptance;
- architecture acceptance;
- governance/security acceptance;
- phase scope acceptance;
- construction directive acceptance;
- critical or major review-finding acceptance;
- destructive migration;
- new external integration;
- production deployment.

## Standard Evidence

At each gate, record evidence in the active project docs. Evidence can include:

- accepted document status;
- reviewer notes;
- command output;
- test suite results;
- UAT transcript or checklist;
- code review report;
- remediation summary;
- as-built close-out;
- traceability matrix update.

## Completion Standard

This workflow is working when a new agent can enter an initialized repository, read `AGENTS.md`,
`docs/project/project.yaml`, and the current gate documents, then know whether to plan, implement,
review, remediate, close out, or stop for human approval.
