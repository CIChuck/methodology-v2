# Gate Transition Protocol

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`,
`docs/methodology/guides/gates.md`,
`docs/methodology/guides/amendment-and-regression-protocol.md`,
`docs/methodology/guides/enforcement-contract.md`

## Purpose

This guide operationalizes gate movement. It defines what must be checked, approved, recorded, and
recommended when moving from one methodology gate to the next.

Gate transitions are procedural decisions. They should not happen implicitly.

## State Model

Artifact status and gate status are related but separate:

```text
Artifact status: Draft -> Ready for Review -> Ready for Approval -> Accepted
                 Stale | Superseded | Complete
Gate status:     pending -> drafting -> ready_for_review -> ready_for_approval -> approved
```

An artifact can be `Ready for Approval` before the gate is approved. A gate becomes `approved` only
after the human approval record is durable and `project.yaml` summarizes the decision.
`Stale` means an upstream authority changed after the artifact pinned that authority. Stale or
superseded artifacts should not be used as gate evidence until reconciled.
Active structural amendments should be reconciled before forward gate movement unless the human
explicitly records why the amendment does not affect the transition.
Every gate transition should be readable in its enforcement context: `attested` or `enforced`.

## Universal Transition Checklist

Before any gate transition, confirm:

```text
[ ] current gate is known
[ ] required source docs exist
[ ] required artifact status is Ready for Approval or Accepted
[ ] required artifact provenance fields are present
[ ] evidence revisions are pinned or explicitly marked TBD for draft work
[ ] no required evidence is Stale or Superseded
[ ] active amendments are reconciled or explicitly non-blocking
[ ] enforcement class is declared in project.yaml
[ ] attestation or enforcement evidence is recorded according to project policy
[ ] required approver is known
[ ] blocking questions are resolved or assigned
[ ] required tests or test plans are present for the gate
[ ] security/governance implications are addressed
[ ] known risks are listed or explicitly N/A
[ ] human approval is recorded when required
[ ] approval includes a substantive checked statement when the standard record is required
[ ] project.yaml is updated or update is queued
[ ] gate-log.md is updated or update is queued
[ ] next role and artifact are identified
```

## Transition Record

Recommended structured record:

````markdown
## Gate Event: G1 -> G2

```yaml
event_type: gate_transition
from_gate: G1
to_gate: G2
decision: approved
decided_by: TBD
gate_started_on: YYYY-MM-DD
ready_for_approval_on: YYYY-MM-DD
approval_requested_on: YYYY-MM-DD
decided_on: YYYY-MM-DD
enforcement_class: attested
blast_radius_class: C2
combined_gates: N/A
combined_gate_justification: N/A
artifact_status: Accepted
evidence:
  - path: docs/project/vision/vision.md
    revision: TBD
    status: Accepted
checked: "TBD: one substantive statement from the approver."
known_risks_accepted:
  - risk: TBD
    rationale: TBD
open_questions_carried_forward:
  - question: TBD
    owner: TBD
    target_gate: G2
conditions:
  - TBD
