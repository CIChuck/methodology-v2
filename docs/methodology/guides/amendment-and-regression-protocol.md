# Amendment And Regression Protocol

Status: Reusable Standard
Authority: `docs/methodology/constitution/gendev.md`,
`docs/methodology/guides/artifact-collaboration-protocol.md`,
`docs/methodology/guides/gate-transition-protocol.md`

## Purpose

This guide defines how a project changes accepted authority after later work has already started.
It prevents two common failures:

- pretending an accepted artifact cannot change;
- allowing agents to use changed authority without reconciling downstream artifacts.

Amendment is the controlled way to change authority while the project remains at its current gate.
Regression is the controlled way to move the project back to an earlier gate when the change
invalidates gate entry conditions.

## Core Rule

Accepted authority may be amended, but not casually overwritten.

When an accepted artifact changes, the lead agent must classify the change, identify affected
downstream artifacts, mark stale authority where needed, record the decision, and ask for human
approval when the change is semantic.

Unamended stale authority is a methodology violation. It is not permission for an agent to infer new
scope, silently reinterpret architecture, or continue implementation from conflicting documents.

## Definitions

Amendment:

```text
A controlled change to an accepted artifact while the current project gate stays where it is.
```

Regression:

```text
A formal move back to an earlier gate because an amendment invalidates the entry conditions for the
current gate or one of the gates already passed.
```

Dirty subtree:

```text
amended artifact
  -> artifacts derived from it
     -> traceability rows citing it
        -> plans, tests, reviews, implementation evidence, deployment evidence, or close-out
```

Reconciliation:

```text
The review and update process that makes downstream artifacts consistent with amended authority.
```

## Amendment Classes

### Editorial Amendment

An editorial amendment changes wording, formatting, spelling, examples, or organization without
changing meaning.

Examples:

- typo correction;
- section reordering;
- clearer wording that does not alter requirements, scope, risk, or acceptance criteria;
- formatting a table without changing values.

Approval:

- no gate re-approval required;
- record the change if the artifact is already accepted and the edit may confuse future readers;
- no downstream artifact should become stale unless meaning changed.

### Additive-Within-Scope Amendment

An additive-within-scope amendment adds detail that clarifies already accepted authority without
changing boundaries.

Examples:

- adding an example to an accepted requirement;
- naming a test case that was already implied by an acceptance criterion;
- adding a non-blocking open question for a later gate;
- adding an implementation note that remains inside the accepted architecture.

Approval:

- lightweight human approval is required when the artifact is accepted;
- affected downstream artifacts should be reviewed;
- downstream artifacts may remain current if the review confirms no semantic impact.

### Structural Amendment

A structural amendment changes the meaning, boundary, risk, or acceptance standard of accepted
authority.

Examples:

- adding, removing, or changing baseline requirements;
- changing acceptance criteria;
- changing architecture ownership, runtime model, data model, or technology stack;
- changing identity, authorization, audit, data sensitivity, tool access, or approval behavior;
- changing phase scope, non-goals, migration behavior, rollback behavior, deployment risk, or
  production readiness criteria.

Approval:

- explicit human approval is required;
- downstream artifacts derived from the amended artifact must be reviewed;
- affected downstream artifacts should be marked `Stale` until reconciled;
- a gate transition must not cite stale downstream evidence.

## Amendment Decision Tree

When the human asks for a change to accepted authority, the lead agent should ask:

```text
1. Is the artifact accepted?
2. Does the requested change alter meaning?
3. Does it affect scope, security, architecture, acceptance criteria, phase boundaries, deployment,
   or operational risk?
4. Which downstream artifacts derive from this artifact?
5. Can the current gate still satisfy its entry conditions after the change?
6. Is amendment sufficient, or is gate regression required?
```

Default decisions:

```text
Editorial only                         -> record if useful; no re-approval.
Clarifies accepted intent              -> additive-within-scope amendment.
Changes boundary, behavior, or risk    -> structural amendment.
Invalidates passed gate entry criteria -> regression.
```

## When To Mark Stale

Mark a downstream artifact `Stale` when it derives from amended authority and the amendment may
change the artifact's meaning, completeness, or evidence value.

Common stale outcomes:

- PRD amended structurally -> architecture, governance/security, phase plans, tests, traceability,
  construction directives, review reports, and as-built records may be stale.
- Architecture amended structurally -> governance/security, phase plans, tactical plans,
  construction directives, tests, review reports, and as-built records may be stale.
- Governance/security amended structurally -> phase plans, tactical plans, construction
  directives, tests, deployment readiness, and production runbooks may be stale.
- Phase build plan amended structurally -> tactical plan, test/UAT plan, construction directive,
  implementation evidence, review report, and as-built close-out may be stale.

Do not mark an artifact stale merely because an upstream file changed editorially. The stale signal
should mean reconciliation is needed.

## When To Mark Superseded

Mark an artifact `Superseded` when a newer accepted artifact replaces it as authority.

Use `Superseded` for:

