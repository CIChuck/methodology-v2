# Vision / Problem Framing: [Project Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
project: [project-slug]
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Vision / Problem Framing
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  <!-- Each revision must be the hash of the last commit that touched the
       source path: git log -1 --format=%H -- <path>. When a source moves
       (every gate closure moves it), run:
       ./scripts/pin-provenance.sh <this file>   to repin automatically. -->
  - path: initial human prompt or project brief
    revision: N/A

---

## Completion Standard

This document is complete when:

```text
the team can explain why the work matters and what success looks like
with measurable success criteria that can be read after deployment
```

Do not proceed to PRD until this standard is met.

---

## Problem Statement

```text
What problem exists?
Who experiences it?
Why does it matter now?
```

<!-- Replace this block with a concise statement of the problem. -->
<!-- Do not describe the solution here. -->

---

## Target Users

```text
Who are the primary users or operators of this system?
Who are the secondary users?
Who is explicitly not a target user?
```

---

## User Pain or Opportunity

```text
What friction, cost, risk, or missed opportunity does this problem create?
Quantify where possible.
```

---

## Desired Outcomes

```text
What must be true when this project succeeds?
State outcomes, not features.
```

---

## Success Criteria

```text
How will success be measured?
Each criterion must be observable and testable. Each row must name the measure, target, timing, owner,
and evidence source needed for a later value review.
```

| Criterion | Measure | Target | Read Timing | Owner | Evidence Source |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

---

## Non-Goals

```text
What is explicitly out of scope for this effort?
What problems are adjacent but not being solved here?
```

Do not omit this section. Undocumented non-goals become scope creep.

---

## Strategic Constraints

```text
What constraints must the solution respect?
Examples: budget, timeline, regulatory, organizational, integration, existing systems.
```

---

## Major Assumptions

```text
What must be true for this effort to succeed that has not been verified?
```

Each assumption is a risk until confirmed.

---

## Major Risks

```text
What could prevent success?
What are the highest-impact unknowns?
```

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Initial Security, Governance, and Compliance Concerns

```text
Are there data sensitivity, identity, access, audit, or regulatory concerns?
Note them here even if not yet fully defined.
```

---

## Testability Implications

```text
What will be difficult to test?
Are there observable behaviors that confirm the problem is solved?
```

---

## Open Questions

```text
What must be answered before a PRD can be written?
```

| Question | Owner | Due |
| --- | --- | --- |
|  |  |  |

---

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass.

Check for:

```text
[ ] problem statement that describes a solution instead of a problem
[ ] success criteria with no measure, target, read timing, owner, or evidence source
[ ] non-goals that are actually in scope
[ ] assumptions that are stated as facts
[ ] risks with no mitigation
[ ] open questions with no owner
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

## G1 Exit Checklist (Vision Ready)

Before proceeding to PRD:

```text
[ ] problem is clear
[ ] target users are clear
[ ] success criteria are measurable and have read timing
[ ] non-goals are documented
[ ] open questions have owners
```
