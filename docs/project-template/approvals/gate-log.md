# Gate Approval Log: [Project Name]

Status: Active
Date: [YYYY-MM-DD]
Owner: TBD
Authority: `docs/methodology/guides/human-approval-protocol.md`

## Purpose

This log records durable human approvals for methodology gate transitions, material risk
acceptance, and major scope decisions. `docs/project/project.yaml` summarizes the current state;
this file preserves the decision history.

## Record Format

Gate records use structured YAML blocks inside Markdown sections. The structured block is the
machine-readable record. Human-readable notes may follow the block.

Legacy prose records may exist in migrated projects, but new gate records should use the structured
form.

## Gate Transition Template

Copy this shape for each material gate transition.

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
artifact_status: Accepted
evidence:
  - path: docs/project/vision/[project-slug]-vision.md
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
next_artifact: docs/project/prd/[project-slug]-prd.md
manifest_updated: true
```
````

## Traceability Sampling Template

Use this shape when an approver samples a traceability row before phase close-out.

````markdown
## Traceability Sample

```yaml
event_type: traceability_sample
gate: G9
phase: 1
sampled_by: TBD
sampled_on: YYYY-MM-DD
requirement_id: TBD
traceability_row: TBD
result: passed
discrepancy: N/A
discrepancy_disposition: N/A
```
````

## Amendment Event Template

Use this shape when accepted authority changes while the current project gate stays in place.

````markdown
## Amendment Event: AMD-YYYYMMDD-001

```yaml
event_type: amendment
amendment_id: AMD-YYYYMMDD-001
class: editorial | additive_within_scope | structural
current_gate: G6
artifact:
  path: docs/project/prd/[project-slug]-prd.md
  previous_revision: TBD
  new_revision: TBD
decision: approved
decided_by: TBD
decided_on: YYYY-MM-DD
reason: TBD
semantic_change: true
downstream_reconciliation:
  - path: docs/project/architecture/[project-slug]-architecture.md
    action: mark_stale | reviewed_no_change | update_required | supersede
    owner: TBD
    due_gate: G6
regression_required: false
target_gate_if_regressed: N/A
risks_accepted:
  - risk: TBD
    rationale: TBD
manifest_updated: true
```
````

## Regression Event Template

Use this shape when an amendment invalidates gate entry conditions and the project formally moves
back to an earlier gate.

````markdown
## Regression Event: G6 -> G3

```yaml
event_type: gate_regression
from_gate: G6
to_gate: G3
reason: TBD
triggering_amendment: AMD-YYYYMMDD-001
decided_by: TBD
decided_on: YYYY-MM-DD
invalidated_gate_entry_conditions:
  - TBD
stale_artifacts:
  - path: docs/project/architecture/[project-slug]-architecture.md
    reason: TBD
required_reconciliation:
  - path: docs/project/architecture/[project-slug]-architecture.md
    owner: TBD
    due_gate: G3
manifest_updated: true
```
````

## Reconciliation Event Template

Use this shape when stale downstream artifacts are reviewed and resolved.

````markdown
## Reconciliation Event: AMD-YYYYMMDD-001

```yaml
event_type: reconciliation
amendment_id: AMD-YYYYMMDD-001
reconciled_by: TBD
reconciled_on: YYYY-MM-DD
artifacts:
  - path: docs/project/architecture/[project-slug]-architecture.md
    previous_status: Stale
    outcome: updated | reviewed_no_change | superseded
    new_revision: TBD
remaining_stale_artifacts:
  - N/A
gate_movement_unblocked: true
manifest_updated: true
```
````

## Enforcement Attestation Template

Use this shape when a project runs one or more enforcement requirements in attested mode.

````markdown
## Enforcement Attestation

```yaml
event_type: enforcement_attestation
gate: G5
attested_by: TBD
attested_on: YYYY-MM-DD
requirements_checked:
  - EC-1
  - EC-2
result: passed
exceptions:
  - requirement: EC-6
    reason: "Task IDs not yet adopted for this phase."
```
````

## Enforcement Override Template

Use this shape when an emergency requires bypassing an enforcement requirement.

````markdown
## Enforcement Override

```yaml
event_type: enforcement_override
gate: G8
approved_by: TBD
approved_on: YYYY-MM-DD
requirements_bypassed:
  - EC-3
reason: TBD
incident_or_emergency: TBD
normal_enforcement_resumed_on: TBD
reconciliation_required: true
```
````

## Gate Records

No gate approvals recorded yet.