- abandoned alternative ADRs;
- replaced architecture documents;
- replaced phase plans;
- old construction directives after a new directive is accepted for the same scope.

Use `Stale`, not `Superseded`, when the artifact may still become current after reconciliation.

## Regression Criteria

Regression is reserved for amendments that invalidate gate entry conditions.

Regress when:

- the vision change invalidates accepted PRD direction;
- the PRD change invalidates architecture or testability;
- the architecture change invalidates governance/security or build planning;
- the governance/security change invalidates build authorization;
- the phase plan change invalidates implementation authorization;
- the amendment makes current implementation evidence no longer conformant;
- the team cannot determine the dirty subtree without returning to an earlier gate.

Do not regress for:

- editorial amendments;
- clarifications that do not change boundaries;
- downstream updates that can be handled with targeted reconciliation while the current gate holds.

## Lead Agent Procedure

When a requested change may amend accepted authority:

1. Stop ordinary forward motion.
2. Identify the current gate from `docs/project/project.yaml`.
3. Identify the accepted artifact being amended.
4. Classify the amendment as editorial, additive-within-scope, or structural.
5. Estimate the dirty subtree.
6. Recommend amendment or regression.
7. Ask for the required human approval.
8. Apply the artifact update only after approval when approval is required.
9. Mark affected downstream artifacts `Stale`, `Superseded`, or reviewed-no-change.
10. Record the amendment in `docs/project/approvals/gate-log.md`.
11. Update `docs/project/project.yaml` amendment state.
12. Resume the current gate only after blockers are visible.

## Human Approval Prompt

Use this shape before applying a semantic amendment:

```text
Amendment:
Current gate:
Artifact to amend:
Current artifact revision:
Proposed amendment class:
Reason:
Semantic impact:
Downstream artifacts requiring reconciliation:
Recommended action:
Regression required:
Risks accepted:
Manifest updates:
```

The human may approve in plain language, but the agent must convert the approval into a durable
record.

## Amendment Event

Use this shape in `docs/project/approvals/gate-log.md`:

````markdown
## Amendment Event: AMD-YYYYMMDD-001

```yaml
event_type: amendment
amendment_id: AMD-YYYYMMDD-001
class: editorial | additive_within_scope | structural
current_gate: G6
artifact:
  path: docs/project/prd/prd.md
  previous_revision: TBD
  new_revision: TBD
decision: approved
decided_by: TBD
decided_on: YYYY-MM-DD
reason: TBD
semantic_change: true
downstream_reconciliation:
  - path: docs/project/architecture/architecture.md
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

## Regression Event

Use this shape when the project gate formally moves backward:

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
  - path: docs/project/architecture/architecture.md
    reason: TBD
required_reconciliation:
  - path: docs/project/architecture/architecture.md
    owner: TBD
    due_gate: G3
manifest_updated: true
```
````

## Reconciliation Event

Use this shape when stale downstream artifacts are reviewed and resolved:

````markdown
## Reconciliation Event: AMD-YYYYMMDD-001

```yaml
event_type: reconciliation
amendment_id: AMD-YYYYMMDD-001
reconciled_by: TBD
reconciled_on: YYYY-MM-DD
artifacts:
  - path: docs/project/architecture/architecture.md
    previous_status: Stale
    outcome: updated | reviewed_no_change | superseded
    new_revision: TBD
remaining_stale_artifacts:
  - N/A
gate_movement_unblocked: true
manifest_updated: true
```
````

## Manifest Summary

`docs/project/project.yaml` should summarize active amendment state. The gate log remains the
durable history.

Recommended shape:

```yaml
amendments:
  active_count: 0
  record: docs/project/approvals/gate-log.md
  protocol: docs/methodology/guides/amendment-and-regression-protocol.md
  active:
    - id: TBD
      class: structural
      artifact: docs/project/prd/prd.md
      status: pending_reconciliation
      opened_on: TBD
      owner: TBD
      regression_required: false
      downstream_stale:
        - docs/project/architecture/architecture.md
```

Use `active_count: 0` and an empty active list when no amendment is open.

## Practical Example

Scenario: the project is at G6. Implementation uncovered a missing requirement in the accepted PRD.

Do not:

```text
Silently add the requirement, keep building, and leave architecture and tests unchanged.
```

Do:

```text
1. Stop implementation.
2. Classify the PRD change.
3. If it changes baseline scope or acceptance criteria, classify it as structural.
4. Record an amendment event.
5. Mark affected architecture, phase plan, test/UAT plan, construction directive, and traceability
   rows Stale or reviewed-no-change.
6. Decide whether G6 can hold or must regress.
7. Reconcile stale artifacts before using them as gate evidence.
```

If the new requirement fits existing architecture and phase boundaries, the project can often remain
at G6 while affected artifacts are reconciled. If it requires new architecture or invalidates build
authorization, regress to G3 or G5 as appropriate.

## Completion Standard

This protocol is working when accepted authority can change without losing control. The project can
adapt, but every semantic change has a class, approver, dirty-subtree assessment, reconciliation
plan, and durable record.
