# Gate Transition Protocol

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`,
`docs/methodology/guides/gates.md`

## Purpose

This guide operationalizes gate movement. It defines what must be checked, approved, recorded, and
recommended when moving from one methodology gate to the next.

Gate transitions are procedural decisions. They should not happen implicitly.

## Universal Transition Checklist

Before any gate transition, confirm:

```text
[ ] current gate is known
[ ] required source docs exist
[ ] required artifact status is ready for approval or accepted
[ ] blocking questions are resolved or assigned
[ ] required tests or test plans are present for the gate
[ ] security/governance implications are addressed
[ ] human approval is recorded when required
[ ] project.yaml is updated or update is queued
[ ] next role and artifact are identified
```

## Transition Record

Recommended lightweight record:

```text
Gate transition:
From:
To:
Decision:
Approved by:
Date:
Evidence:
Known risks accepted:
Next role:
Next artifact:
```

This record may live in the artifact being approved, a gate log, or another active project document.
`project.yaml` should summarize the current gate and approval state.

## G0 -> G1: Project Initialized To Vision Ready Work

Required:

- `docs/project/project.yaml`;
- active project folder structure;
- human owner or temporary owner;
- collaboration mode.

Review questions:

- Is this a new project or continuation?
- Is the project name and slug correct?
- Is the current mode appropriate?

Human approval: not required unless initialization overwrote existing state.

Next role: Product Vision Agent.

Next artifact: vision/problem framing document.

Stop if:

- project identity is unclear;
- active project folder is missing;
- manifest paths do not exist.

## G1 -> G2: Vision Ready To Requirements Ready Work

Required:

- accepted vision/problem framing document;
- target users;
- success criteria;
- non-goals;
- risks and open questions.

Review questions:

- Does the vision explain the problem rather than only a solution?
- Are target users clear?
- Are success criteria observable?
- Are non-goals acceptable?
- Are open questions non-blocking for PRD drafting?

Human approval: required.

Next role: PRD Agent.

Next artifact: PRD.

Stop if:

- the human disagrees with users, outcomes, or non-goals;
- scope is too vague;
- unresolved questions could change requirements.

## G2 -> G3: Requirements Ready To Architecture Ready Work

Required:

- accepted PRD;
- stable requirement IDs;
- acceptance criteria;
- edge cases;
- deferred requirements;
- product-level security/governance requirements.

Review questions:

- Does every baseline requirement have acceptance criteria?
- Are requirements testable?
- Are deferred items documented with reasons?
- Are architecture-affecting open questions resolved?

Human approval: required.

Next role: Architecture Agent.

Next artifacts:

- architecture specification;
- technology stack decision record.

Stop if:

- baseline scope is too broad;
- acceptance criteria are unmeasurable;
- requirements imply unapproved external systems.

## G3 -> G4: Architecture Ready To Governance Ready Work

Required:

- accepted architecture specification;
- accepted or proposed technology stack decision;
- component ownership;
- runtime and data model;
- error and failure behavior;
- deferred architecture.

Review questions:

- Can implementation proceed without inventing core structure?
- Are data and lifecycle boundaries clear?
- Are external integrations identified?
- Are security-sensitive boundaries visible?

Human approval: required.

Next role: Security Governance Agent.

Next artifact: governance/security specification.

Stop if:

- stack decision is unresolved;
- architecture conflicts with PRD;
- trust boundaries are implicit.

## G4 -> G5: Governance Ready To Build Ready

Required:

- accepted governance/security specification;
- identity model;
- authorization rules;
- approval model;
- audit model;
- secrets and data sensitivity rules;
- security and negative test expectations.

Review questions:

- Does every actor have permitted and forbidden actions?
- Are authorization rules testable?
- Are audit and retention expectations explicit?
- Are agent/tool stop conditions documented or N/A?

Human approval: required.

Next role: Phase Planning Agent.

Next artifacts:

- phase roadmap or selected phase;
- phase build plan;
- tactical implementation plan;
- test/UAT plan;
- construction directive.

Stop if:

- authorization behavior is implicit;
- data sensitivity is unknown;
- security tests are missing for security requirements.

## G5 -> G6: Build Ready To Implementation Ready For Review

Required:

- accepted phase build plan;
- accepted tactical implementation plan;
- accepted test/UAT plan or embedded equivalent;
- accepted construction directive;
- implementation completed within scope;
- verification run or skipped with reason.

Review questions:

- Did implementation stay within the directive?
- Were required tests added or updated?
- Were verification commands run?
- Were skipped checks reported?
- Did implementation affect docs, examples, or traceability?

Human approval: required before construction begins, but not required merely to enter review unless
critical verification was skipped.

Next role: Code Review Agent.

Next artifact: code review report.

Stop if:

- implementation changed architecture/security scope;
- required verification failures are unresolved;
- deferred behavior was implemented.

## G6 -> G7: Implementation Ready For Review To Acceptance Ready

Required:

- code review report;
- remediation plan or summary, if findings exist;
- tests and UAT evidence;
- residual risk statement;
- updated traceability evidence.

Review questions:

- Are critical findings remediated?
- Are major findings remediated or explicitly accepted?
- Do tests prove acceptance criteria?
- Does traceability match actual evidence?
- Are known limitations documented?

Human approval: required for acceptance and for any accepted critical/major residual risk.

Next role: As-Built Close-Out Agent or Deployment Readiness Agent, depending on release path.

Next artifacts:

- as-built close-out;
- deployment readiness checklist if production release is in scope.

Stop if:

- findings lack remediation or acceptance;
- verified traceability lacks evidence;
- documentation still describes planned behavior as implemented.

## G7 -> G8: Acceptance Ready To Deployment Ready

Required:

- accepted implementation;
- as-built updates sufficient for release evaluation;
- deployment target;
- environment/config/secrets expectations;
- migration and rollback plan;
- operational checks;
- human release approver.

Review questions:

- What exactly is being released?
- What can fail in deployment?
- How is rollback performed?
- What monitoring confirms success?
- Who owns post-deployment response?

Human approval: required.

Next role: Deployment Readiness Agent.

Next artifacts:

- production runbook;
- release checklist;
- post-deployment validation plan;
- rollback decision procedure.

Stop if:

- rollback is undefined for risky changes;
- production credentials are requested in chat;
- monitoring or validation is missing;
- deployment target is not approved.

## G8 -> G9: Deployment Ready To As-Built Closed

Required:

- deployment or release decision;
- post-deployment validation results, if deployed;
- rollback status or confirmation not needed;
- production known limitations;
- final as-built close-out;
- traceability update.

Review questions:

- Did deployment occur?
- Did post-deployment checks pass?
- Were incidents, rollback, or follow-up items recorded?
- Can future agents understand the production state?

Human approval: required for phase close.

Next role: Product Vision Agent, Phase Planning Agent, or Deployment Readiness Agent, depending on
next work.

Next artifact: next phase plan or operational follow-up backlog.

Stop if:

- production status is unclear;
- runbook or known limitations are stale;
- traceability is not updated.

## Completion Standard

This protocol is working when a gate never advances merely because an agent says it is ready. Each
transition has source evidence, review questions, recorded approval where required, updated state,
and a clear next role.
