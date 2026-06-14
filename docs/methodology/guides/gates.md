# Methodology Gates

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

Gates define when agents may proceed and when they must stop. They convert the methodology into
objective lifecycle checkpoints.

The Process Gates section of `docs/methodology/constitution/gendev.md` mirrors this enumeration;
this document is canonical for gate numbers, names, and detailed entry/exit criteria.

Use this guide with `docs/methodology/guides/gate-transition-protocol.md` for the procedural steps
needed to move from one gate to another.

Use `docs/methodology/guides/amendment-and-regression-protocol.md` when accepted authority changes
after later gate work has begun.

Gate status values:

```text
pending
drafting
ready_for_review
ready_for_approval
approved
blocked
superseded
```

Artifact status values used as gate evidence:

```text
Draft
Ready for Review
Ready for Approval
Accepted
Stale
Superseded
Complete
```

`Stale` means an upstream authority changed after the artifact pinned that authority. A stale
artifact should not support a gate transition until it is reconciled. `Superseded` means the
artifact has been replaced and should not govern current work.

Gate regression is not the same as amendment. Amendment changes accepted authority while the current
gate holds. Regression formally moves the current gate backward when the amendment invalidates gate
entry conditions.

## Gate Summary

| Gate | Name | Objective |
| --- | --- | --- |
| G0 | Project Initialized | Confirm the cloned baseline has an active project workspace. |
| G1 | Vision Ready | Establish why the product exists and what success means. |
| G2 | Requirements Ready | Convert the vision into testable product requirements. |
| G3 | Architecture Ready | Define system structure, boundaries, lifecycle, and technology decisions. |
| G4 | Governance Ready | Make security, policy, identity, audit, and agent/tool behavior explicit. |
| G5 | Build Ready | Authorize a bounded implementation phase. |
| G6 | Implementation Ready For Review | Confirm implementation is ready for conformance review. |
| G7 | Acceptance Ready | Decide whether implementation can be accepted after review and remediation. |
| G8 | Deployment Ready | Confirm the accepted product state can be deployed or released. |
| G9 | As-Built Closed | Preserve the implemented state for future work. |

## G0: Project Initialized

Purpose: Confirm a cloned baseline has an active project workspace.

Required:

- `docs/project/project.yaml`;
- active project folders;
- root `AGENTS.md`;
- `docs/methodology/constitution/gendev.md`;
- project name and slug.

Human approval: not required unless initialization overwrites an existing project.

Exit criteria:

- manifest paths are syntactically valid;
- starter docs exist;
- current gate is recorded as `G1`.

Agents must stop if:

- `docs/project/` is missing;
- manifest authority paths do not exist;
- project name or owner is unclear.
- required authority or evidence artifacts are marked `Stale` or `Superseded`.
- an active structural amendment has not been reconciled.

## G1: Vision Ready

Purpose: Establish why the product exists and what success means.

Required:

- vision/problem framing document;
- target users;
- success criteria;
- non-goals;
- assumptions, risks, and open questions.

Human approval: required.

Exit criteria:

- problem statement is clear;
- target users are clear;
- success criteria are measurable and include read timing;
- non-goals are explicit;
- blocking open questions are assigned.

Agents must stop if:

- the problem is actually a proposed implementation without user context;
- success criteria are not measurable;
- product scope depends on unresolved human decisions.
- the vision evidence is marked `Stale` or `Superseded`.
- a vision amendment invalidates the proposed PRD direction.

## G2: Requirements Ready

Purpose: Convert vision into testable product requirements.

Required:

- PRD;
- stable requirement IDs;
- functional and non-functional requirements;
- acceptance criteria;
- edge cases;
- deferred items;
- testability notes.

Human approval: required.

Exit criteria:

- every baseline requirement has acceptance criteria;
- requirements are specific enough for architecture and tests;
- deferred items have reasons;
- open questions that block architecture are resolved or assigned.

Agents must stop if:

- requirements contradict the vision;
- acceptance criteria are untestable;
- baseline scope is too broad for coherent architecture.
- the PRD or source vision evidence is marked `Stale` or `Superseded`.
- a PRD amendment changes baseline requirements without downstream reconciliation.

## G3: Architecture Ready

Purpose: Define system structure, boundaries, lifecycle, and technology decisions.

Required:

- architecture specification;
- technology stack decision record;
- terminology and domain model;
- component ownership;
- runtime and data model;
- state lifecycle;
- interfaces;
- error and failure behavior;
- deferred architecture.

Human approval: required.

Exit criteria:

