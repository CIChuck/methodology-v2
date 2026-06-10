# ADR-0001: Technology Stack

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
  - path: docs/project/prd/[prd-document].md
    revision: TBD
  - path: docs/project/architecture/[architecture-document].md
    revision: TBD

---

## Purpose

This record documents the technology stack decision for [Project Name].

```text
The stack decision is an architectural decision.
It must be made explicitly, documented with rationale,
and accepted before build planning or stack initialization begins.
```

No implementation tooling may be initialized until this ADR is Accepted.

---

## Completion Standard

This record is complete when:

```text
every stack concern has a documented decision and rationale,
alternatives considered are recorded,
consequences are explicit,
and quality gate commands are defined
```

Do not mark Accepted until all sections are complete and the architecture
specification Technology Stack section references this ADR.

---

## Context

```text
What is the nature of this project?
What constraints, organizational standards, team capabilities,
or integration requirements shape the stack decision?
What options were realistically available?
```

---

## Decision

The following technology stack is approved for this project.

### Runtime and Language

| Concern | Decision |
| --- | --- |
| Language |  |
| Runtime |  |
| Version |  |

### Package and Dependency Management

| Concern | Decision |
| --- | --- |
| Package manager |  |
| Lock file |  |

### Application Framework

| Concern | Decision |
| --- | --- |
| Framework |  |
| Version |  |

### Data and Persistence

| Concern | Decision |
| --- | --- |
| Data store |  |
| Query / ORM layer |  |
| Migration tool |  |

### Testing

| Concern | Decision |
| --- | --- |
| Unit test framework |  |
| Integration test approach |  |
| End-to-end test approach |  |

### Code Quality

| Concern | Decision |
| --- | --- |
| Linter |  |
| Formatter |  |
| Type checker |  |

### Infrastructure and Deployment

| Concern | Decision |
| --- | --- |
| Target environment |  |
| Containerization |  |
| CI/CD |  |
| Secrets management |  |

---

## Rationale

```text
Why was this stack chosen over the alternatives?
What project-specific factors drove this decision?
```

---

## Alternatives Considered

```text
What other stacks were evaluated?
Why was each alternative rejected?
```

| Alternative | Reason Rejected |
| --- | --- |
|  |  |

---

## Consequences

### Positive

```text
What does this stack enable or improve?
```

### Negative

```text
What constraints, risks, or costs does this stack introduce?
```

### Neutral

```text
What tradeoffs are accepted as neither good nor bad for this project?
```

---

## Constraints and Prohibited Substitutions

```text
What substitutions are not permitted without a new ADR?
What dependencies are explicitly prohibited?
```

```text
Deviations from this stack require a new ADR.
No substitution is valid until the superseding ADR status is Accepted.
Verbal or chat-based approvals are not sufficient.
```

---

## Quality Gate Commands

```text
What commands must pass before any phase is considered complete?
These become the verification baseline for all construction directives.
```

```bash
# Replace with project-specific commands
# Example: uv run pytest
# Example: npm test
# Example: bun test
```

---

## Test Impact

```text
What test framework decisions follow from this stack?
What fixtures or test infrastructure must be established in Phase 1?
```

---

## Security and Governance Impact

```text
What security implications follow from this stack?
What secrets management, credential handling, or data protection
constraints does this stack impose?
```

---

## Documentation Impact

```text
What must be updated in other documents when this ADR is accepted?
```

```text
[ ] docs/project/architecture/[architecture-document].md — Technology Stack section
[ ] AGENTS.md — Build, Test, and Development Commands section
[ ] docs/project/build-plan/ — phase plans may reference stack-specific tooling
```

---

## Implementation Initialization

When this ADR is Accepted:

```text
[ ] architecture specification Technology Stack section is complete
[ ] AGENTS.md build commands are updated for this stack
[ ] stack initialization may proceed (ci-init-stack.sh or equivalent)
[ ] Phase 1 build plan may reference stack tooling
```

---

## Accuracy Pass

Before marking this record Accepted, perform an accuracy pass.

Check for:

```text
[ ] stack concerns with no documented decision
[ ] decisions with no rationale
[ ] alternatives table that is empty or perfunctory
[ ] quality gate commands that are not project-specific
[ ] test impact that does not name the test framework
[ ] security impact that omits secrets management or credential handling
[ ] documentation impact checklist items that are incomplete
[ ] constraints section that does not name prohibited substitutions explicitly
```

---

## Deferred Follow-Up

```text
What stack decisions are being deferred to a later phase or ADR?
```

| Decision | Reason Deferred | Target Phase |
| --- | --- | --- |
|  |  |  |

---

## Review Cadence

```text
When should this decision be reviewed?
Under what conditions should it be revisited?
```
