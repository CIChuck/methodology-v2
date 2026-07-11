# Test and UAT Plan: [Project Name] — Phase [N]: [Phase Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
project: [project-slug]
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Test and UAT Plan
Source:
  Tactical Plan: `docs/project/build-plan/phases/[tactical-plan].md`
  Architecture: `docs/project/architecture/architecture.md`
  Governance/Security: `docs/project/security-governance/governance-security-spec.md`
  PRD: `docs/project/prd/prd.md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/[tactical-plan].md
    revision: TBD
  - path: docs/project/architecture/architecture.md
    revision: TBD
  - path: docs/project/security-governance/governance-security-spec.md
    revision: TBD
  - path: docs/project/prd/prd.md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
the implementation can be accepted or rejected using documented evidence
```

---

## Test Scope

```text
What is being tested in this phase?
What is explicitly out of scope for testing in this phase?
```

---

## Required Test Infrastructure

```text
What fixtures, test data, environment configuration,
or external service stubs are required before testing can begin?
```

| Requirement | Type | Owner | Status |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Unit Tests

```text
What units of behavior must be tested in isolation?
```

| Test ID | Component | Behavior Under Test | Expected Result | Fixture Required |
| --- | --- | --- | --- | --- |
| UT-001 |  |  |  |  |

---

## Integration Tests

```text
What interactions between components must be tested?
```

| Test ID | Components | Scenario | Expected Result | Fixture Required |
| --- | --- | --- | --- | --- |
| IT-001 |  |  |  |  |

---

## Negative Tests

```text
Negative tests are mandatory.
What failure paths, invalid inputs, and boundary conditions must be tested?
```

| Test ID | Scenario | Input | Expected Failure Behavior |
| --- | --- | --- | --- |
| NT-001 |  |  |  |

---

## Security and Governance Tests

```text
What security and governance behaviors must be verified?
Authorization rules must have negative tests.
```

| Test ID | Rule | Test Description | Expected Result |
| --- | --- | --- | --- |
| ST-001 |  |  |  |

---

## Migration Tests

```text
If this phase includes schema or data migrations:
What must be verified before and after migration?
What is the rollback verification?
If not applicable, mark this section N/A with a reason.
```

---

## CLI and UAT Scenarios

```text
What user-observable behaviors must be verified through the CLI or UI?
These are the acceptance scenarios the operator will execute.
```

| Scenario ID | Description | Steps | Expected Output |
| --- | --- | --- | --- |
| UAT-001 |  |  |  |

---

## Manual Verification Steps

```text
What cannot be automated and must be verified by a human?
Each manual step must have an explicit expected outcome.
```

| Step | Action | Expected Outcome | Verified By |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Coverage Gaps

```text
What is not tested in this plan?
Each gap must have an explicit justification.
The absence of tests must be explicit and justified.
```

| Gap | Justification | Risk |
| --- | --- | --- |
|  |  |  |

---

## Verification Commands

```text
Commands that must pass for the phase to be accepted.
```

```bash
# Replace with project-specific commands
```

---

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass.

Check for:

```text
[ ] test cases that do not map to a requirement or architecture rule
[ ] negative tests absent for any authorization or validation rule
[ ] security tests missing for any security requirement
[ ] required fixtures not listed in test infrastructure
[ ] UAT scenarios with no expected output
[ ] coverage gaps without explicit justification
[ ] migration tests absent when this phase includes schema changes
```

---

## Acceptance Evidence

```text
What evidence must exist to close this phase?
```

```text
[ ] required fixtures created and verified
[ ] unit tests pass
[ ] integration tests pass
[ ] negative tests pass
[ ] security tests pass
[ ] UAT scenarios executed and documented
[ ] coverage gaps justified
[ ] verification commands output recorded
```

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
