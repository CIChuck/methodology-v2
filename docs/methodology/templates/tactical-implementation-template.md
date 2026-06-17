# Tactical Implementation Plan: [Project Name] — Phase [id]: [Phase Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
project: [project-slug]
Date:
Owner:
Position: G5.[id].2
Authority: `docs/methodology/constitution/gendev.md` — Tactical Implementation Plan
Source:
  Phase Build Plan: `docs/project/build-plan/phases/[phase-build-plan].md`
  Prior Phase Learnings: `docs/project/build-plan/phases/[prior-phase-learnings].md` (N/A for the first phase)
  Architecture: `docs/project/architecture/[architecture-document].md`
  PRD: `docs/project/prd/[prd-document].md`
  Governance/Security: `docs/project/security-governance/[governance-document].md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/[phase-build-plan].md
    revision: TBD
  - path: docs/project/build-plan/phases/[prior-phase-learnings].md
    revision: TBD
  - path: docs/project/architecture/[architecture-document].md
    revision: TBD
  - path: docs/project/prd/[prd-document].md
    revision: TBD
  - path: docs/project/security-governance/[governance-document].md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
an AI builder can implement from this plan
without inventing architecture or scope
```

---

## Implementation Objective

```text
What must be built in this phase?
One paragraph. Reference the phase build plan.
```

---

## Source Authority and Precedence

```text
Which documents govern this implementation?
In case of conflict, which takes precedence?
```

1. Governance and Security Specification
2. Architecture Specification
3. PRD
4. Phase Build Plan
5. This Tactical Plan

---

## Assumptions

```text
What must be true for this plan to be valid?
If an assumption proves false, stop and revise the plan.
```

---

## Non-Goals

```text
What is explicitly out of scope for this implementation, including deferred
features and adjacent work that may be tempting? Agents must not implement
these items. Anything that will be built in a later phase belongs in Deferred
Items below; anything this project will never build belongs here.
```

---

## Deferred Items

```text
What does this tactical plan intentionally leave to a later phase?
This is visibility, not authorization — it names what a future phase owns.
```

| Item | Reason Deferred | Target Phase |
| --- | --- | --- |
|  |  |  |

---

## Workstreams

Each workstream is a self-contained unit of implementation work.

### Workstream [N]: [Name]

**Objective:**

```text
What must be built?
```

**Files and Modules:**

```text
What files or modules may be created or modified?
What must not be changed?
```

**Implementation Requirements:**

```text
Precise behavioral requirements.
Reference architecture rules and PRD requirement IDs.
```

**Schema and Data Changes:**

```text
What schema, database, or data structure changes are required?
What migration is needed?
```

**API and CLI Changes:**

```text
What interfaces are created, changed, or removed?
```

**Security and Governance Requirements:**

```text
What authorization, audit, secrets, or policy behavior must be implemented?
Reference governance specification.
```

**Test Requirements:**

```text
What tests must be written for this workstream?
```

| Test | Type | Description | Fixture |
| --- | --- | --- | --- |
|  | unit / integration / negative / UAT |  |  |

**Negative Tests:**

```text
What failure paths must be tested explicitly?
```

**Verification Commands:**

```text
Commands to run after this workstream is complete.
Expected output or exit code for each.
```

```bash
# Replace with project-specific commands
```

**Acceptance Criteria:**

```text
How will this workstream be verified as complete?
```

**Documentation Close-Out:**

```text
What documentation must be updated when this workstream is complete?
```

---

<!-- Repeat the Workstream block for each workstream -->

---

## Migration Order

```text
If workstreams have ordering constraints due to schema or data dependencies,
state the required sequence here.
```

---

## Rollback and Reset Considerations

```text
If this implementation must be reversed, what is the rollback procedure?
What data or schema changes cannot be cleanly reversed?
What is the state of the system if the implementation is halted midway?
If rollback is not applicable, state that explicitly with a reason.
```

---

## Known Risks

```text
What implementation risks remain?
What could cause this plan to fail?
```

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
|  |  |  |  |  |

---

## Negative Boundary Tests

```text
Tests that assert this phase does NOT do what it must not do. Distinct from the
per-workstream negative tests (which test failure paths within scope): these
assert the phase respects its boundaries — that out-of-scope behavior is absent,
deferred features are not present, and adjacent subsystems are untouched.
```

| Boundary | Assertion (what must be absent) | Test |
| --- | --- | --- |
|  |  |  |

---


---

## Supporting Artifacts

Project-specific artifacts produced by whatever analysis or design technique this
project uses (for example a data model, an object-interaction model, a
state-transition model, a user-story set, or a UX specification) attach here as
typed references. This section is empty when the project needs none.

Each entry uses a relationship type from the constitution's bounded vocabulary
(Rule 12), the canonical path to the supporting artifact, and a short note on what
it supports. The relationship type declares the coherence obligation and which end
holds authority:

```text
implements:     docs/project/design/<artifact>.md     - <what it realizes>
satisfies:      docs/project/design/<artifact>.md      - <what it fulfills>
tested-by:      docs/project/testing/<artifact>.md     - <what verifies it>
constrained-by: docs/project/design/<artifact>.md      - <what limits it>
refines:        docs/project/design/<artifact>.md      - <what detail it adds>
```

References form a directed acyclic graph and are one level deep (Rule 12);
supporting artifacts obey the form discipline in Rule 13 (valid kebab identifier,
canonical location, required project front-matter field, typed relationship).

## Independent Review Checklist

```text
Binary checks for an independent reviewer (human or a cold-context conformance
judge). Each item is pass/fail against this plan and its upstream authority.
```

```text
[ ] every workstream traces to a phase build plan workstream
[ ] every implementation requirement references an architecture rule or PRD id
[ ] no workstream invents scope absent from the build plan
[ ] file/module ownership is explicit and non-overlapping
[ ] schema and migration changes are complete and ordered
[ ] security requirements are assigned to a workstream
[ ] negative tests and negative boundary tests are present
[ ] verification commands are runnable with expected results
[ ] deferred items name a target phase
[ ] prior phase learnings were consulted and reflected (or N/A for the first phase)
```

---

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass. Identify:

```text
errors:
omissions:
contradictions:
scope drift:
missing tests:
missing security/governance requirements:
missing documentation close-out:
unresolved blockers:
opportunities for improvement:
```

---

## G5.[id].2 Checkpoint — Tactical Ready

Before proceeding to construction directive:

```text
[ ] all workstreams are defined with explicit scope
[ ] every workstream has test requirements
[ ] every workstream has verification commands
[ ] schema and migration changes are fully specified
[ ] security requirements are workstream-assigned
[ ] negative boundary tests are defined
[ ] documentation close-out is defined per workstream
[ ] prior phase learnings consulted (or N/A for the first phase)
[ ] plan is executable without architecture invention
```

Closure discipline: the artifact status change to `Accepted`, the manifest
`phase_position` advance to `G5.[id].2`, and the `phase_checkpoint` event in the
gate log land in the same commit.
