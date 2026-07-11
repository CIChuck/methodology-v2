# Phase Plan: [Project Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date:
Owner:
Position: G5.0
Authority: `docs/methodology/constitution/gendev.md` — Phase Plan (G5)
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/prd/prd.md
    revision: TBD
  - path: docs/project/architecture/architecture.md
    revision: TBD
  - path: docs/project/security-governance/governance-security-spec.md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
the build is partitioned into ordered, independently testable phases, every
in-scope requirement is assigned to a phase, and integration criteria are
declared. Accepting it closes G5 (checkpoint G5.0).
```

---

## Purpose

The phase plan partitions the build into ordered, independently testable phases.
It is the artifact that gate G5 certifies. It does not contain tactical
implementation detail — each phase still produces its own build plan, tactical
plan, construction directive, and build prompt inside the phase loop.

## Phase Sequence

Order in this table is authoritative. Phase ids are labels, not computed from
position; inserted or split phases keep stable ids (for example 10-5, 15a).

| Phase id | Name | Objective | Status |
| --- | --- | --- | --- |
|  |  |  | pending |

## Requirement Coverage Map

Every in-scope requirement maps to exactly one owning phase.

| Requirement id | Owning phase |
| --- | --- |
|  |  |

## Cross-Phase Rules

```text
Rules that hold across all phases: shared conventions, invariants that no phase
may break, interfaces that multiple phases depend on.
```

## Partitioning Rationale

```text
Why are the phases sized and ordered as they are?
Sizing criterion: features testable together, bounded to what a focused
implementation session can hold with its authority. Record the reasoning so a
future reader (or a re-partitioning decision) understands the original intent.
```

## Integration Criteria

```text
How will independently built phases be proven to compose into a working whole?
When do integration tests exist, and who declares them?
This is checked at G6 entry.
```

## Amendments

Record phase insertions and splits here with reasons. Each change updates the
manifest `phases` list in the same commit (per the amendment-and-regression
protocol).

| Date | Change | Reason |
| --- | --- | --- |
|  |  |  |

## Accuracy Pass

Before marking this document Accepted, identify:

```text
unassigned requirements:
phases too broad to build without drift:
phases with no testable exit:
undefined integration criteria:
ordering hazards:
```

## G5.0 Checkpoint — Phase Plan Ready (G5 Exit)

```text
[ ] every in-scope requirement is mapped to an owning phase
[ ] phase order is defined and ids are stable labels
[ ] partitioning rationale records the sizing criterion
[ ] integration criteria are declared
[ ] cross-phase rules are stated
```

Closure discipline: accepting this plan is the G5 gate transition, recorded as a
`gate_transition` event; the manifest `phase_position` is set to `G5.0` and the
`phases` list is populated in the same commit.
