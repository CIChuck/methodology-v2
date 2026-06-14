# Phase Construction Directive: [Project Name] — Phase [id]: [Phase Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date:
Owner:
Position: G5.[id].3
Authority: `docs/methodology/constitution/gendev.md` — Rule 6 (AI Build Prompts Are Controlled Artifacts)
Source:
  Tactical Plan: `docs/project/build-plan/phases/[phase-tactical-plan].md`
  Phase Build Plan: `docs/project/build-plan/phases/[phase-build-plan].md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/[phase-tactical-plan].md
    revision: TBD
  - path: docs/project/build-plan/phases/[phase-build-plan].md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
it walks the building agent through the phase precisely enough to prevent drift,
and a build prompt can be issued from it without inventing scope or authority
```

---

## 1. AI Builder Role

You are an AI coding agent implementing Phase [id] from documented authority.
You follow the source authority and precedence, preserve phase boundaries,
implement required tests, and update required documentation. You do not invent
scope or architecture.

## 2. Source Authority and Precedence

Controlling documents, pinned at the revisions accepted for this phase. In a
conflict, the higher entry wins.

```text
1. Governance/Security Specification: [path] @ [revision]
2. Architecture Specification: [path] @ [revision]
3. PRD / Requirements: [path] @ [revision]
4. Phase Build Plan: [path] @ [revision]
5. Tactical Implementation Plan: [path] @ [revision]
6. This Construction Directive
```

## 3. Implementation Objective

State exactly what the AI builder must implement in this phase.

## 4. Allowed Scope

List the implementation scope. Nothing outside this list is authorized.

## 5. Explicit Non-Goals

List work the AI builder must not implement, including deferred features and
adjacent work. Name sibling phases by id where a capability belongs to them.

## 6. Required Coding Directives

Break the work into concrete coding directives. Every Directive ID names the
tactical workstream it implements, so the chain requirement → workstream →
directive is traceable. For each directive:

```text
Directive ID:            (e.g. D-WS1-01)
Parent workstream:       (the tactical workstream this implements)
Purpose:
Files/modules likely affected:
Required behavior:
Required tests:
Acceptance criteria:
Notes:
```

## 7. Migration / Removal Directives

Define replacement, deletion, rejection, compatibility, or migration behavior.

## 8. Security / Governance Directives

```text
identity:
permissions:
policy:
approval:
audit:
data sensitivity:
secrets:
tool/external access:
```

## 9. Test Directives

Require unit, integration, security/governance, negative, migration, and
CLI/API/UAT tests as applicable.

```text
Coverage target: at least 90% meaningful coverage for new or materially changed
code. A shortfall must be justified in writing with a named residual risk.
```

## 10. Verification Directives

List the commands to run and the expected evidence. If a command cannot be run,
the AI builder must explain why — never silently skip.

## 11. Documentation Close-Out Directives

List the documentation updates required before the phase can close.

## 12. Reporting Requirements

The AI builder must report:

```text
summary of changes
files changed
tests added or updated
commands run
skipped verification and reasons
documentation updated
coverage status
risks
deviations from directive
```

Honesty rules: report skipped verification, do not claim unimplemented behavior
as implemented, do not hide failures.

## 13. Stop Conditions

The AI builder must stop and ask if:

```text
source authority conflicts
required files or systems are missing
security/governance requirements are unclear
implementation would require deferred scope
tests cannot be meaningfully added
architecture must be changed
```

## 14. Anti-Drift Rules

The AI builder must not:

```text
implement deferred features
broaden scope
silently change architecture
weaken security or governance behavior
remove unrelated code
rewrite unrelated modules
mark planned behavior as implemented unless implemented
hide skipped tests or failed verification
```

## 15. Accuracy Pass

Verify:

```text
each tactical workstream has coding directives
each directive names its parent workstream
each directive has tests
security/governance requirements are represented
migration/removal requirements are represented
documentation close-out is represented
non-goals are explicit
stop conditions are explicit
```

---

## G5.[id].3 Checkpoint — Directive Ready

Before phase build begins:

```text
[ ] every tactical workstream has at least one coding directive
[ ] every directive names its parent workstream
[ ] authority is pinned at accepted revisions
[ ] stop conditions and anti-drift rules are explicit
[ ] the build prompt has been issued from this directive at a pinned revision
```

Closure discipline: the artifact status change to `Accepted`, the build prompt
issuance, the manifest `phase_position` advance to `G5.[id].3`, and the
`phase_checkpoint` event in the gate log land in the same commit.
