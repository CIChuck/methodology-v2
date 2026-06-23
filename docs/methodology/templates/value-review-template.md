# Value Review: [Project Name] — Phase [N]: [Phase Name]

Status: Draft | Ready for Review | Complete | Stale | Superseded
project: [project-slug]
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Measurement Principle
Source:
  Vision: `docs/project/vision/vision.md`
  As-Built Close-Out: `docs/project/as-built/phase-[N]-as-built-closeout.md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/vision/vision.md
    revision: TBD
  - path: docs/project/as-built/phase-[N]-as-built-closeout.md
    revision: TBD

---

## Purpose

```text
Compare the measurable success criteria declared at G1 against actual post-deployment evidence.
```

This review prevents the project from redefining success after delivery.

---

## Completion Standard

This document is complete when:

```text
each due G1 success criterion is reported as met, missed, or unmeasurable with evidence
```

---

## Read Context

| Field | Value |
| --- | --- |
| Phase | [N] |
| Production or value event | TBD |
| Read date | [YYYY-MM-DD] |
| Reviewer | TBD |
| Evidence sources reviewed | TBD |

---

## Success Criteria Actuals

Use one row for each due G1 success criterion.

| Criterion | Measure | Target | Actual | Result | Evidence Source | Notes |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  | met \| missed \| unmeasurable |  |  |

---

## User Acceptance

The UAT scenarios designed at G2 (one per feature) are executed here. User
acceptance is partly objective and partly subjective, and this section keeps the
two honest rather than pretending the subjective part away. What is objective (the
feature is present, it responds, the response time is within target) is recorded as
a result. What is subjective (is it good enough) is framed against the scenario and
a checklist, so the judgment is made against a defined frame, not a vibe.

| Feature | UAT scenario | Present | Responsive (target/actual) | User verdict | Notes |
| --- | --- | --- | --- | --- | --- |
|  |  | yes \| no |  | accepted \| rejected \| conditional |  |

```text
For each feature, provide the user a checklist and hints for how to test it:
  what action to take;
  what response to expect;
  what "good enough" looks like for this feature.
A rejected or conditional verdict is a follow-up decision below, not a silent
failure. Disagreement between users is recorded, not averaged away.
```

---

## Unmeasurable Criteria

```text
List any criterion that could not be measured, why it could not be measured, and what must change.
```

| Criterion | Reason | Required Follow-Up | Owner |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Outcome Summary

```text
What did the project learn about product value?
Do not count activity as value. Use outcome evidence where possible.
```

---

## Follow-Up Decisions

| Decision Needed | Owner | Due | Notes |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Accuracy Pass

Before marking this review Complete, check:

```text
[ ] each due criterion has an actual result
[ ] every result has an evidence source or a reason it is unmeasurable
[ ] missed criteria are not reframed as success without a decision record
[ ] follow-up decisions have owners
[ ] the as-built close-out points to this value review
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
