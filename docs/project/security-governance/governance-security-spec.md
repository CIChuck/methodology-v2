# Governance and Security Specification: Eval Test Product

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date: 2026-06-11
Owner: TBD
Authority: `docs/methodology/constitution/gendev.md` — Governance and Security Specification
Source:
  Vision: `docs/project/vision/[vision-document].md`
  PRD: `docs/project/prd/[prd-document].md`
  Architecture: `docs/project/architecture/[architecture-document].md`
Produced by: TBD
Produced on: 2026-06-11
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/vision/[vision-document].md
    revision: TBD
  - path: docs/project/prd/[prd-document].md
    revision: TBD
  - path: docs/project/architecture/[architecture-document].md
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
