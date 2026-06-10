# 06. Gates And Artifacts

## Purpose

This chapter explains how GenDev gates and artifacts work together. Gates (explicit lifecycle
checkpoints where the team decides whether the project is ready to move forward) define lifecycle
state (where the project sits in the overall process). Artifacts (durable project documents or
records) hold the durable content that proves the project is ready to advance. Evidence means the
specific documents, records, tests, reviews, or approvals that support a readiness claim.
G0 through G9 are shorthand labels for the ordered GenDev gates.

## Gate Status Versus Artifact Status

A gate and an artifact are related but not the same.

Artifact status (the readiness state of a document) describes a document:

```text
Draft
Ready for Review
Ready for Approval
Accepted
Superseded
```

Gate status (the readiness state of a lifecycle checkpoint) describes project movement:

```text
pending
drafting
ready_for_review
ready_for_approval
approved
blocked
superseded
```

An artifact may be `Ready for Approval` before the gate is approved. The gate becomes `approved`
only after human approval is recorded in durable project authority (accepted repository state that
future humans and agents should trust).

Gate approvals should be recorded as structured gate-log events in
`docs/project/approvals/gate-log.md`. A structured event is a Markdown section containing a small
YAML block with the gate transition, decision, approver, evidence, accepted risks, and a `checked`
statement naming what the approver actually verified.

## Gate Overview

## G0: Project Initialized

G0 confirms that the baseline repository (the reusable GenDev repository before product-specific
setup) has been initialized for a specific product.

Primary evidence:

- `docs/project/project.yaml`;
- starter project folders;
- rendered artifact templates;
- current gate set to G1.

Human approval is not required unless initialization overwrote existing project state (existing
product-specific files or manifest values).

## G1: Vision Ready

G1 establishes why the product exists and what success means.

Primary artifact:

```text
docs/project/vision/[project-slug]-vision.md
```

The vision should define:

- problem statement;
- target users;
- user pain or opportunity;
- desired outcomes;
- success criteria;
- non-goals (things the team is explicitly choosing not to build now);
- assumptions (beliefs being used for planning before they are proven);
- risks;
- open questions.

Do not let the agent turn G1 into an implementation plan. The vision explains the problem and
success conditions. It does not authorize code.

## G2: Requirements Ready

G2 converts the vision into testable product requirements (specific product behaviors and
constraints that can be reviewed and tested).

Primary artifact:

```text
docs/project/prd/[project-slug]-prd.md
```

The PRD should define:

- product objective;
- stable requirement IDs;
- functional requirements (what the product must do);
- non-functional requirements (qualities such as performance, reliability, security, or
  maintainability);
- primary workflows;
- edge cases (unusual but plausible inputs, states, or user actions);
- out-of-scope behavior;
- deferred items;
- dependencies;
- security and governance requirements;
- observability and audit requirements;
- testability notes.

The PRD is ready only when baseline requirements have observable acceptance criteria (conditions
that prove a requirement is satisfied).

## G3: Architecture Ready

G3 defines system structure (how the product is organized technically and where boundaries exist).

Primary artifacts:

```text
docs/project/architecture/[project-slug]-architecture.md
docs/project/decisions/0001-technology-stack.md
```

The architecture should define:

- terminology and domain model (the important product concepts and how they relate);
- system boundaries (what the system owns and what it depends on externally);
- component responsibilities;
- runtime model;
- data model;
- lifecycle and state transitions (how important records or workflows move from one state to
  another);
- interfaces;
- failure behavior;
- technology stack decision;
- deferred architecture.

Implementation should not need to invent core structure after G3.

## G4: Governance Ready

G4 makes security, policy, identity, audit (records of important events), and agent/tool behavior
explicit.

Primary artifact:

```text
docs/project/security-governance/governance-security-spec.md
```

The specification should define:

- identity model;
- roles and permissions;
- authorization rules (what each actor is allowed or forbidden to do);
- approval model;
- audit model;
- secrets handling (how credentials, tokens, and private configuration are protected);
- data sensitivity (how confidential or regulated the data is);
- trust boundaries (places where data or control crosses between actors, systems, or privileges);
- external tool rules (limits on tools, services, or integrations outside the repository);
- agent stop conditions (situations where the agent must pause and ask the human);
- security and negative tests.

G4 is especially important for products with users, sensitive data, automation, integrations, or
production deployment.

## G5: Build Ready

G5 authorizes a bounded implementation phase (a controlled increment of build work).

Primary artifacts:

```text
docs/project/build-plan/phase-roadmap.md
docs/project/build-plan/phases/phase-1-build-plan.md
docs/project/build-plan/phases/phase-1-tactical-implementation-plan.md
docs/project/testing/phase-1-test-uat-plan.md
docs/project/build-plan/phases/phase-1-construction-directive.md
```

The build-ready state should define:

- phase scope;
- non-goals;
- workstreams (groups of related implementation tasks);
- file or module ownership expectations;
- verification commands (commands that prove the work builds, tests, or checks correctly);
- UAT expectations (user acceptance testing expectations);
- migration and rollback implications (data or release changes and how to reverse them if needed);
- documentation close-out requirements (docs that must be updated after work is complete).

No meaningful implementation should begin before G5 unless the human explicitly decides to bypass
the methodology for a throwaway experiment.

## G6: Implementation Ready For Review

G6 means implementation work is complete enough for conformance review (checking the work against
accepted authority rather than personal taste).

Evidence should include:

- implementation summary;
- changed files;
- tests added or updated;
- verification commands run or skipped with reasons;
- known deviations (places where the implementation differs from the accepted plan).

G6 does not mean the work is accepted. It means the work is ready to be reviewed against authority.

## G7: Acceptance Ready

G7 decides whether implementation can be accepted after review and remediation (fixing review
findings or explicitly accepting the remaining risk).

Required evidence:

- code review report;
- remediation summary, if findings existed;
- passing verification evidence or accepted exceptions;
- test/UAT evidence;
- updated traceability matrix;
- residual risk statement (the risk that remains after remediation).

Human approval is required for phase acceptance and for accepting critical or major residual risk.

## G8: Deployment Ready

G8 confirms that the accepted product state can be deployed or released (moved into an operating
environment).

Required evidence:

- release scope;
- deployment target;
- configuration and secrets expectations;
- migration plan;
- rollback plan (how to return to a previous known-good state if deployment fails);
- operational checks (checks an operator performs before or after release);
- monitoring plan (how the team will observe health, errors, and important signals);
- deployment approval;
- post-deployment owner.

Deployment approval is separate from implementation acceptance.

## G9: As-Built Closed

G9 preserves the implemented and operational state for future work.

Required evidence:

- as-built close-out;
- updated docs;
- known limitations;
- deferred backlog (items intentionally postponed for later work);
- final traceability update;
- production status, if deployed;
- next phase or operational follow-up.

The project is not truly done until future agents can understand the actual state without relying on
chat history.

## Practitioner Rule

At each gate, ask:

```text
What artifact proves readiness?
What human approval is required?
What did the approver actually check?
What risk is being accepted?
What happens next?
```