- architecture rules trace to requirements;
- ownership boundaries are clear;
- state and lifecycle are defined;
- stack decision is accepted;
- implementation does not need to invent core structure.

Agents must stop if:

- component boundaries overlap;
- stack decisions are missing;
- security-sensitive architecture is implicit;
- required external services are not approved.
- the architecture, stack decision, or source requirement evidence is marked `Stale` or
  `Superseded`.
- an architecture amendment changes ownership, runtime, data, or stack behavior without downstream
  reconciliation.

## G4: Governance Ready

Purpose: Make security, policy, identity, audit, and agent/tool behavior explicit.

Required:

- governance/security specification;
- identity model;
- roles and permissions;
- authorization rules;
- approval model;
- audit model;
- secrets handling;
- data sensitivity model;
- trust boundaries;
- tool/external-system access rules;
- security and negative tests.

Human approval: required.

Exit criteria:

- every actor has permitted and forbidden actions;
- authorization rules include positive and negative tests;
- audit requirements are explicit;
- secrets and sensitive data handling are defined;
- agent/tool stop conditions are documented or marked N/A.

Agents must stop if:

- authorization behavior is inferred rather than documented;
- external tool access is unclear;
- data sensitivity is not classified;
- security tests are missing for security requirements.
- the governance/security artifact or source architecture evidence is marked `Stale` or
  `Superseded`.
- a governance/security amendment changes authorization, audit, data, tool, or approval behavior
  without downstream reconciliation.

## G5: Build Ready

Purpose: Authorize the build by ratifying the phase partition. The
implementation itself is carried out through the phase loop interior to the
G5 to G6 span (see "G5 Interior: The Phase Loop" below). G5 certifies the
plan that governs that loop; it does not certify any single phase's
construction artifacts, which are produced and accepted at interior
checkpoints.

Required:

- phase plan (the ordered partition of the build into phases);
- requirement coverage map (each requirement mapped to an owning phase);
- integration criteria (how independently built phases will be proven to
  compose, and who declares the integration tests);
- partitioning rationale (why the phases are sized and ordered as they are).

Human approval: required.

Exit criteria:

- the build is partitioned into ordered, independently testable phases;
- every phase carries a stable phase id, and ordering is defined by the phase
  plan (never computed from the id);
- the requirement coverage map accounts for all in-scope requirements;
- integration criteria are declared;
- the partitioning rationale records the sizing criterion (features testable
  together, bounded to what a focused implementation session can hold with its
  authority).

Closing G5 is the checkpoint addressed as `G5.0`: the phase plan is accepted
and the phase loop may begin.

Agents must stop if:

- the partition leaves requirements unassigned to any phase;
- a phase is too broad to build without losing the thread (drift risk);
- integration criteria are undefined;
- the phase plan or its source authority evidence is marked `Stale` or
  `Superseded`;
- an active amendment affects the partition, coverage, or integration criteria.

## G5 Interior: The Phase Loop

Checkpoints are not gates. The gate enumeration is and remains G0 through G9;
the positions described here are checkpoints interior to the G5 to G6 span,
written `G5.x`. A checkpoint is a progress address, not a gate: it carries no
separate gate-approval ceremony and never appears in the gate enumeration. The
`G5.x` form is deliberately a sub-address of the G5 to G6 span so it cannot be
mistaken for a gate.

After G5 closes (`G5.0`), the project holds an accepted phase plan. The build
then proceeds one phase at a time. For each phase, identified by a stable phase
id, the loop produces four planning artifacts and one execution result, marked
by these checkpoints:

```
G5.0          G5 closed: phase plan accepted               (gate_transition)
G5.<id>.1     phase build plan ready                       (phase_checkpoint)
G5.<id>.2     tactical implementation plan ready           (phase_checkpoint)
G5.<id>.3     construction directive ready and build
              prompt issued at a pinned revision           (phase_checkpoint)
G5.<id>.4     phase exit: built, tested, learnings written (phase_transition)
```

### Checkpoint to template binding

| Position | Closes when | Owning template (`docs/methodology/templates/`) | Authoring prompt |
| --- | --- | --- | --- |
| G5.0 | phase plan `Accepted` at a pinned revision; `gate_transition` recorded | `phase-plan-template.md` | Phase Plan Prompt |
| G5.\<id\>.1 | phase build plan `Accepted`; `phase_checkpoint` recorded | `phase-build-plan-template.md` | Phase Build Plan Prompt |
| G5.\<id\>.2 | tactical plan `Accepted`; `phase_checkpoint` recorded | `tactical-implementation-template.md` | Tactical Implementation Plan Prompt |
| G5.\<id\>.3 | construction directive `Accepted` and build prompt issued at a pinned revision; `phase_checkpoint` recorded | `phase-construction-directive-template.md` + `phase-build-prompt-template.md` | Construction Directive Prompt + Build Prompt Prompt |
| G5.\<id\>.4 | execution complete (below); `phase_transition` recorded | `phase-learnings-template.md` (output) | — |

