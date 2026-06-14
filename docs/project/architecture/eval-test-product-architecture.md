# Architecture Specification: Eval Test Product

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date: 2026-06-11
Owner: TBD
Authority: `docs/methodology/constitution/gendev.md` — Architecture Specification
Source:
  Vision: `docs/project/vision/[vision-document].md`
  PRD: `docs/project/prd/[prd-document].md`
Produced by: TBD
Produced on: 2026-06-11
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/vision/[vision-document].md
    revision: TBD
  - path: docs/project/prd/[prd-document].md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
implementation cannot reinterpret major object ownership or lifecycle behavior
```

Do not proceed to build planning until this standard is met.

---

## Purpose and Scope

```text
What system or subsystem does this specification govern?
What is the boundary of this architecture document?
```

---

## Terminology and Glossary

```text
Define terms used in this document.
Agents must not redefine these terms during implementation.
```

| Term | Definition |
| --- | --- |
|  |  |

---

## Technology Stack

This section is a required architectural decision.

```text
The technology stack must be decided and documented before implementation planning begins.
An Architecture Decision Record must be created for this decision.
See: docs/project/decisions/0001-technology-stack.md
```

### Runtime and Language

| Concern | Decision | Rationale |
| --- | --- | --- |
| Language |  |  |
| Runtime |  |  |
| Language version |  |  |

### Package and Dependency Management

| Concern | Decision | Rationale |
| --- | --- | --- |
| Package manager |  |  |
| Lock file strategy |  |  |
| Dependency update policy |  |  |

### Application Framework

| Concern | Decision | Rationale |
| --- | --- | --- |
| Primary framework |  |  |
| Version |  |  |
| Framework constraints |  |  |

### Data and Persistence

| Concern | Decision | Rationale |
| --- | --- | --- |
| Primary data store |  |  |
| ORM / query layer |  |  |
| Migration strategy |  |  |
| Schema ownership |  |  |

### Testing

| Concern | Decision | Rationale |
| --- | --- | --- |
| Unit test framework |  |  |
| Integration test approach |  |  |
| End-to-end test approach |  |  |
| Coverage requirements |  |  |

### Code Quality

| Concern | Decision | Rationale |
| --- | --- | --- |
| Linter |  |  |
| Formatter |  |  |
| Type checker |  |  |
| Quality gate commands |  |  |

### Infrastructure and Deployment

| Concern | Decision | Rationale |
| --- | --- | --- |
| Target environment |  |  |
| Containerization |  |  |
| CI/CD approach |  |  |
| Secrets management |  |  |

### Stack Constraints

```text
What substitutions are not permitted without an architecture exception?
What dependencies are explicitly prohibited?
```

### Stack Decision Record

```text
Reference the ADR that documents the rationale, alternatives considered,
and consequences of the stack decisions above.

ADR: docs/project/decisions/0001-technology-stack.md
Status: [ ] created  [ ] accepted
```

Do not begin build planning until the ADR is created and accepted.

---

## Domain Model

```text
What are the core entities in this system?
What does each entity own?
How do entities relate to each other?
```

Diagram if useful.

---

## Component Ownership

```text
What are the major components or modules?
What is each component responsible for?
What is each component explicitly not responsible for?
```

| Component | Responsibility | Boundary |
| --- | --- | --- |
|  |  |  |

---

## Runtime Model

```text
How does the system execute?
What processes, threads, queues, or agents are involved?
What is the startup and shutdown sequence?
What is the concurrency model?
```

---

## Data Model

```text
What data does the system persist?
What are the primary entities, their fields, and their types?
What are the relationships and constraints?
What data is sensitive?
```

Schema definitions belong here or in a linked schema document.

---

## State Lifecycle

```text
What stateful objects exist?
What states can each object occupy?
What transitions are permitted?
What transitions are forbidden?
```

State diagram if useful.

---

## Interfaces and Integration Points

```text
What APIs, CLI surfaces, events, or integration contracts does this system expose or consume?
```

| Interface | Direction | Contract | Version |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Error and Failure Behavior

```text
How does the system behave when a component fails?
What errors are recoverable?
What errors are terminal?
What does the system surface to users or operators on failure?
```

---

## Security-Sensitive Boundaries

```text
Where does trust change in this system?
What data crosses a trust boundary?
What must be validated at each boundary?
```

Full security treatment belongs in the Governance and Security Specification.

---

## Extension Points

```text
Where is the system designed to be extended?
What extension patterns are approved?
What must not be extended without an architecture exception?
```

---

## Deferred Architecture

```text
What architecture decisions have been explicitly deferred?
Each item must have a reason and a suggested future phase.
```

| Decision | Reason Deferred | Target Phase |
| --- | --- | --- |
|  |  |  |

---

## Diagrams

```text
Include or link diagrams where they reduce ambiguity.
Minimum: component boundary diagram.
Add: sequence diagrams for non-obvious flows, data flow diagrams for sensitive paths.
```

---

## Open Decisions

```text
What architecture questions are unresolved?
Each open decision blocks implementation of the affected component.
```

| Decision | Impact | Owner | Due |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Requirement Traceability

```text
Every major architecture rule must trace to one or more PRD requirements.
```

| Architecture Rule | PRD Requirement(s) |
| --- | --- |
|  |  |

---

## Acceptance Criteria Seed

```text
Tests are design artifacts — they must be seeded during architecture, not after code generation.
What tests will eventually prove this architecture is correctly implemented?
List them here. They become the starting point for the Test and UAT Plan.
```

```text
What unit behavior must be verifiable?
What integration points must be testable?
What security boundaries require negative tests?
What state transitions require assertion?
```

---

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass.

Check for:

```text
[ ] terminology that is undefined or used inconsistently
[ ] component boundaries that overlap or leave gaps
[ ] state transitions that are incomplete
[ ] interfaces that lack a contract
[ ] security boundaries that are implicit
[ ] stack decisions that are undocumented or lack an ADR
[ ] open decisions that block the critical path
[ ] architecture rules that cannot be tested
```

---

## Gate 3 Exit Checklist

Before proceeding to build planning:

```text
[ ] core terminology is stable and defined
[ ] technology stack is decided and ADR is accepted
[ ] system boundaries are unambiguous
[ ] component ownership is clear and non-overlapping
[ ] security and governance boundaries are explicit
[ ] state and lifecycle are fully defined
[ ] deferred architecture is marked with reasons
[ ] all architecture rules trace to PRD requirements
```
