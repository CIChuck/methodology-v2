# Artifact Collaboration Protocol

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines how humans and agents collaboratively create methodology artifacts. It prevents
one-shot document generation from replacing actual shared understanding.

Every major artifact should pass through:

```text
source check -> draft -> review -> revise -> approval -> record
```

## Universal Artifact Rules

For every artifact:

- cite source authority;
- record who produced the artifact, when it was produced, whether an agent participated, and which
  upstream sources it derives from;
- pin upstream source revisions when the source has a durable revision identifier;
- identify assumptions;
- mark non-goals;
- include testability or verification expectations where applicable;
- keep status accurate;
- do not mark planned behavior as implemented;
- record approval when the artifact becomes authority.

## Artifact Status Values

Use these status values for planning authority artifacts:

```text
Draft
Ready for Review
Ready for Approval
Accepted
Stale
Superseded
```

Use `Ready for Review` when the agent wants human feedback but the artifact is not yet approval
candidate quality. Use `Ready for Approval` only when the artifact has completed its accuracy pass,
open questions are non-blocking or explicitly carried forward, and known risks are listed for human
disposition.

Use `Stale` when an upstream authority changed after the artifact pinned that authority. A stale
artifact requires reconciliation review before it can support a gate transition. `Stale` is not the
same as `Superseded`; stale artifacts may become current again after reconciliation, while
superseded artifacts have been replaced by newer accepted authority.

Reports and close-out artifacts may use `Complete` instead of `Accepted` when they record review or
evidence rather than define future build authority.

## Provenance And Revision Pinning

Authority and evidence artifacts should carry this header block near the top of the document:

```text
Produced by: TBD
Produced on: YYYY-MM-DD
Produced with: human | agent | human-agent collaboration
Agent identity: TBD model/version/session, or N/A
Derived from:
  - path: docs/project/vision/vision.md
    revision: TBD
```

`Produced by` is the accountable human or role that created or accepted the artifact text.
`Produced with` records whether the artifact was created by a human, by an agent, or through
human-agent collaboration. `Agent identity` should be bounded: record the tool, model, agent role,
or session identifier if known; do not paste long chat transcripts into the header.

`Derived from` lists the upstream artifacts, prompts, or external records the artifact depends on.
Each entry should include a path and a revision. Use a commit SHA, tag, pull request revision,
release identifier, or other immutable reference when one exists. Draft artifacts may use `TBD`
until the upstream source is committed or otherwise pinned.

If a derived-from source changes after an artifact pins it, the downstream artifact should be marked
`Stale` until reviewed. Reconciliation may confirm that no change is required, update the artifact,
or supersede it with a new artifact.

## Amending Accepted Artifacts

Accepted artifacts can change, but accepted authority should not be overwritten as if no prior
approval existed. Use `docs/methodology/guides/amendment-and-regression-protocol.md` when changing
accepted authority.

Classify amendments before editing:

```text
editorial                 no semantic change
additive-within-scope     clarification inside accepted boundaries
structural                scope, security, architecture, acceptance, phase, deployment, or risk change
```

When an accepted artifact changes semantically, the lead agent should:

- identify the current gate;
- identify the artifact revision being amended;
- ask for the required approval;
- update provenance and derived-from revisions;
- identify affected downstream artifacts;
- mark downstream artifacts `Stale` when reconciliation is needed;
- mark replaced artifacts `Superseded` when they no longer govern;
- record the amendment in `docs/project/approvals/gate-log.md`.

Do not use stale downstream artifacts as evidence for a gate transition.

## Vision

Responsible role: Product Vision Agent.

Inputs:

- human product idea;
- target users;
- business or operational context;
- constraints and known risks.

Human questions:

- Who is the product for?
- What problem matters most?
- What would success look like?
- What is explicitly out of scope?

Approval criteria:

- problem is clear;
- users are clear;
- success criteria are measurable and have read timing;
- non-goals are explicit.

## PRD

Responsible role: PRD Agent.

Inputs:

- accepted vision;
- human clarifications;
- constraints and dependencies.

Human questions:

- Which requirements are baseline?
- Which are deferred?
- What acceptance criteria prove success?
- What edge cases matter?

Approval criteria:

- stable requirement IDs exist;
- every baseline requirement has acceptance criteria;
- requirements are testable;
- deferred items have reasons.

