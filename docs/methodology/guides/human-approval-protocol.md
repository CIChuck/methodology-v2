# Human Approval Protocol

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines lightweight human approval records for methodology gates, major artifacts,
review findings, deployment, rollback, and risk acceptance.

Approval records must be easy to create and review. They do not need a heavy signature workflow at
this stage. They must be explicit enough that a future agent can see what was approved, by whom, and
under what scope.

## Approval Principles

- Approval is a human control point.
- Approval should be recorded in Markdown.
- Standard gate approvals should include a structured event block that can be checked by tooling.
- `project.yaml` should summarize current approval state.
- `docs/project/approvals/gate-log.md` should preserve gate approval history.
- Chat approval should be copied into durable project docs when it affects scope, risk, or gate
  movement.
- Gate evidence should identify artifact path, revision, and status.
- Approval of one artifact does not approve unrelated future work.
- Accepted risk must be visible.
- Approval is meaningful only when the approver can explain the artifact, identify its principal
  risks, and could credibly stop the work.

## Approval State Values

Use these values for gate approval state in `docs/project/project.yaml`:

```text
pending
drafting
ready_for_review
ready_for_approval
approved
blocked
superseded
```

Use these values for major artifact status when applicable:

```text
Draft
Ready for Review
Ready for Approval
Accepted
Stale
Superseded
```

`Stale` means an upstream authority changed after the artifact pinned that authority. A stale
artifact requires reconciliation review before it can be used as gate evidence.

Reports and close-out artifacts may use `Complete` instead of `Accepted` when they record evidence
rather than define planning authority.

## Standard Approval Record

Use this shape:

```text
Decision:
Approved by:
Date:
Scope approved:
Evidence reviewed:
Criterion IDs:
Checked:
Known risks accepted:
Conditions:
Next gate:
```

`Checked` is one substantive statement, in the approver's own words, naming something they actually
verified. It is not a restatement of "looks good."

If a section is not applicable, write `N/A` with a short reason.

## Minimal Approval Record

For low-risk draft movement:

```text
Decision:
Approved by:
Date:
Next step:
```

The minimal form is not sufficient for deployment, destructive migration, security exceptions, or
accepting critical/major findings.

## Required Approval Points

Human approval is required for:

- vision acceptance;
- PRD acceptance;
- technology stack acceptance;
- architecture acceptance;
- governance/security acceptance;
- phase scope acceptance;
- tactical implementation plan acceptance;
- construction directive acceptance;
- accepting critical or major review findings without remediation;
- destructive migration;
- new external integration;
- production deployment;
- rollback decision;
- phase close-out.

## Artifact Approval

Artifact approval means the human accepts that document as current authority for its scope.

Recommended section:

```markdown
## Approval

Decision:
Approved by:
Date:
Scope approved:
Known risks accepted:
Conditions:
Next gate:
```

Approval should be near the top or bottom of the artifact, depending on local document convention.

## Gate Approval

Gate approval means the project may move from one gate to the next.

Standard gate approval records should use a structured YAML block inside
`docs/project/approvals/gate-log.md`. Human-readable notes may follow the block.

Recommended record:

````markdown
## Gate Event: G1 -> G2

