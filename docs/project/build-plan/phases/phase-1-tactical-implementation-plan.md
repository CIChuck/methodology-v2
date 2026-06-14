# Tactical Implementation Plan: Eval Test Product — Phase [N]: [Phase Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date: 2026-06-11
Owner: TBD
Authority: `docs/methodology/constitution/gendev.md` — Tactical Implementation Plan
Source:
  Phase Build Plan: `docs/project/build-plan/phases/[phase-build-plan].md`
  Architecture: `docs/project/architecture/[architecture-document].md`
  PRD: `docs/project/prd/[prd-document].md`
  Governance/Security: `docs/project/security-governance/[governance-document].md`
Produced by: TBD
Produced on: 2026-06-11
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/[phase-build-plan].md
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

1. Architecture Specification
2. Governance and Security Specification
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
What is explicitly out of scope for this implementation?
Agents must not implement these items.
```

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

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass.

Check for:

```text
[ ] workstreams that are too broad for a single implementation session
[ ] missing file or module ownership for any workstream
[ ] workstreams with no test requirements
[ ] negative tests that are absent for failure paths
[ ] verification commands that are missing or untestable
[ ] security requirements not covered by any workstream
[ ] schema changes without migration steps
[ ] documentation close-out items that are unassigned
```

---

## Gate 4 Exit Checklist

Before proceeding to construction directive:

```text
[ ] all workstreams are defined with explicit scope
[ ] every workstream has test requirements
[ ] every workstream has verification commands
[ ] schema and migration changes are fully specified
[ ] security requirements are workstream-assigned
[ ] documentation close-out is defined per workstream
[ ] plan is executable without architecture invention
```
