# Methodology Gates

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

Gates define when agents may proceed and when they must stop. They convert the methodology into
objective lifecycle checkpoints.

Use this guide with `docs/methodology/guides/gate-transition-protocol.md` for the procedural steps
needed to move from one gate to another.

Gate status values:

```text
not_started
in_progress
blocked
ready_for_approval
accepted
superseded
```

## G0: Project Initialized

Purpose: Confirm a cloned baseline has an active project workspace.

Required:

- `docs/project/project.yaml`;
- active project folders;
- root `AGENTS.md`;
- `docs/methodology/constitution/gendev.md`;
- project name and slug.

Human approval: not required unless initialization overwrites an existing project.

Exit criteria:

- manifest paths are syntactically valid;
- starter docs exist;
- current gate is recorded as `G1`.

Agents must stop if:

- `docs/project/` is missing;
- manifest authority paths do not exist;
- project name or owner is unclear.

## G1: Vision Ready

Purpose: Establish why the product exists and what success means.

Required:

- vision/problem framing document;
- target users;
- success criteria;
- non-goals;
- assumptions, risks, and open questions.

Human approval: required.

Exit criteria:

- problem statement is clear;
- target users are clear;
- success criteria are observable;
- non-goals are explicit;
- blocking open questions are assigned.

Agents must stop if:

- the problem is actually a proposed implementation without user context;
- success criteria are not measurable;
- product scope depends on unresolved human decisions.

## G2: Requirements Ready

Purpose: Convert vision into testable product requirements.

Required:

- PRD;
- stable requirement IDs;
- functional and non-functional requirements;
- acceptance criteria;
- edge cases;
- deferred items;
- testability notes.

Human approval: required.

Exit criteria:

- every baseline requirement has acceptance criteria;
- requirements are specific enough for architecture and tests;
- deferred items have reasons;
- open questions that block architecture are resolved or assigned.

Agents must stop if:

- requirements contradict the vision;
- acceptance criteria are untestable;
- baseline scope is too broad for coherent architecture.

## G3: Architecture Ready

Purpose: Define system structure, boundaries, lifecycle, and technology decisions.

Required:

- architecture specification;
- technology stack decision record;
- terminology and domain model;
- component ownership;
- runtime and data model;
- state lifecycle;
- interfaces;
- error and failure behavior;
- deferred architecture.

Human approval: required.

Exit criteria:

- architecture rules trace to requirements;
- ownership boundaries are clear;
- state and lifecycle are defined;
- stack decision is accepted;
- implementation does not need to invent core structure.

Agents must stop if:

- component boundaries overlap;
- stack decisions are missing;
- security-sensitive architecture is implicit;
- required external services are not approved.

## G4: Governance Ready

Purpose: Make security, policy, identity, audit, and agent/tool behavior explicit.

Required:

- governance/security specification;
- identity model;
- roles and permissions;
- authorization rules;
- approval model;
- audit model;
- secrets handling;
- data sensitivity model;
- trust boundaries;
- tool/external-system access rules;
- security and negative tests.

Human approval: required.

Exit criteria:

- every actor has permitted and forbidden actions;
- authorization rules include positive and negative tests;
- audit requirements are explicit;
- secrets and sensitive data handling are defined;
- agent/tool stop conditions are documented or marked N/A.

Agents must stop if:

- authorization behavior is inferred rather than documented;
- external tool access is unclear;
- data sensitivity is not classified;
- security tests are missing for security requirements.

## G5: Build Ready

Purpose: Authorize a bounded implementation phase.

Required:

- phase build plan;
- tactical implementation plan;
- test/UAT plan or phase-embedded equivalent;
- construction directive;
- updated traceability matrix entries for planned work.

Human approval: required.

Exit criteria:

- phase scope is bounded;
- out-of-scope and deferred items are explicit;
- workstreams have file/module ownership expectations;
- tests and UAT checks are defined;
- migration and rollback behavior are documented where applicable;
- construction directive is ready for an implementation agent.

Agents must stop if:

- workstreams are too broad;
- required tests are missing;
- implementation would require undocumented architecture;
- phase success depends on deferred behavior.

## G6: Implementation Ready For Review

Purpose: Confirm implementation is ready for conformance review.

Required:

- implementation summary;
- changed files;
- tests added or updated;
- verification commands run or skipped with reasons;
- known deviations.

Human approval: not required before review, but required for accepting skipped critical
verification.

Exit criteria:

- authorized scope is implemented;
- required tests were run or skipped with reason;
- no known deferred-feature leakage is unreported;
- documentation changes needed for review are present or identified.

Agents must stop if:

- verification failures are hidden;
- implementation changed unapproved architecture or security behavior;
- destructive migration or production action is pending.

## G7: Acceptance Ready

Purpose: Decide whether implementation can be accepted after review and remediation.

Required:

- code review report;
- remediation plan or summary, if findings exist;
- passing verification evidence or accepted exceptions;
- updated test/UAT evidence;
- updated traceability matrix.

Human approval: required for critical/major finding acceptance and phase acceptance.

Exit criteria:

- critical findings are remediated;
- major findings are remediated or explicitly accepted with rationale;
- tests and UAT evidence exist;
- residual risk is documented;
- traceability matrix reflects actual status.

Agents must stop if:

- findings lack remediation;
- verified status lacks evidence;
- documentation still describes planned behavior as implemented.

## G8: Deployment Ready

Purpose: Confirm the accepted product state can be deployed or released.

Required:

- deployment target and environment assumptions;
- config/secrets documentation;
- migration and rollback plan;
- operational checks;
- security sign-off for production-sensitive behavior;
- release notes or deployment checklist;
- production runbook;
- post-deployment validation plan;
- monitoring and alert review;
- incident and rollback decision procedure.

Human approval: required.

Exit criteria:

- release scope is accepted;
- deployment commands and rollback commands are documented;
- sensitive environment variables and secrets are accounted for;
- production-impacting migrations are approved;
- known limitations are visible;
- post-deployment owner is identified.

Agents must stop if:

- production secrets or credentials are requested in chat;
- rollback is undefined for irreversible changes;
- deployment target is not approved;
- release would bypass human approval.

## G9: As-Built Closed

Purpose: Preserve the implemented state for future work.

Required:

- as-built close-out document;
- updated architecture/PRD/config/API/CLI docs as needed;
- updated examples or usage docs;
- known limitations;
- deferred backlog;
- final traceability matrix update.

Human approval: required for phase close.

Exit criteria:

- future agents can understand the actual system without chat history;
- implemented behavior, deferred behavior, and deviations are explicit;
- test evidence is recorded;
- next phase or backlog state is clear.

Agents must stop if:

- as-built docs are missing;
- traceability is stale;
- planned but unbuilt behavior is described as done.

## Gate Progression

Default progression:

```text
G0 -> G1 -> G2 -> G3 -> G4 -> G5 -> G6 -> G7 -> G8 -> G9
```

Some projects may combine gates, but they must preserve the required content and human approvals.

For small prototypes, G3 and G4 may be lightweight. They must still define architecture and security
assumptions explicitly.
