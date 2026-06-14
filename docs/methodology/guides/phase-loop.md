# Guide: The Phase Loop (G5 to G6)

Status: Active
Authority: `docs/methodology/constitution/gendev.md`; `docs/methodology/guides/gates.md`

## Purpose

This guide describes how a project moves through the interior of the G5 to G6
span: from an accepted phase plan, through one phase at a time, to a project
ready for conformance review. It is the operational companion to the "G5
Interior: The Phase Loop" section of `gates.md`, which is the normative source.
Where this guide and gates.md differ, gates.md controls.

## Gates and checkpoints

Gates are G0 through G9 and do not change. Inside the G5 to G6 span the project
passes through interior checkpoints written `G5.x`. A checkpoint is a progress
address, not a gate: it marks the acceptance of a planning artifact or the exit
of a phase. Checkpoints carry no separate gate-approval ceremony and never
appear in the gate enumeration.

## The loop

After G5 closes (`G5.0`), the project holds an accepted phase plan: the ordered
partition of the build into independently testable phases, with a requirement
coverage map and declared integration criteria. The build then proceeds one
phase at a time. For each phase, identified by a stable label:

```
G5.<id>.1   author the phase build plan        (phase_checkpoint)
G5.<id>.2   author the tactical plan           (phase_checkpoint)
G5.<id>.3   author the construction directive
            and issue the build prompt          (phase_checkpoint)
G5.<id>.4   build, test, exit                    (phase_transition)
```

### Checkpoints G5.\<id\>.1 through G5.\<id\>.3 — planning

These three checkpoints produce the phase's planning artifacts. Each artifact is
authored from its template, reviewed, and accepted at a pinned revision before
the next begins. The owning templates are bound to checkpoints in the table in
the gates.md interior section; the authoring prompts live in
`docs/methodology/templates/build-instructions-templates.md`.

These artifacts are context construction. The build plan defines what the phase
builds and, just as importantly, what it does not. The tactical plan designs the
build workstream by workstream. The construction directive walks the building
agent through the work precisely enough to prevent drift, and the build prompt
is the dispatch issued from it.

### Checkpoint G5.\<id\>.4 — build, test, exit

This is where construction happens. From the pinned build prompt:

1. The building agent implements the phase. The construction directive and
   tactical plan at their pinned revisions are controlling; scope conflicts
   resolve by the directive's precedence rules.
2. Generated work is reviewed against the phase artifacts. Findings are
   remediated in a bounded loop until no blocking findings remain; remaining
   findings are accepted as enumerated residuals.
3. The phase exit test (specified in the build plan) passes at the exit
   candidate revision.
4. The regression suite — the accumulated exit tests of all previously exited
   phases — is green at that revision. A prior exit test failing is a regression,
   handled by the amendment and regression protocol.
5. Coverage meets at least 90% meaningful coverage for new or materially changed
   code, or the shortfall is justified in writing with a named residual risk.
6. A named approver — a human by default, a delegated reviewer context only where
   the manifest explicitly authorizes it — records the exit decision with
   `decided_by` and a substantive `checked` statement in the `phase_transition`
   event.
7. The phase learnings document is authored as the final act of the phase.

## Rolling wave

Phase build plans lead the wave: you author them ahead, because stating what an
early phase will not build requires knowing what later phases will. But the
tactical plan and construction directive for a phase are authored just in time,
right before that phase is built, because each phase teaches something that
sharpens the next. The phase learnings document is the carrier: written at the
close of phase N, it is required input to phase N+1's tactical plan, and that
tactical plan must cite it.

This is deliberate. The building agent's experience does not live in a session
that drifts and then vanishes; it is written down, so the next phase rebuilds
that context from the document in a fresh session.

## Mid-phase amendments

An upstream defect discovered mid-phase is handled only through a recorded
amendment: an amendment event, a decision rationale, and reconciliation of the
upstream document, with the phase's `phase_transition` event referencing the
amendment. Silent edits to upstream documents to match what the code did are
defects. Phase insertions and splits are recorded in the phase plan's amendments
section with reasons, and the manifest `phases` list is updated in the same
commit.

## Exit to G6

When every phase declared in the phase plan has a closed `G5.<id>.4`, the
accumulated regression suite is green, and the integration criteria are
satisfied or carried as enumerated residuals, the project is ready for G6.

## Scaling

A single-phase project collapses the loop to `G5.0` plus one ladder. A GenDev
Lite project may combine the three planning checkpoints into a single pass,
provided the scaling decision is recorded. The phase exit and its exit test are
not waivable: a phase that cannot be tested has not been bounded correctly.
