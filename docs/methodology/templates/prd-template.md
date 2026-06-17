# Product Requirements Document: [Project Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
project: [project-slug]
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Product Requirements Document
Source: `docs/project/vision/[vision-document].md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/vision/[vision-document].md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
requirements are specific enough to become architecture and test cases
```

Do not proceed to architecture until this standard is met.

---

## Product Objective

```text
One paragraph.
What does this product or feature do, for whom, and to what end?
Derived from the vision document. Do not introduce new goals here.
```

---

## Requirement IDs

Assign stable IDs in the format `REQ-NNN`. Once assigned, IDs do not change.

Status values:

```text
baseline    — required for initial delivery
deferred    — intentionally excluded from current scope
optional    — included only if resources allow
open        — pending a decision before status can be assigned
```

---

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Testability Notes | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| REQ-001 |  |  |  | baseline |  |

Rules:

```text
each requirement must be testable
acceptance criteria must be observable
do not describe implementation
do not combine multiple requirements in one row
```

---

## Non-Functional Requirements

| ID | Category | Requirement | Acceptance Criteria | Testability Notes | Status |
| --- | --- | --- | --- | --- | --- |
| REQ-NF-001 | Performance |  |  |  | baseline |
| REQ-NF-002 | Security |  |  |  | baseline |
| REQ-NF-003 | Reliability |  |  |  | baseline |
| REQ-NF-004 | Scalability |  |  |  | baseline |
| REQ-NF-005 | Observability |  |  |  | baseline |

---

## Primary User Workflows

```text
Describe the main paths a user takes through the system.
Use numbered steps.
Every step must name the actor: user, system, agent, operator, or external service.
Do not describe UI implementation.
```

### Workflow 1: [Name]

1.
2.
3.

### Workflow 2: [Name]

1.
2.
3.

---

## Edge Cases

```text
What boundary conditions, error states, or unusual inputs must the system handle?
```

| Case | Expected Behavior | Requirement ID |
| --- | --- | --- |
|  |  |  |

---

## Out-of-Scope Behavior

```text
What will this system explicitly not do?
Reference the vision non-goals where applicable.
Add any requirements-level exclusions discovered during this analysis.
```

---

## Deferred Items

```text
What has been explicitly deferred to a future phase?
Each deferred item must have a reason.
```

| ID | Description | Reason Deferred | Suggested Future Phase |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Dependencies

```text
What external systems, services, teams, or decisions does this product depend on?
```

| Dependency | Type | Status | Owner |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Security and Governance Requirements

```text
What security, identity, access, audit, or compliance requirements are visible at the product level?
These will be expanded in the Governance and Security Specification.
```

---

## Observability and Audit Requirements

```text
What must be logged, monitored, or auditable?
```

---

## Testability Notes

```text
What will be hard to test?
What fixtures, test data, or environment conditions are required?
```

---

## Open Questions

```text
What is unresolved that could affect requirements?
```

| Question | Owner | Due | Blocking |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass.

Check for:

```text
[ ] contradictions between requirements
[ ] vague requirements that cannot be tested
[ ] acceptance criteria that are unmeasurable
[ ] requirements that exceed the vision scope
[ ] missing edge cases for stated workflows
[ ] deferred items that are actually blocking
[ ] open questions that block architecture
```

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

## G2 Exit Checklist (Requirements Ready)

Before proceeding to architecture:

```text
[ ] requirements are specific
[ ] every requirement has acceptance criteria
[ ] edge cases are captured
[ ] all requirements can be traced to a test
[ ] deferred items are documented with reasons
[ ] open questions have owners and due dates
```
