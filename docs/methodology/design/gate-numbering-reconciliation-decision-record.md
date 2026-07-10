# Decision Record: Gate Numbering Reconciliation

Date: 2026-06-11
Status: Proposed
Owner: GenDev maintainers

## Context

The constitution used an older six-step gate enumeration while the rest of the methodology used
the G0-G9 lifecycle model.

The conflicting model created collisions. The most severe collision was the old ordinal 5, which
named Implementation Ready For Review in the constitution while canonical G5 names Build Ready in
the operating methodology. EC-1 also freezes implementation paths below G5, which is coherent only
under the G0-G9 model.

The canonical G0-G9 model is already used by the gate guide, enforcement contract, project
manifest, gate-log model, metrics, checker, practitioner guide, and initialized-project templates.

## Decision

Adopt G0-G9 as the single gate enumeration across the methodology and declare
`docs/methodology/guides/gates.md` canonical for gate numbers, gate names, and detailed entry/exit
criteria.

The constitution's Process Gates section mirrors the canonical enumeration and states that
`gates.md` controls in any conflict.

Mapping from the prior constitution enumeration:

| Prior constitution item | Canonical item | Note |
| --- | --- | --- |
| old ordinal 1: Vision Ready | G1: Vision Ready | number coincides |
| old ordinal 2: Requirements Ready | G2: Requirements Ready | number coincides |
| old ordinal 3: Architecture Ready | G3: Architecture Ready | number coincides |
| old ordinal 4: Build Ready | G5: Build Ready | collision |
| old ordinal 5: Implementation Ready For Review | G6: Implementation Ready For Review | collision |
| old ordinal 6: Acceptance Ready | G7: Acceptance Ready | collision; close-out content belongs to G9 |

## Rationale

The G0-G9 model is the active operating model. It supports explicit initialization, governance,
deployment readiness, and as-built close-out gates that the older six-step model did not represent.

Keeping two enumerations would cause agents to inherit the wrong authority when reading the
constitution first. Synchronizing the constitution to `gates.md` removes that ambiguity without
changing enforcement behavior.

## Alternatives Considered

Renumber `gates.md` back to the older six-step model.

Rejected because the checker, manifest, enforcement contract, gate log, metrics, practitioner
guide, and initialized-project templates already depend on G0-G9. Renumbering the operating model
would create broader breakage and would remove lifecycle boundaries that the hardened methodology
intentionally added.

## Consequences

Agents that read the constitution first now receive the same gate model used by the rest of the
repository.

Template section headers include both the canonical G-number and the canonical gate name, reducing
the chance that a future renumbering leaves stale labels behind.

The older acceptance close-out conflation is split: acceptance status maps to G7, while as-built
close-out content maps to G9.

## Test Impact

Validation must confirm that no bare old-style ordinal gate references remain under `docs/`, except
inside the canonical gate guide when intentionally discussing gate mechanics.

The methodology checker and guard must continue to pass. The EC-1 guard behavior must still reject
staged implementation-path changes below G5.

## Security/Governance Impact

G4: Governance Ready is now represented in the constitution. This aligns the constitution with the
security and governance lifecycle already required by `gates.md`.

Enforcement semantics are unchanged.

## Documentation Impact

Updated documentation:

- `docs/methodology/constitution/gendev.md`;
- `docs/methodology/guides/gates.md`;
- affected methodology templates;
- affected example code-review document.

## Deferred Follow-Up

Independent conformance review is required before merge. The reviewer should receive the build
prompt, the diff, and the verification transcript, but not the implementing agent's session
transcript.

## Append-Only Classification Notice: 2026-07-10

This notice preserves the original `Status: Proposed` header. The G0-G9
reconciliation is implemented in the current constitution, gate guide, manifest,
checker, and templates, and Git records the implementing change at
`bae030b91ec680042ea4e1f08641a8ababc4fc0b`. The repository does not contain a
separate durable human-ratification record sufficient to rewrite the historical
header to Accepted, so this notice does not manufacture one.

Coherence classification: **Active implemented baseline rule with incomplete
ratification provenance; proposed partial supersession pending human
ratification**.

Proposed successor:
`docs/methodology/design/operational-coherence-decision-record.md` (D-004,
D-016, and D-018).

If and only if that exact successor record is ratified, the implemented G0-G9
rule remains active and this record is **Partially Superseded** as follows:

| Historical clause | Disposition after ratification | Successor rule |
| --- | --- | --- |
| Decision: adopt G0-G9 as the single enumeration | Remains active | D-004 and D-018 preserve G0-G9, including terminal G9. |
| Decision: `gates.md` is canonical for numbers, names, and detailed criteria | Partially superseded | Under D-016, the constitution delegates enumeration to the canonical lifecycle model, the JSON registry is its validated machine-readable contract, and `gates.md` remains the normative human explanation. |
| Mapping from the prior six-step constitution model | Remains active historical reconciliation | Operational coherence does not restore the retired numbering. |
| Consequence: acceptance maps to G7 and project close-out to G9 | Remains active and is made complete | D-018 supplies the aggregate G6-G9 evidence and approval ownership. |
| Security/Governance statement: "Enforcement semantics are unchanged" | Historical and superseded for 0.5 | D-004, D-005, D-006, D-011, D-012, and D-018 introduce explicit strict enforcement without changing numbering. |

The missing historical ratification provenance must remain visible in release
metadata under D-015. Until successor ratification, this notice classifies the
observed implementation but grants no new normative authority.
