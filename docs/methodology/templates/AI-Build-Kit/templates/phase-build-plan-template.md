# Phase X Build Plan

Status: Draft  
Date: YYYY-MM-DD  
Phase: Phase X  
Project:

## 1. Source Authority

List every document used to construct this build plan.

Required where available:

```text
Phase Roadmap:
Project methodology documents:
PRD / requirements:
Architecture specifications:
Governance/security specifications:
Prior phase plans:
Prior phase code reviews:
Deferred backlog:
```

## 2. Phase Objective

Define the central purpose of Phase X in one to three paragraphs.

The objective must be specific enough to determine whether the phase succeeded.

## 3. Phase Scope

Define what Phase X is authorized to build.

Use concrete bullets.

## 4. Explicit Non-Goals

Define what Phase X must not build.

Include deferred features and adjacent work that may be tempting but is outside the phase.

## 5. Methodology Baseline

Identify project methodology rules this phase must follow.

Examples:

```text
documentation-first implementation
phase-boundary discipline
test-centered planning
security/governance as first-class requirements
documentation close-out as definition of done
```

## 6. Architecture Baseline

Summarize architecture rules or constraints that govern this phase.

Include:

```text
core objects or subsystems
ownership boundaries
state/lifecycle rules
interfaces
configuration rules
data model implications
```

## 7. Governance And Security Baseline

Identify security, governance, identity, permission, audit, approval, policy, data sensitivity, or secrets-handling requirements.

If none apply, state why.

## 8. Workstreams

| Workstream | Purpose | Required Outcome | Tests / UAT | Notes |
| --- | --- | --- | --- | --- |
| WS-1 |  |  |  |  |

## 9. Dependencies

List required prior work, documents, code, tooling, schema, config, or environment prerequisites.

## 10. Migration / Removal Requirements

If the phase changes existing behavior, define:

```text
what is replaced
what is adapted
what is removed
what is rejected
what compatibility is or is not required
```

## 11. Test Strategy

Define required test categories:

```text
unit tests
integration tests
security/governance tests
negative tests
migration tests
CLI/API/UAT checks
manual verification, if needed
```

Target:

```text
90% meaningful test coverage for new or materially changed code unless impractical and justified
```

## 12. Acceptance Criteria

List phase-level acceptance criteria.

Each criterion should be testable or inspectable.

## 13. Documentation Close-Out

Define documentation updates required when Phase X is complete.

Include:

```text
developer docs
architecture docs
CLI/API/config docs
examples
test evidence
deferred backlog
known limitations
```

## 14. Risks

List implementation, architecture, security, test, migration, and documentation risks.

## 15. Open Questions

List questions that should be resolved before tactical implementation planning.

## 16. Accuracy Pass

Identify:

```text
errors:
omissions:
contradictions:
scope drift:
missing tests:
missing security/governance requirements:
missing documentation close-out:
unresolved blockers:
opportunities for improvement:
```
