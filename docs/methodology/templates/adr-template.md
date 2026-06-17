# ADR-[NNNN]: [Decision Title]

Status: Proposed | Ready for Approval | Accepted | Stale | Rejected | Superseded
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Rule 10: Decisions Must Be Durable
Supersedes: —
Superseded by: —
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: TBD
    revision: TBD

---

## Completion Standard

This record is complete when:

```text
the decision is stated, the rationale is documented,
alternatives are recorded, and consequences are explicit
```

Do not mark Accepted until all sections are complete.

---

## Context

```text
What situation, constraint, or open question requires a decision?
What forces are in tension?
What happens if no decision is made?
```

---

## Decision

```text
State the decision clearly and completely.
One decision per ADR.
```

---

## Rationale

```text
Why was this option chosen?
What evidence or reasoning supports it?
```

---

## Alternatives Considered

| Alternative | Reason Rejected |
| --- | --- |
|  |  |

---

## Consequences

### Positive

```text
What does this decision enable?
```

### Negative

```text
What constraints or costs does this decision introduce?
```

### Neutral

```text
What tradeoffs are accepted?
```

---

## Scope Impact

```text
What changes in build scope follow from this decision?
```

---

## Test Impact

```text
What test requirements follow from this decision?
```

---

## Security and Governance Impact

```text
What security or governance implications follow from this decision?
```

---

## Documentation Impact

```text
What other documents must be updated when this ADR is accepted?
```

---

## Accuracy Pass

Before marking this record Accepted, perform an accuracy pass.

Check for:

```text
[ ] decision that is ambiguous or could be interpreted more than one way
[ ] rationale that asserts rather than reasons
[ ] alternatives that were not genuinely considered
[ ] consequences that are incomplete or understated
[ ] scope, test, or security impacts that are missing
[ ] documentation impact items that are not listed
```

---

## Deferred Follow-Up

```text
What related decisions are being deferred?
```

| Decision | Reason Deferred | Target Phase |
| --- | --- | --- |
|  |  |  |

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
