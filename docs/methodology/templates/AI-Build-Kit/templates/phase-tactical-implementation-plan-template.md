# Phase X Tactical Implementation Plan

Status: Draft  
Date: YYYY-MM-DD  
Phase: Phase X  
Project:

## 1. Source Authority And Precedence

List controlling documents in priority order.

```text
1. Phase X Build Plan:
2. Architecture Specification:
3. Governance/Security Specification:
4. PRD / Requirements:
5. Project methodology:
6. Prior phase artifacts:
```

If documents conflict, state which document controls.

## 2. Implementation Objective

Define what implementation must accomplish.

## 3. Assumptions

List implementation assumptions.

Separate confirmed assumptions from inferred assumptions.

## 4. Explicit Non-Goals

List what this tactical plan must not implement.

## 5. Workstreams

Repeat this section for each workstream.

### Workstream N: [Name]

Purpose:

Required implementation:

Affected modules / files / subsystems:

Data / schema impact:

API / CLI / configuration impact:

Security / governance impact:

Tests:

Negative tests:

Acceptance criteria:

Dependencies:

Non-goals:

## 6. Migration Order

Define implementation sequence.

For refactors, identify safe ordering:

```text
new model first
validation gates
runtime switching
legacy rejection
test replacement
documentation update
```

## 7. Test Plan

Define test requirements by category:

```text
unit:
integration:
security/governance:
negative:
migration:
CLI/API/UAT:
manual:
```

Target:

```text
90% meaningful test coverage for new or materially changed code unless impractical and justified
```

## 8. Verification Commands

List expected commands and what they prove.

## 9. Documentation Close-Out

List exact docs or doc categories that must be updated.

## 10. Acceptance Criteria

List tactical acceptance criteria tied to workstreams and tests.

## 11. Deferred Items

List features or improvements intentionally excluded from this phase.

## 12. Risks And Mitigations

List implementation risks and mitigations.

## 13. Accuracy Pass

Identify:

```text
missing implementation steps:
missing affected areas:
missing tests:
missing negative tests:
missing migration steps:
security/governance gaps:
documentation close-out gaps:
scope drift:
unresolved blockers:
opportunities for improvement:
```
