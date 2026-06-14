# Phase Plan: [Project Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date: [YYYY-MM-DD]
Owner: TBD
Position: G5.0
Authority: docs/methodology/constitution/gendev.md
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/prd/[project-slug]-prd.md
    revision: TBD
  - path: docs/project/architecture/[project-slug]-architecture.md
    revision: TBD

## Purpose

The phase plan partitions the build into ordered, independently testable phases.
It is the artifact that G5 certifies. Accepting it closes G5 (checkpoint G5.0)
and authorizes the phase loop. The full template arrives with the phase-loop
template set; this stub holds the required structure.

## Phase Sequence

Order in this table is authoritative. Phase ids are labels, not computed from
position; inserted or split phases keep stable ids (for example 10-5, 15a).

| Phase id | Name | Objective | Status |
| --- | --- | --- | --- |
| 1 | TBD | TBD | pending |

## Requirement Coverage Map

| Requirement id | Owning phase |
| --- | --- |
| TBD | 1 |

## Partitioning Rationale

Record why phases are sized and ordered as they are. Sizing criterion: features
testable together, bounded to what a focused implementation session can hold
with its authority.

## Integration Criteria

State how independently built phases will be proven to compose, and who declares
the integration tests.

## Amendments

Record phase insertions and splits here with reasons. Each change updates the
manifest phases list in the same commit.

| Date | Change | Reason |
| --- | --- | --- |

## G5.0 Checkpoint — Phase Plan Ready (G5 Exit)

[ ] every in-scope requirement is mapped to an owning phase
[ ] phase order is defined and ids are stable labels
[ ] partitioning rationale records the sizing criterion
[ ] integration criteria are declared
