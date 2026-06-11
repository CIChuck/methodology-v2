# As-Built Documentation Close-Out: [Project Name] — Phase [N]: [Phase Name]

Status: Draft | Ready for Review | Complete | Stale | Superseded
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Rule 9: As-Built Documentation Is Definition of Done
Source:
  Tactical Plan: `docs/project/build-plan/phases/[tactical-plan].md`
  Code Review Report: `docs/project/build-plan/phases/[review-report].md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/[tactical-plan].md
    revision: TBD
  - path: docs/project/build-plan/phases/[review-report].md
    revision: TBD
  - path: docs/project/traceability/[traceability-matrix].md
    revision: TBD
  - path: docs/project/testing/[test-uat-plan].md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
future developers can understand the actual system
without relying on chat history
```

A phase is not done until this document is complete.

---

## Implemented Behavior

```text
What was actually built in this phase?
Be precise. Do not describe planned behavior as implemented.
```

---

## Deferred Behavior

```text
What was planned but not built?
Where is each deferred item tracked?
```

| Item | Reason Not Implemented | Tracking Location |
| --- | --- | --- |
|  |  |  |

---

## Changed Assumptions

```text
What assumptions in the architecture, PRD, or phase plan proved incorrect?
What was changed as a result?
```

---

## Documentation Updated

### Developer Guide

```text
[ ] updated  [ ] not applicable
Notes:
```

### Architecture Specification

```text
[ ] updated  [ ] not applicable
Notes:
What changed from the planned architecture?
```

### PRD Status

```text
[ ] updated  [ ] not applicable
Notes:
Which requirements were implemented, deferred, or changed?
```

### CLI and API Documentation

```text
[ ] updated  [ ] not applicable
Notes:
```

### Configuration Documentation

```text
[ ] updated  [ ] not applicable
Notes:
```

### Examples

```text
[ ] updated  [ ] not applicable
Notes:
What examples, sample outputs, or usage guides reflect the as-built behavior?
```

### Schema References

```text
[ ] updated  [ ] not applicable
Notes:
```

### Diagrams

```text
[ ] updated  [ ] not applicable
Notes:
```

### Traceability Matrix

```text
[ ] updated  [ ] not applicable
Notes:
```

### Deferred Feature Backlog

```text
[ ] updated  [ ] not applicable
Notes:
```

---

## Known Limitations

```text
What limitations exist in the implemented system?
What will future phases need to account for?
```

---

## Test Evidence

```text
What test results confirm the implementation is correct?
```

| Test Suite | Result | Date Run | Notes |
| --- | --- | --- | --- |
|  |  |  |  |

Verification command output:

```text
Paste or link to verification command output.
```

---

## Metrics Snapshot

```text
Run the methodology metrics command at phase close-out and paste or link the resulting report.
This is a snapshot, not a separate reporting database.
```

Command:

```bash
./scripts/methodology-metrics.sh docs/project
```

Snapshot:

```text
TBD
```

---

## Value Review Status

```text
If the phase reached production or produced measurable user value, summarize the value review.
If value review is not yet due, state the read trigger and owner.
```

Value review artifact:

```text
docs/project/as-built/phase-[N]-value-review.md
```

Status:

```text
not_due | ready | complete | blocked
```

---

## As-Built Deviations

```text
Where did the implementation deviate from the tactical plan or construction directive?
What was the reason for each deviation?
```

| Deviation | Reason | Impact | Documentation Updated |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Accuracy Pass

Before marking this document Complete, perform an accuracy pass.

Check for:

```text
[ ] implemented behavior described as planned but not actually built
[ ] deferred items that are missing from the tracking location
[ ] changed assumptions that were not propagated to architecture or PRD
[ ] documentation sections marked updated but not actually reconciled
[ ] test evidence that references a run that did not pass
[ ] metrics snapshot missing when phase close-out is requested
[ ] value review status missing when deployment or measurable user value occurred
[ ] as-built deviations that lack a documented reason
[ ] known limitations that affect future phases but are not noted
```

---

## G9 Exit Checklist (As-Built Closed)

Before closing this phase:

```text
[ ] code review completed
[ ] critical and major findings remediated or accepted
[ ] tests and UAT evidence exist and are recorded
[ ] all documentation sections above are complete
[ ] examples updated to reflect as-built behavior
[ ] traceability matrix updated
[ ] methodology metrics snapshot recorded or explicitly deferred
[ ] value review status recorded or explicitly not due
[ ] deferred items tracked
[ ] known limitations documented
[ ] as-built deviations documented
```

Phase is closed: Yes | No