next_role: prd-agent
next_artifact: docs/project/prd/prd.md
manifest_updated: true
```
````

This record should live in `docs/project/approvals/gate-log.md` and may also live in the approved
artifact. `project.yaml` should summarize the current gate and approval state.

Legacy prose transition records may remain in existing projects during migration. New gate
transitions should use the structured form so tooling can identify the transition, approver,
evidence, risk disposition, and checked statement.

Before requesting approval, the lead agent should show the human:

```text
Gate:
Artifact status:
Evidence reviewed:
Evidence revisions:
Enforcement class:
Blast-radius class:
Combined gate justification, if applicable:
Attestation or enforcement evidence:
Open questions:
Known risks:
Risks requiring acceptance:
Proposed next gate:
Proposed next role:
Manifest updates to record:
```

If the gate transition depends on authority that changed after approval, follow
`docs/methodology/guides/amendment-and-regression-protocol.md` before requesting the transition.
Do not use stale evidence to move a gate forward.

## Amendment And Regression Checks

Before gate movement, the lead agent should inspect:

```text
docs/project/project.yaml amendments section
docs/project/approvals/gate-log.md amendment events
artifact Status fields for Stale or Superseded
Derived from revisions for affected authority
```

If an accepted artifact was amended:

- editorial amendments do not block transition unless they reveal a semantic issue;
- additive-within-scope amendments require lightweight approval and downstream review;
- structural amendments require explicit approval and downstream reconciliation;
- amendments that invalidate gate entry conditions require regression.

Regression should be recorded as a gate regression event, not as an ordinary forward gate
transition.

## G0 -> G1: Project Initialized To Vision Ready Work

Required:

- `docs/project/project.yaml`;
- active project folder structure;
- human owner or temporary owner;
- required approver, if known;
- collaboration mode.

Review questions:

- Is this a new project or continuation?
- Is the project name and slug correct?
- Is the current mode appropriate?

Human approval: not required unless initialization overwrote existing state.

Next role: Product Vision Agent.

Next artifact: vision/problem framing document.

Stop if:

- project identity is unclear;
- active project folder is missing;
- manifest paths do not exist.

## G1 -> G2: Vision Ready To Requirements Ready Work

Required:

- accepted vision/problem framing document;
- gate approval log entry or queued approval record;
- target users;
- success criteria;
- non-goals;
- risks and open questions.

Review questions:

- Does the vision explain the problem rather than only a solution?
- Are target users clear?
- Are success criteria measurable, with target, read timing, owner, and evidence source?
- Are non-goals acceptable?
- Are open questions non-blocking for PRD drafting?

Human approval: required.

Next role: PRD Agent.

Next artifact: PRD.

Stop if:

- the human disagrees with users, outcomes, or non-goals;
- scope is too vague;
- unresolved questions could change requirements.

## G2 -> G3: Requirements Ready To Architecture Ready Work

Required:

- accepted PRD;
- gate approval log entry or queued approval record;
- stable requirement IDs;
- acceptance criteria;
- edge cases;
- deferred requirements;
- product-level security/governance requirements.

Review questions:

- Does every baseline requirement have acceptance criteria?
- Are requirements testable?
- Are deferred items documented with reasons?
- Are architecture-affecting open questions resolved?

Human approval: required.

Next role: Architecture Agent.

Next artifacts:

- architecture specification;
- technology stack decision record.

Stop if:

- baseline scope is too broad;
- acceptance criteria are unmeasurable;
- requirements imply unapproved external systems.

## G3 -> G4: Architecture Ready To Governance Ready Work

Required:

- accepted architecture specification;
- accepted or proposed technology stack decision;
- gate approval log entry or queued approval record;
- component ownership;
- runtime and data model;
- error and failure behavior;
- deferred architecture.

Review questions:

- Can implementation proceed without inventing core structure?
- Are data and lifecycle boundaries clear?
- Are external integrations identified?
- Are security-sensitive boundaries visible?

Human approval: required.

Next role: Security Governance Agent.

Next artifact: governance/security specification.

Stop if:

- stack decision is unresolved;
- architecture conflicts with PRD;
- trust boundaries are implicit.

## G4 -> G5: Governance Ready To Build Ready

Required:

- accepted governance/security specification;
- gate approval log entry or queued approval record;
- identity model;
- authorization rules;
- approval model;
- audit model;
- secrets and data sensitivity rules;
- security and negative test expectations.

Review questions:

- Does every actor have permitted and forbidden actions?
- Are authorization rules testable?
- Are audit and retention expectations explicit?
- Are agent/tool stop conditions documented or N/A?

Human approval: required.

Next role: Phase Planning Agent.

Next artifacts:

- phase plan (the ordered partition with the requirement coverage map and
  integration criteria).

The per-phase build plan, tactical plan, construction directive, and build
prompt are produced inside the phase loop at the interior G5.x checkpoints, not
as G5 exit artifacts. See docs/methodology/guides/phase-loop.md.

Stop if:

- authorization behavior is implicit;
- data sensitivity is unknown;
- security tests are missing for security requirements.

## G5 -> G6: Build Ready To Implementation Ready For Review

This transition spans the entire phase loop. G5 closes when the phase plan is
accepted (G5.0); the build then proceeds one phase at a time through the
interior G5.<id> checkpoints. G6 is entered only after every planned phase has
exited.

Required:

- every phase declared in the phase plan has a closed G5.<id>.4 (phase exit)
  event;
- the accumulated regression suite is green at the G6 candidate revision;
- the integration criteria declared in the phase plan are satisfied or carried
  as enumerated residuals;
- gate approval log entry or queued approval record;
- implementation completed within the scope of every exited phase;
- verification run or skipped with reason.

The per-phase build plan, tactical plan, construction directive, and build
prompt are produced and accepted inside the loop at the interior checkpoints;
they are not G5->G6 entry artifacts. See docs/methodology/guides/phase-loop.md.

Review questions:

- Did every phase stay within its directive?
- Were required tests added or updated, and did each phase's exit test pass?
- Is the accumulated regression suite green?
- Were verification commands run?
- Were skipped checks reported?
- Did implementation affect docs, examples, or traceability?

Human approval: required before construction begins, but not required merely to enter review unless
critical verification was skipped.

Next role: Code Review Agent.

Next artifact: code review report.

Stop if:

- implementation changed architecture/security scope;
- required verification failures are unresolved;
- deferred behavior was implemented.

## G6 -> G7: Implementation Ready For Review To Acceptance Ready

Required:

- code review report;
- remediation plan or summary, if findings exist;
- tests and UAT evidence;
- residual risk statement;
- updated traceability evidence;
- gate approval log entry or queued approval record.

Review questions:

- Are critical findings remediated?
- Are major findings remediated or explicitly accepted?
- Do tests prove acceptance criteria?
- Does traceability match actual evidence?
- Are known limitations documented?

Human approval: required for acceptance and for any accepted critical/major residual risk.

Next role: As-Built Close-Out Agent or Deployment Readiness Agent, depending on release path.

Next artifacts:

- as-built close-out;
- deployment readiness checklist if production release is in scope.

Stop if:

- findings lack remediation or acceptance;
- verified traceability lacks evidence;
- documentation still describes planned behavior as implemented.

## G7 -> G8: Acceptance Ready To Deployment Ready

Required:

- accepted implementation;
- as-built updates sufficient for release evaluation;
- deployment target;
- environment/config/secrets expectations;
- migration and rollback plan;
- operational checks;
- human release approver.

Review questions:

- What exactly is being released?
- What can fail in deployment?
- How is rollback performed?
- What monitoring confirms success?
- Who owns post-deployment response?

Human approval: required.

Next role: Deployment Readiness Agent.

Next artifacts:

- production runbook;
- release checklist;
- post-deployment validation plan;
- rollback decision procedure.

Stop if:

- rollback is undefined for risky changes;
- production credentials are requested in chat;
- monitoring or validation is missing;
- deployment target is not approved.

## G8 -> G9: Deployment Ready To As-Built Closed

Required:

- deployment or release decision;
- post-deployment validation results, if deployed;
- rollback status or confirmation not needed;
- production known limitations;
- final as-built close-out;
- traceability update.

Review questions:

- Did deployment occur?
- Did post-deployment checks pass?
- Were incidents, rollback, or follow-up items recorded?
- Can future agents understand the production state?

Human approval: required for phase close.

Next role: Product Vision Agent, Phase Planning Agent, or Deployment Readiness Agent, depending on
next work.

Next artifact: next phase plan or operational follow-up backlog.

Stop if:

- production status is unclear;
- runbook or known limitations are stale;
- traceability is not updated.

## Completion Standard

This protocol is working when a gate never advances merely because an agent says it is ready. Each
transition has source evidence, review questions, recorded approval where required, updated state,
and a clear next role.
