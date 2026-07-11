# Decision Record: G5 Phase Loop

Date: 2026-06-12
Status: Accepted
Owner: GenDev maintainers

Historical note: this record predates the 1.0 release and remains accepted design evidence. Later
0.5 references in the compatibility table are historical, not current release targets.

## Context

The G5 to G6 span is where construction happens. The baseline methodology
treated that span as a single phase: G5 required exactly one phase build plan,
one tactical implementation plan, and one construction directive. Real systems
are built in multiple bounded, independently testable phases, both to reduce
code-generation drift and to surface defects through phase-by-phase exit testing
rather than big-bang integration.

The methodology had no first-class way to express an N-phase build, no partition
authority above the per-phase artifacts, no structured record of phase progress
or phase exits, and no template for the construction directive or build prompt
as distinct artifacts (these existed only as working drafts in an examination
folder, docs/methodology/templates/AI-Build-Kit/).

## Decision

Introduce the phase loop interior to the G5 to G6 span.

1. Two-tier semantics. The gate enumeration remains G0 through G9. Interior
   progress is tracked by checkpoints written `G5.x`, which are addresses, not
   gates, and carry no gate-approval ceremony.

2. Generalize G5. G5 certifies the phase plan (the ordered partition, the
   requirement coverage map, integration criteria, partitioning rationale)
   rather than a single phase's construction artifacts. Closing G5 is the
   checkpoint `G5.0`.

3. Per-phase checkpoint ladder: `G5.<id>.1` build plan, `G5.<id>.2` tactical
   plan, `G5.<id>.3` construction directive and build prompt, `G5.<id>.4` phase
   exit. G6 entry requires every declared phase exited, the regression suite
   green, and integration criteria satisfied or carried as residuals.

4. Phase id is a label, not a number. Order is defined by the phase plan and the
   manifest phases list, never computed from the id, so inserted and split
   phases (for example 10-5, 15a) remain expressible.

5. Six-artifact phase set: phase plan, phase build plan, tactical implementation
   plan, construction directive, build prompt, phase learnings. Each has a
   canonical template.

6. Structured events: `phase_checkpoint` (planning checkpoints) and
   `phase_transition` (phase exit) added to the gate-log model; manifest gains
   `phase_position` and a `phases` list. Checker validation is additive.

7. Phase discipline ships attested. Closure discipline (status, manifest, event
   in one commit) is attested, not mechanically enforced, in this release.

8. The AI-Build-Kit examination folder is harvested into canonical templates,
   the phase-loop guide, and the authoring prompts, then deleted. No references
   to it survive in the methodology body, with one explicit and bounded
   exception: the records that document its removal (this decision record and
   the release note) name it, because a record cannot describe the deletion of
   a thing it is forbidden to name. This carve-out is intent-preserving — D8's
   purpose is that the kit does not survive as a usable artifact or a live
   reference in the methodology, and a deletion record serves that purpose
   rather than violating it. The carve-out is limited to deletion records and
   extends to nothing else.

## Rationale

The two-tier model avoids overloading the gate enumeration, which the prior gate
numbering reconciliation showed to be a real hazard. Generalizing G5 rather than
adding gates keeps the enumeration stable and the change additive. The label
rule reflects observed practice, where phases are inserted and split mid-build.
Making learnings a first-class artifact carries phase experience forward through
documentation rather than through a drifting agent session, consistent with the
documentation-first thesis.

## Rejected Alternative

Model each phase artifact as a full gate with gate semantics, extending the
enumeration past G9. Rejected: it
amends the canonical enumeration, multiplies gates without bound on large
projects, and dilutes the meaning of a gate. The checkpoint model gives the
needed addressing and structure without those costs.

## Consequences

- gates.md gains a G5 generalization, a G6 entry amendment, and the interior
  section. The G0-G9 enumeration and all other gate criteria are unchanged.
- The constitution mirrors the G5 generalization and delegates phase-loop
  detail to gates.md.
- Enforcement contract gains one attested disposition statement.
- Existing initialized projects remain valid: phase-loop manifest fields are
  optional and the checker tolerates their absence.

## Verification

Executed in six phases with per-phase verification. Final state: checker green;
all ten gate headers intact; no bare ordinal gate numbering outside gates.md; no
checkpoint-as-gate language; the AI-Build-Kit folder is deleted and no
references survive except in the deletion records permitted by decision 8;
fresh project init and
legacy-manifest validation both pass.

## Append-Only Classification Notice: 2026-07-10

This notice preserves the complete historical record above. It does not alter
the original Accepted status or claim that a proposed successor is already
normative.

Current classification: **Active; proposed partial supersession pending human
ratification**.

Proposed successor:
`docs/methodology/design/operational-coherence-decision-record.md` (D-004,
D-005, D-006, D-011, D-012, D-013, D-016, D-017, and D-018).

If and only if that exact successor record is ratified, this record becomes
**Partially Superseded** with the following clause-level disposition:

| Historical clause | Disposition after ratification | Successor rule |
| --- | --- | --- |
| Decision item 1: checkpoints are `G5.x` addresses, not gates and carry no gate-approval ceremony | Remains active | D-004 preserves separate major-gate and phase-position axes. Named-human acceptance of checkpoint authority under D-011 is a checkpoint event, not a major-gate approval or transition. |
| Decision item 2: "Closing G5 is the checkpoint `G5.0`" | Superseded | D-004 makes `G5.0` a `phase_checkpoint` inside G5. The sole major transition out of G5 is `G5 -> G6` after the loop. |
| Decision item 3: checkpoint order, phase exit, and G6 entry | Partially superseded | Checkpoint order and label semantics remain active; D-005 supplies complete phase-exit evidence and D-018 supplies aggregate G5-to-G6 evidence. |
| Decision item 4: phase ID is a label ordered by the phase plan | Remains active | D-008 adds stable tactical IDs without changing phase ordering. |
| Decision item 5: "Six-artifact phase set" | Superseded as a complete-set claim | The six named artifacts remain members of D-005's larger canonical phase evidence set. |
| Decision item 6: event and manifest additions | Partially superseded | Distinct checkpoint/transition event types remain active; D-004, D-011, D-012, D-016, and D-018 impose schema-2 state and evidence bindings. |
| Decision item 7: attested closure discipline | Superseded for 0.5 strict operation | D-011 and D-012 require mechanically validated durable events and immutable evidence. Pinned older releases retain their declared enforcement. |
| Decision item 8: AI-Build-Kit removal | Remains active historical disposition | No operational-coherence decision restores that removed source. |
| Consequence: "all other gate criteria are unchanged" | Superseded only for G5-G9 overlap | D-004-D-006, D-017, and D-018 define the changed criteria; other gate-numbering intent remains active. |
| Consequence: phase fields optional and legacy manifests tolerated | Superseded | D-013 provides explicit version-bound pinning and migration; strict schema-2 fields are not permanently optional. |

The Context, rationale for bounded phases, rejected unbounded-gate alternative,
phase-label rule, and documentation-first learnings rationale remain active.
Until successor ratification, every clause above retains its prior authority.
