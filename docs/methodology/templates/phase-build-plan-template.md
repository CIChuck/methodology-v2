# Phase Build Plan: [Project Name] — Phase [id]: [Phase Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
project: [project-slug]
Date:
Owner:
Position: G5.[id].1
Authority: `docs/methodology/constitution/gendev.md` — Phase Build Plan
Source:
  PRD: `docs/project/prd/prd.md`
  Architecture: `docs/project/architecture/architecture.md`
  Governance/Security: `docs/project/security-governance/governance-security-spec.md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phase-plan.md
    revision: TBD
  - path: docs/project/prd/prd.md
    revision: TBD
  - path: docs/project/architecture/architecture.md
    revision: TBD
  - path: docs/project/security-governance/governance-security-spec.md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
the phase is bounded, its exit test is defined, and it can be converted into
tactical implementation work
```

---

## Phase Objective

```text
What must be true when this phase is complete?
One paragraph. Outcomes, not tasks. Specific enough to determine whether the
phase succeeded.
```

---

## Why This Phase Now

```text
What did the prior phase establish that makes this phase possible or necessary?
For the first phase, state what baseline the phase plan assumes.
One short paragraph. This anchors the phase in the rolling-wave sequence.
```

---

## Methodology Baseline

```text
Which methodology rules govern this phase? Name them so the building agent
carries them as context, not as links to chase. Examples:
  documentation-first implementation
  phase-boundary discipline
  test-centered planning
  security/governance as first-class requirements
  documentation close-out as definition of done
```

---

## Architecture Baseline

```text
Which architecture rules or constraints are in force for this phase?
  core objects or subsystems
  ownership boundaries
  state/lifecycle rules
  interfaces
  configuration rules
  data model implications
```

### Architecture Mirror Check

Hold the G3 architecture up as a mirror and check what reflects back. This is
design verification re-asked at phase scope against the already-ratified
architecture; it is a check, not a new architecture document.

```text
Does the work planned for this phase still conform to the G3 architecture?
Did planning this phase reveal anything the architecture did not anticipate
  (a missing interface, an unhandled failure mode, an assumption that does not
  hold)?
If the architecture must change, that is a regression against G3, not a silent
  phase decision: raise it, do not absorb it here.
```

---

## Phase Scope

```text
What is included in this phase?
Reference PRD requirement IDs where applicable.
```

| Item | PRD Requirement | Notes |
| --- | --- | --- |
|  |  |  |

---

## Out-of-Scope and Explicit Non-Goals

```text
What is explicitly excluded from this phase, including deferred features and
adjacent work that may be tempting but is outside the phase? Name sibling
phases by id where a capability belongs to them. Anything that will be built
later belongs in the Deferred Items table below; anything that will never be
built by this project belongs here.
```

---

## Deferred Items

```text
What is being deferred from this phase to a future phase?
```

| Item | Reason Deferred | Target Phase |
| --- | --- | --- |
|  |  |  |

---

## Dependencies

```text
What must be complete before this phase can begin?
What external systems, decisions, or approvals are required?
```

| Dependency | Type | Status | Owner |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Implementation Workstreams

```text
What are the major units of work in this phase?
Workstreams should be independently completable where possible.
```

| Workstream | Description | Owner | Dependencies |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Sequencing

```text
In what order must workstreams proceed?
What can proceed in parallel?
```

---

## Risk Areas

```text
What parts of this phase carry the most implementation uncertainty?
What could cause the phase to fail or require rework?
Include implementation, architecture, security, test, migration, and
documentation risks.
```

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Security and Governance Implications

```text
Governance/security baseline: identify the security, governance, identity,
permission, audit, approval, policy, data-sensitivity, or secrets-handling
requirements in force for this phase. If none apply, state why.

Below the baseline, record what must be verified before the phase can close.
Reference: docs/project/security-governance/governance-security-spec.md
```

---

## Migration and Compatibility

```text
Does this phase change existing behavior, schemas, APIs, or data?
What must remain compatible?
What must be migrated? What is replaced, adapted, removed, or rejected?
What is the rollback plan if the migration fails?
If not applicable, mark this section N/A with a reason.
```

---

## Test Strategy

```text
What must be tested in this phase?
Tests are planned here, not after code generation.
Required categories: unit, integration, security/governance, negative,
migration, CLI/API/UAT, and manual verification where needed.
```

| Workstream | Unit Tests | Integration Tests | Negative Tests | UAT / CLI |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

Required fixtures:

```text
List test data, environment conditions, or infrastructure required for testing.
```

---

## Phase Exit Test

```text
The phase exit test is the test that must pass for this phase to be considered
complete (checkpoint G5.[id].4). It tests the code this phase generates. It is
distinct from integration tests and user-acceptance tests.

Define:
  what the exit test is (the specific suite or command set);
  how it is executed (the exact commands);
  the pass criteria (what green means for this phase).
```

| Exit test | Execution command | Pass criterion |
| --- | --- | --- |
|  |  |  |

Coverage standard:

```text
Coverage requirement follows the project-defined coverage policy. A shortfall must be
recorded in this artifact with written justification and a named residual risk.
Never accept a shortfall silently.
```

Adequacy approver:

```text
Name the approver who decides whether this exit test is sufficient (a human by
default). The approver records the phase exit decision in the phase_transition
event at G5.[id].4.
```

Regression note:

```text
On exit, this test joins the accumulated regression suite and is re-run as a
required regression check on every subsequent phase.
```

Traceability:

```text
The features this phase delivers, and the exit test that proves them, must trace
back to the PRD requirements (and through them to the vision) this phase claims to
satisfy. A phase exit that cannot name which PRD requirements it has implemented
has not verified that it built the right thing, only that it built some thing.
```

---

## CLI and UAT Strategy

```text
If this phase exposes CLI commands, API endpoints, or user-observable behavior,
define how those surfaces will be verified.
This is distinct from automated tests — it is the human-executable acceptance surface.
If not applicable, mark this section N/A with a reason.
```

| Scenario | Actor | Steps | Expected Output |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Acceptance Criteria

```text
How will this phase be accepted or rejected?
Each criterion must be observable and verifiable.
```

| Criterion | Verification Method |
| --- | --- |
|  |  |

---

## Documentation Close-Out Requirements

```text
What documentation must be updated before this phase is closed?
```

```text
[ ] architecture docs reflect as-built state
[ ] traceability matrix updated
[ ] deferred feature backlog updated
[ ] known limitations documented
[ ] test evidence recorded
[ ] developer / CLI / API / config docs updated
```

---

## Open Questions

```text
What must be resolved before tactical implementation planning?
These map to the open-questions-carried-forward field in the gate log.
```

| Question | Owner | Needed by |
| --- | --- | --- |
|  |  |  |

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

## G5.[id].1 Checkpoint — Build Plan Ready

Before proceeding to tactical planning:

```text
[ ] phase scope is bounded
[ ] out-of-scope and explicit non-goals are documented
[ ] deferred items have reasons and target phases
[ ] workstreams are defined
[ ] tests are planned for each workstream
[ ] phase exit test is defined with execution commands and pass criteria
[ ] coverage standard stated; any shortfall justified with a named residual risk
[ ] CLI/UAT strategy defined or marked N/A
[ ] migration plan exists if applicable
[ ] acceptance criteria are verifiable
[ ] documentation close-out requirements are defined
[ ] open questions recorded
```

Closure discipline: the artifact status change to `Accepted`, the manifest
`phase_position` advance to `G5.[id].1`, and the `phase_checkpoint` event in the
gate log land in the same commit.

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