## Architecture

Responsible role: Architecture Agent.

Inputs:

- accepted PRD;
- accepted vision;
- existing code or stack constraints;
- governance concerns.

Human questions:

- What stack is acceptable?
- What external systems are allowed?
- What lifecycle and ownership boundaries matter?
- What architecture decisions are deferred?

Approval criteria:

- component ownership is clear;
- runtime/data/lifecycle models are explicit;
- stack decision is recorded;
- implementation will not need to invent core structure.

## Governance And Security

Responsible role: Security Governance Agent.

Inputs:

- PRD;
- architecture;
- data sensitivity context;
- tool and external-system expectations.

Human questions:

- Who can act in the system?
- What actions are forbidden?
- What must be auditable?
- What data is sensitive?
- What requires approval?

Approval criteria:

- identity and authorization are explicit;
- positive and negative tests are defined;
- data and secrets handling are documented;
- agent/tool stop conditions exist or are N/A.

## Phase Roadmap

Responsible role: Phase Planning Agent.

Inputs:

- PRD;
- architecture;
- governance/security specification;
- known constraints.

Human questions:

- What should be delivered first?
- Which features are deferred?
- What phase produces user-visible value?
- What phase carries the highest risk?

Approval criteria:

- phases are bounded;
- dependencies are visible;
- each phase has an acceptance signal;
- security-sensitive work is sequenced appropriately.

## Phase Build Plan

Responsible role: Phase Planning Agent.

Inputs:

- phase plan;
- PRD;
- architecture;
- governance/security specification;
- traceability matrix.

Approval criteria:

- scope and non-goals are explicit;
- workstreams are identified;
- tests and UAT strategy exist;
- documentation close-out is defined.

## Tactical Implementation Plan

Responsible role: Phase Planning Agent.

Inputs:

- phase build plan;
- architecture;
- governance/security;
- active codebase context if available.

Approval criteria:

- workstreams are executable;
- file/module ownership expectations exist;
- verification commands are defined;
- negative tests are included;
- migration and rollback are addressed where applicable.

## Construction Directive

Responsible role: Phase Planning Agent or lead agent.

Inputs:

- accepted tactical implementation plan;
- supporting authority docs.

Approval criteria:

- allowed scope is clear;
- non-goals are clear;
- source authority revisions are listed;
- required tests are named;
- stop conditions are explicit;
- reporting expectations are clear;
- the directive can be preserved with the resulting implementation reference.

## Test And UAT Plan

Responsible role: Test UAT Agent.

Inputs:

- requirements;
- architecture acceptance criteria seed;
- governance/security tests;
- phase plan.

Approval criteria:

- each material requirement has a verification path;
- negative tests exist for authorization/validation behavior;
- UAT expected outputs are documented;
- coverage gaps are justified.

## Code Review Report

Responsible role: Code Review Agent.

Inputs:

- code diff or implementation summary;
- PRD;
- architecture;
- governance/security;
- tactical plan;
- construction directive;
- test evidence.

Approval criteria:

- findings are ordered by severity;
- each finding maps to authority;
- required remediation and tests are explicit;
- residual risk is visible.

## Remediation Plan

Responsible role: Remediation Agent.

Inputs:

- code review report;
- implementation context;
- tactical plan;
- construction directive.

Approval criteria:

- every finding is addressed exactly once;
- fixes do not broaden scope;
- required tests are included;
- residual findings are explicitly accepted or reopened.

## As-Built Close-Out

Responsible role: As-Built Close-Out Agent.

Inputs:

- implementation summary;
- review and remediation evidence;
- test/UAT evidence;
- active project docs.

Approval criteria:

- implemented behavior is accurate;
- deferred behavior is tracked;
- known limitations are documented;
- traceability reflects evidence;
- future agents can understand state without chat history.

## Traceability Matrix

Responsible role: As-Built Close-Out Agent or Traceability Matrix guidance.

Inputs:

- PRD;
- architecture;
- phase plans;
- implementation summary;
- tests/UAT evidence;
- review confirmation.

Approval criteria:

- verified rows have evidence;
- planned rows are not overstated;
- implementation references exist;
- tests map to requirements or documented rationale.

## Completion Standard

This protocol is working when each artifact is created through collaborative understanding,
reviewed by the human where necessary, and promoted to authority only after approval.