### Checkpoint entry, exit, and closure discipline

A checkpoint's entry requires the prior checkpoint's event to exist and its
upstream artifact to be `Accepted` at a pinned revision. A checkpoint's exit is
the owning template's checkpoint checklist. Closure discipline (attested): the
artifact status change to `Accepted`, the manifest `phase_position` advance, and
the corresponding gate-log event land in the same commit.

### Phase id is a label

The position grammar is `G5.<phase-id>.<checkpoint>`, where the phase id is an
identifier such as `1`, `2`, `10-5`, or `15a`. Phases are inserted and split in
practice, so ids are not necessarily sequential integers. Phase order is defined
exclusively by the phase plan and the manifest `phases` list, and is never
computed from the id.

### Phase execution (the interior of G5.\<id\>.3 to G5.\<id\>.4)

1. Implementation proceeds from the pinned build prompt; the construction
   directive and tactical plan at their pinned revisions are the controlling
   authority, and scope conflicts resolve by the directive's precedence rules.
2. Generated work is reviewed against the phase artifacts; findings are
   remediated in a bounded loop until no blocking findings remain, with any
   remaining findings accepted as enumerated residuals.
3. The phase exit test, specified in the phase build plan, passes at the phase
   exit candidate revision.
4. The regression suite (the accumulated exit tests of all previously exited
   phases) is green at that revision. A prior phase's exit test failing is a
   regression, handled by the amendment and regression protocol.
5. Coverage standard: at least 90% meaningful coverage for new or materially
   changed code. A shortfall requires a written justification and a named
   residual risk, never silent acceptance.
6. A named approver (a human by default; a delegated reviewer context only where
   the project manifest explicitly authorizes it) records the phase exit
   decision with `decided_by` and a substantive `checked` statement in the
   `phase_transition` event.
7. The phase learnings document is authored as the final act of the phase and is
   the closing precondition of `G5.<id>.4`. It is required input to the next
   phase's tactical plan.

### Mid-phase amendments

An upstream defect discovered mid-phase is handled only through a recorded
amendment: an amendment event, a decision rationale, and reconciliation of the
upstream document, with the phase's `phase_transition` event referencing the
amendment. Silent edits to upstream documents to match what the code did are
defects. Phase insertions and splits are recorded in the phase plan's amendments
section with reasons, and the manifest `phases` list is updated in the same
commit.

### Blast-radius scaling

A single-phase project collapses the loop to `G5.0` plus one `G5.<id>.1`
through `G5.<id>.4` ladder. A GenDev Lite project may combine checkpoints
`G5.<id>.1` through `G5.<id>.3` into a single planning pass, provided the
scaling decision is recorded. The phase exit (`G5.<id>.4`) and its exit test are
not waivable: a phase that cannot be tested has not been bounded correctly.

## G6: Implementation Ready For Review

Purpose: Confirm implementation is ready for conformance review.

Entry criteria:

- every phase declared in the phase plan has a closed `G5.<id>.4` event;
- the accumulated regression suite is green at the G6 candidate revision;
- the integration criteria declared in the phase plan are satisfied, or carried
  as enumerated residuals.

Required:

- implementation summary;
- changed files;
- tests added or updated;
- verification commands run or skipped with reasons;
- known deviations.

Human approval: not required before review, but required for accepting skipped critical
verification.

Exit criteria:

- authorized scope is implemented;
- required tests were run or skipped with reason;
- no known deferred-feature leakage is unreported;
- documentation changes needed for review are present or identified.

Agents must stop if:

- verification failures are hidden;
- implementation changed unapproved architecture or security behavior;
- destructive migration or production action is pending.
- the construction directive cannot be produced or is not tied to the resulting implementation
  reference.
- implementation reveals a structural authority gap that requires amendment or regression.

## G7: Acceptance Ready

Purpose: Decide whether implementation can be accepted after review and remediation.

Required:

- code review report;
- remediation plan or summary, if findings exist;
- passing verification evidence or accepted exceptions;
- updated test/UAT evidence;
- updated traceability matrix.

Human approval: required for critical/major finding acceptance and phase acceptance.

Exit criteria:

- critical findings are remediated;
- major findings are remediated or explicitly accepted with rationale;
- tests and UAT evidence exist;
- residual risk is documented;
- traceability matrix reflects actual status.

