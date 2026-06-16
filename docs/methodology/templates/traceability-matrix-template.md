# Traceability Matrix: [Project Name]

Status: Active | Stale | Superseded
project: [project-slug]
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Traceability Matrix
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/prd/[prd-document].md
    revision: TBD
  - path: docs/project/architecture/[architecture-document].md
    revision: TBD
  - path: docs/project/build-plan/phases/[phase-build-plan].md
    revision: TBD
  - path: docs/project/testing/[test-uat-plan].md
    revision: TBD

---

## Purpose

```text
Prove requirement-to-test continuity.
Every material requirement must map forward to implementation and verification.
```

This document is updated at the close of each phase.

---

## Completion Standard

This document is complete when:

```text
major requirements have visible implementation and verification evidence
```

---

## Status Values

```text
planned      — requirement accepted; not yet implemented
implemented  — code exists; not yet verified
verified     — test or UAT evidence confirms implementation
deferred     — explicitly excluded from current scope
rejected     — requirement removed from scope with reason
blocked      — cannot proceed; dependency unresolved
```

---

## Matrix

| Req ID | Requirement | Source | Architecture Rule | Build Item | Tactical Task | Implementation | Test / UAT Evidence | Review Confirmation | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-001 |  |  |  |  |  |  |  |  | planned |  |

---

## Coverage Analysis

Update this section at the close of each phase.

### Requirements Without Architecture Coverage

```text
Requirements that have no corresponding architecture rule.
These cannot be implemented without architecture guidance.
```

| Req ID | Requirement | Action Required |
| --- | --- | --- |
|  |  |  |

### Architecture Rules Without Implementation Tasks

```text
Architecture rules that have no corresponding tactical task.
These may indicate unplanned scope.
```

| Architecture Rule | Action Required |
| --- | --- |
|  |  |

### Implementation Tasks Without Tests

```text
Tactical tasks that have no corresponding test.
Each gap must be justified or remediated.
```

| Task | Gap Justification |
| --- | --- |
|  |  |

### Tests Without Requirement Coverage

```text
Tests that do not map to any requirement.
These may be unnecessary or indicate undocumented scope.
```

| Test | Action Required |
| --- | --- |
|  |  |

### Deferred Requirements

```text
Requirements explicitly excluded from current scope.
```

| Req ID | Reason Deferred | Target Phase |
| --- | --- | --- |
|  |  |  |

### Blocked Requirements

```text
Requirements that cannot proceed due to unresolved dependencies.
```

| Req ID | Blocking Dependency | Owner |
| --- | --- | --- |
|  |  |  |

---

## Accuracy Pass

Before updating this matrix at phase close, perform an accuracy pass.

Check for:

```text
[ ] requirements marked verified without test or UAT evidence
[ ] requirements marked verified without review confirmation
[ ] implementation column referencing files that do not exist
[ ] deferred requirements with no target phase
[ ] blocked requirements with no owner or action
[ ] tests without requirement coverage that are not accounted for
[ ] coverage gaps that have not been justified or remediated
```

---

## Phase Update Log

```text
Record each update to this matrix.
```

| Date | Phase | Updated By | Summary of Changes |
| --- | --- | --- | --- |
|  |  |  |  |
