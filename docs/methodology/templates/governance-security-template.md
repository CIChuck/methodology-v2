# Governance and Security Specification: [Project Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
project: [project-slug]
Date:
Owner:
Authority: `docs/methodology/constitution/gendev.md` — Governance and Security Specification
Source:
  Vision: `docs/project/vision/vision.md`
  PRD: `docs/project/prd/prd.md`
  Architecture: `docs/project/architecture/architecture.md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/vision/vision.md
    revision: TBD
  - path: docs/project/prd/prd.md
    revision: TBD
  - path: docs/project/architecture/architecture.md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
security-sensitive behavior is explicit, testable,
and not left to implementation inference
```

---

## Scope

```text
What system or subsystem does this specification govern?
What is explicitly out of scope?
```

---

## Identity Model

```text
Who or what can act in this system?
```

| Actor | Type | Description |
| --- | --- | --- |
|  | human / service / agent |  |

---

## Roles and Permissions

```text
What can each role do?
What is each role explicitly forbidden from doing?
```

| Role | Permitted Actions | Forbidden Actions |
| --- | --- | --- |
|  |  |  |

---

## Authorization Rules

```text
What checks must occur before an action is permitted?
Authorization rules must be testable.
Every authorization rule requires a corresponding negative test.
A negative test verifies that the action is denied when authorization is absent or invalid.
```

| Action | Required Authorization | Positive Test | Negative Test |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Policy Model

```text
What policies govern system behavior independent of user actions?
Examples: retention policies, rate limits, expiration rules.
```

---

## Approval Model

```text
What actions require explicit approval before execution?
Who can approve?
What happens if approval is denied or times out?
```

---

## Audit Model

```text
What events must be logged?
What must each log record contain?
Where are logs stored?
Who can access logs?
How long are logs retained?
```

| Event | Required Fields | Retention | Access |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Secrets Handling

```text
What secrets does this system use?
How are they stored, rotated, and accessed?
What must never be logged or exposed?
```

| Secret | Storage | Rotation | Exposure Prohibition |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Data Sensitivity

```text
What data does this system handle?
How is each data category classified?
What handling rules apply?
```

| Data Category | Classification | Handling Rules |
| --- | --- | --- |
|  |  |  |

---

## Trust Boundaries

```text
Where does trust change in this system?
What must be validated at each boundary?
What must never cross a trust boundary without validation?
```

---

## Tool and External System Access

```text
If this system calls external APIs, tools, or services:
What is authorized to call what?
What input validation is required before each call?
What data may not be sent to external systems?
```

---

## Failure, Pause, and Recovery Behavior

```text
What happens when a component fails?
What happens when an external dependency is unavailable?
What states require operator intervention to recover?
Can the system resume safely after a partial failure?
```

---

## Revocation and Deactivation

```text
How are credentials, tokens, sessions, or agent authorizations revoked?
What happens to in-flight operations when a principal is deactivated?
```

---

## Threat Scenarios

```text
What are the most likely ways this system could be abused or compromised?
What mitigations exist for each?
```

| Threat | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
|  |  |  |  |

---

## Agentic System Requirements

Complete this section only if the system includes AI agents with tool use, autonomous execution, or side effects.

```text
If not applicable, mark this section N/A with a reason.
```

### Agent Identity

```text
How is each agent identified?
How is agent identity verified?
```

### Agent Authorization

```text
What is each agent permitted to do?
What requires human approval?
What is the agent explicitly prohibited from doing?
```

### Agent Audit

```text
What agent actions must be logged?
What must the log record for each action?
```

### Tool Use Rules

```text
What tools may agents use?
What inputs to each tool must be validated?
What data may not be passed to external tools?
```

### Stop and Pause Conditions

```text
Under what conditions must an agent stop and wait for human review?
How is a running agent halted?
```

---

## Security Tests

```text
Every security requirement must have a corresponding test.
```

| Requirement | Test Description | Test Type |
| --- | --- | --- |
|  |  |  |

Negative tests are required for all authorization rules.

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

## Completion Checklist

Before marking this document Accepted:

```text
[ ] identity model covers all actors
[ ] every actor has explicit permitted and forbidden actions
[ ] every authorization rule has a positive test and a negative test
[ ] audit model defines what is logged, where, and for how long
[ ] secrets handling covers all credentials used by this system
[ ] data sensitivity is classified with handling rules
[ ] trust boundaries are explicit and validated
[ ] threat scenarios have mitigations
[ ] agentic section completed or marked N/A with reason
[ ] every security requirement has a corresponding test
```

---

## Accuracy Pass

Before marking this document Accepted, perform an accuracy pass.

Check for:

```text
[ ] authorization rules that are implicit rather than stated
[ ] audit events that are missing or underspecified
[ ] secrets that are referenced but not covered in secrets handling
[ ] threat scenarios that lack mitigations
[ ] agentic behaviors that lack authorization rules
[ ] security requirements that have no corresponding test
```
