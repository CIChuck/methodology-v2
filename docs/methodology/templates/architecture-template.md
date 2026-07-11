# Architecture Specification: [Project Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
project: [project-slug]
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Architecture Specification
Source:
  Vision: `docs/project/vision/vision.md`
  PRD: `docs/project/prd/prd.md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/vision/vision.md
    revision: TBD
  - path: docs/project/prd/prd.md
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

Once this section reaches Accepted status, it is the closed, approved list of
entities, fields, relationships, classes, and interfaces for this project. Every
entity, field, relationship, class, and interface a later phase introduces must
already be named here. If a phase's work genuinely requires something not yet in
this model, that is a finding: send it back as a deliberate, named amendment to
this document before the build proceeds. Nothing new is introduced silently
during generation. This is the enforcement point for the constitution's sixth
code-quality principle: No Undeclared Abstractions.

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

## Verification Specification

This section is the human-approved encoding of how the implementation will be
proven correct. It is derived from the G2 acceptance criteria (in EARS form for
C2/C3) and, because those criteria are already test-shaped, each entry here traces
directly back to a same-shaped requirement. A human approves this specification as
a faithful encoding of intent, separately from and before approving any code. That
approval is what lets the build phase grade generated code against this
specification rather than against prose, and lets an AI reviewer judge against
human-certified intent rather than its own reinterpretation.

For each requirement, record the verification that will prove it, across the three
verification questions the Verification-First Principle names. (Closely related
requirements verified by the same evidence may share an entry, but the default is
one entry per requirement.) Cross-cutting concerns (security, performance,
operational, deployment) are not a fourth category; they appear within these three.

```text
Requirement: REQ-...
Behavioral:    what proves the implementation does what is required, including the
               unwanted-behavior (If/then) cases — derived from the EARS criteria
Design:        what about this requirement depends on the design holding under
               stress (see the interrogation below); reference the failure mode
Implementation: what makes the code for this sound and durable (contracts, types,
               assumptions that must not erode)
UAT:           the user-facing scenario that demonstrates this feature (designed
               now, executed at phase exit)
```

Approved by: TBD
Approved on: TBD

The verification evidence itself (test results, reports, UAT logs) is not recorded
here; it attaches to the relevant artifacts as supporting artifacts through the
`tested-by` typed reference when the work is done.

The design row above draws on a design-verification interrogation: design
verification asks whether this architecture holds under the conditions it must
survive, evaluable now, on paper, before any code exists. Answer these prompts
proportional to blast radius — a C1 project may answer briefly, including an honest
"no failure modes beyond single-process operation"; a C3 project expands each into
a real analysis. The point is that the questions are asked and their answers
recorded, not deferred to an incident.

```text
What failure modes must this design survive (partition, network loss, crash and
  restart, partial failure, resource exhaustion)? For each, how does the design
  respond?
Where might this design not scale, and at what point?
Where might this design paint the project into an evolutionary corner — what future
  change would be expensive because of a decision made here?
What security boundaries does the design rely on, and what happens when one is
  crossed or fails?
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

## G3 Exit Checklist (Architecture Ready)

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
[ ] the verification specification exists, is human-approved, and traces to the G2 acceptance criteria
[ ] the design-verification interrogation is answered (proportional to blast radius)
```