```yaml
event_type: gate_transition
from_gate: G1
to_gate: G2
decision: approved
decided_by: TBD
criterion_ids:
  - G1-REQ-ID
  - G1-AC-COVERAGE
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

Gate approval should be recorded in `docs/project/approvals/gate-log.md`. It may also be recorded
in the approved artifact. `project.yaml` must summarize the latest gate state.

Before asking for gate approval, the lead agent should present:

```text
Gate:
Artifact status:
Evidence reviewed:
Enforcement class:
Blast-radius class:
Combined gate justification, if applicable:
Criterion IDs:
Gate started on:
Ready for approval on:
Approval requested on:
Open questions:
Known risks:
Risks requiring acceptance:
Proposed next gate:
Proposed next role:
Manifest updates to record:
```

The agent should not interpret a casual `proceed` as gate approval unless the gate, approver,
evidence path, evidence revision, evidence status, and risk disposition are unambiguous and can be
recorded.

Legacy prose approval records are acceptable during migration, but new gate approvals should use the
structured event shape. Structured records make gate movement, approval sampling, enforcement
attestation, and future metrics computable from the project record.

The timing fields support basic process telemetry. `gate_started_on` is when meaningful work began
for the gate, `ready_for_approval_on` is when the agent or team believed the gate had enough
evidence for approval, `approval_requested_on` is when the human was actually asked to decide, and
`decided_on` is when the approval or rejection occurred.

## Evidence Sampling

At least once per implementation phase, before phase close-out approval, the approver should sample
one traceability row and verify it end to end.

The sampled row should be recorded in the gate log:

```text
requirement -> architecture rule or decision -> build item -> implementation reference -> test/UAT evidence -> review confirmation
```

Record:

```text
Sampled traceability row:
Sampled by:
Sampled on:
Result:
Discrepancy:
Disposition:
```

A discrepancy in a sampled row blocks phase close-out until it is explained, remediated, or
explicitly accepted as risk by the human approver.

## Review Finding Acceptance

If a critical or major finding will not be remediated before acceptance, record:

```text
Finding ID:
Severity:
Decision:
Approved by:
Date:
Risk accepted:
Reason:
Follow-up:
```

The lead agent should challenge unclear risk acceptance and ask the human to make the risk explicit.

## Deployment Approval

Production deployment requires:

```text
Release scope:
Deployment target:
Approved by:
Date:
Rollback plan reviewed:
Monitoring plan reviewed:
Known risks accepted:
Post-deployment owner:
```

Deployment approval must not be inferred from acceptance-ready status.

## Rollback Approval

Rollback approval requires:

```text
Rollback trigger:
Impact:
Approved by:
Date:
Rollback steps:
Validation after rollback:
Owner:
```

Emergency procedures may allow faster action, but the action must be recorded afterward.

## Manifest Summary

Recommended `docs/project/project.yaml` fields:

```yaml
approvals:
  current_gate:
    gate: G1
    status: pending
    required_approver: TBD
    criterion_ids:
      - G1-REQ-ID
      - G1-AC-COVERAGE
    approved_by: TBD
    approved_on: TBD
    evidence:
      - docs/project/vision/vision.md
    risks_accepted:
      - TBD
    blocking_open_questions:
      - TBD
    next_gate: G2
    next_role: prd-agent
    next_artifact: docs/project/prd/prd.md
  latest_decision:
    decision: TBD
    criterion_ids:
      - G1-REQ-ID
      - G1-AC-COVERAGE
    decided_by: TBD
    decided_on: TBD
    record: docs/project/approvals/gate-log.md
```

The manifest summarizes state. The detailed record belongs in Markdown artifacts.

Rules:

- Do not set gate status to `ready_for_approval` while required approver, evidence, or risk
  disposition is unknown.
- Do not set gate status to `approved` unless `approved_by`, `approved_on`, evidence, and risk
  disposition are recorded.
- Use `N/A` with a short reason when there are no risks to accept or no open questions to carry
  forward.
- Keep `next_gate`, `next_role`, and `next_artifact` current so a future agent can resume.

## Approval Language In Conversation

The human may approve in natural language:

```text
Approved. Move from G1 to G2.
I approve this PRD with the noted risks.
Approve Phase 1 scope, but keep integrations deferred.
```

The agent should convert material approvals into a durable record and ask for missing fields if
needed.

## Stop Conditions

The agent must stop if:

- approval is ambiguous;
- approver identity is unknown;
- scope approved is broader than the artifact;
- known risks are material but not acknowledged;
- approval conflicts with governance/security rules;
- production approval is implied but not explicit.

## Completion Standard

This protocol is working when human approval is lightweight, durable, and visible to future agents
without becoming a heavy process bottleneck.
