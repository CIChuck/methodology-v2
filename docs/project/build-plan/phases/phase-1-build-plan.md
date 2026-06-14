# Phase Build Plan: Eval Test Product — Phase [N]: [Phase Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date: 2026-06-11
Owner: TBD
Authority: `docs/methodology/constitution/gendev.md` — Phase Build Plan
Source:
  PRD: `docs/project/prd/[prd-document].md`
  Architecture: `docs/project/architecture/[architecture-document].md`
  Governance/Security: `docs/project/security-governance/[governance-document].md`
Produced by: TBD
Produced on: 2026-06-11
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/prd/[prd-document].md
    revision: TBD
  - path: docs/project/architecture/[architecture-document].md
    revision: TBD
  - path: docs/project/security-governance/[governance-document].md
    revision: TBD
  - path: docs/project/build-plan/phase-roadmap.md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
the phase is bounded and can be converted into tactical implementation work
```

---

## Phase Objective

```text
What must be true when this phase is complete?
One paragraph. Outcomes, not tasks.
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

## Out-of-Scope Items

```text
What is explicitly excluded from this phase?
Every deferred feature must appear here or in the deferred items table.
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
```

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Security and Governance Implications

```text
What security or governance requirements are active in this phase?
What must be verified before the phase can close?
Reference: docs/project/security-governance/[governance-document].md
```

---

## Migration and Compatibility

```text
Does this phase change existing behavior, schemas, APIs, or data?
What must remain compatible?
What must be migrated?
What is the rollback plan if the migration fails?
If not applicable, mark this section N/A with a reason.
```

---

## Test Strategy

```text
What must be tested in this phase?
Tests are planned here, not after code generation.
```

| Workstream | Unit Tests | Integration Tests | Negative Tests | UAT / CLI |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

Required fixtures:

```text
List test data, environment conditions, or infrastructure required for testing.
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
```

---

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass.

Check for:

```text
[ ] scope items that are too broad for a single phase
[ ] deferred items that are actually blocking this phase
[ ] workstreams with no test coverage
[ ] acceptance criteria that cannot be verified
[ ] missing migration or compatibility requirements
```

---

## Gate 4 Exit Checklist

Before proceeding to tactical planning:

```text
[ ] phase scope is bounded
[ ] out-of-scope items are documented
[ ] deferred items have reasons
[ ] workstreams are defined
[ ] tests are planned for each workstream
[ ] CLI/UAT strategy defined or marked N/A
[ ] migration plan exists if applicable
[ ] acceptance criteria are verifiable
[ ] documentation close-out requirements are defined
```
