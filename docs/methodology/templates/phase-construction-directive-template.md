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

## 14. Anti-Drift Rules (First Principles Enforcement)

These rules are the construction-directive-level restatement of the six constitutional
principles. They are stated here in full, every phase, every directive, without exception,
regardless of which ones appear load-bearing for this phase's scope. The asymmetry that
decides this: a restated-but-irrelevant rule costs one ignored line; a silently dropped rule
that turns out to matter costs a missed violation. Restate all six every time.

Authority: the constitution's First Principles of Code Quality section. These are
not arbitrary house rules. They are the constitution's six named code-quality
principles, restated here at the point of generation so they are proximate and
active, not buried in a document read once at session start.

The AI builder must not:

```text
[YAGNI] implement deferred features
[YAGNI] broaden scope beyond what this directive explicitly authorizes
[KISS]  build a more complex structure than the requirement needs; the simplest solution
        that satisfies the requirement is the correct one
[DRY]   duplicate logic that already exists elsewhere in this codebase; if the same
        operation is needed, find and call what exists, do not rewrite it
[SRP]   have any single unit (function, class, module) do more than one coherent job;
        if a unit is doing two things, it should be two units
[LA]    produce behavior a reader would not expect from an obvious reading of the
        requirement; correctness without astonishment
[NAA]   introduce any entity, field, relationship, class, or interface not already
        present in the Accepted architecture's Domain Model; if a phase genuinely
        needs something not yet in the model, that is a finding to send upstream,
        not a silent addition
[GOV]   silently change architecture
[GOV]   weaken security or governance behavior
[GOV]   remove unrelated code
[GOV]   rewrite unrelated modules
[INT]   mark planned behavior as implemented unless fully implemented
[INT]   hide skipped tests or failed verification
```

Key: YAGNI = You Aren't Gonna Need It; KISS = Keep It Simple; DRY = Don't Repeat Yourself;
SRP = Single Responsibility; LA = Least Astonishment; NAA = No Undeclared Abstractions;
GOV = Governance; INT = Integrity.

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