Agents must stop if:

- findings lack remediation;
- verified status lacks evidence;
- documentation still describes planned behavior as implemented.
- the review evidence, test/UAT evidence, or traceability evidence is marked `Stale` or
  `Superseded`.
- review findings require an unresolved amendment to accepted authority.

## G8: Deployment Ready

Purpose: Confirm the accepted product state can be deployed or released.

Required:

- deployment target and environment assumptions;
- config/secrets documentation;
- migration and rollback plan;
- operational checks;
- security sign-off for production-sensitive behavior;
- release notes or deployment checklist;
- production runbook;
- post-deployment validation plan;
- monitoring and alert review;
- incident and rollback decision procedure.

Human approval: required.

Exit criteria:

- release scope is accepted;
- deployment commands and rollback commands are documented;
- sensitive environment variables and secrets are accounted for;
- production-impacting migrations are approved;
- known limitations are visible;
- post-deployment owner is identified.

Agents must stop if:

- production secrets or credentials are requested in chat;
- rollback is undefined for irreversible changes;
- deployment target is not approved;
- release would bypass human approval.
- deployment readiness, runbook, monitoring, rollback, or release evidence is marked `Stale` or
  `Superseded`.
- an active amendment affects release scope, operational risk, monitoring, rollback, or runbook
  procedure.

## G9: As-Built Closed

Purpose: Preserve the implemented state for future work.

Required:

- as-built close-out document;
- updated architecture/PRD/config/API/CLI docs as needed;
- updated examples or usage docs;
- known limitations;
- deferred backlog;
- final traceability matrix update.

Human approval: required for phase close.

Exit criteria:

- future agents can understand the actual system without chat history;
- implemented behavior, deferred behavior, and deviations are explicit;
- test evidence is recorded;
- next phase or backlog state is clear.

Agents must stop if:

- as-built docs are missing;
- traceability is stale;
- planned but unbuilt behavior is described as done.
- close-out evidence is marked `Stale` or `Superseded`.
- active amendments or regressions remain unresolved.

## Gate Progression

Default progression:

```text
G0 -> G1 -> G2 -> G3 -> G4 -> G5 -> G6 -> G7 -> G8 -> G9
```

Some projects may combine gates, but they must preserve the required content, evidence, and human
approvals.

## Blast-Radius Scaling

The project manifest declares the blast-radius class under `scaling.blast_radius_class`.

```text
C1 Contained
  Internal tools, reversible outputs, no sensitive data, low operational risk.

C2 Standard
  Default product work, moderate operational or data risk, ordinary production release discipline.

C3 Critical
  Regulated data, irreversible actions, external integrations, production-sensitive automation,
  agentic runtime behavior, or high operational impact.
```

Blast-radius class controls how much lifecycle ceremony may be compressed or must be expanded. It
does not change the obligation to preserve durable authority, traceability, approval, and review
evidence.

| Class | Gate/artifact handling | Non-negotiables |
| --- | --- | --- |
| C1 Contained | G1-G4 may combine into one framing document if the required content exists. Per-phase planning and close-out may combine when implementation is small and reversible. | Build-ready approval, production approval if deployed, explicit architecture and security assumptions, verification evidence, as-built close-out. |
| C2 Standard | Use the full default chain. Gates combine only with recorded justification and human approval. | G4, G5, G8, and G9 approval evidence; independent review for implementation acceptance; traceability and metrics records. |
| C3 Critical | Do not combine gates. Expand review, evidence sampling, enforcement, and override discipline beyond the baseline. | Reviewer independence, evidence sampling at every major gate, strict production approval, explicit rollback or irreversibility decision, stricter override policy. |

## Combined Gate Records

Gate combination is allowed only when the project records the decision. Record the decision in
`docs/project/project.yaml` under `scaling.combined_gates` and, when it changes authority or risk,
also in `docs/project/approvals/gate-log.md` or a decision record.

Recommended manifest shape:

```yaml
scaling:
  blast_radius_class: C1
  classification_reason: Internal reversible utility with no sensitive data.
  combined_gates:
    - gates: G1-G4
      mode: combined_framing_document
      justification: Small C1 utility; required vision, PRD, architecture, and security assumptions are preserved in one artifact.
      approved_by: TBD
      approved_on: TBD
      evidence: docs/project/vision/[project-slug]-vision.md
```

The justification must explain why combination is appropriate, what content is preserved, and what
approval still applies. A combined gate with no justification is not a valid shortcut.

For small prototypes, G3 and G4 may be lightweight. They must still define architecture and security
assumptions explicitly.
