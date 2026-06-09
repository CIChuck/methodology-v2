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
- `project.yaml` should summarize current approval state.
- Chat approval should be copied into durable project docs when it affects scope, risk, or gate
  movement.
- Approval of one artifact does not approve unrelated future work.
- Accepted risk must be visible.

## Standard Approval Record

Use this shape:

```text
Decision:
Approved by:
Date:
Scope approved:
Known risks accepted:
Conditions:
Next gate:
```

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

Recommended record:

```markdown
## Gate Approval

Gate transition:
Decision:
Approved by:
Date:
Evidence reviewed:
Known risks accepted:
Next role:
Next artifact:
```

Gate approval may be recorded in a gate log if the active project creates one. If not, it may be
recorded in the approved artifact.

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
    approved_by: TBD
    approved_on: TBD
    evidence: TBD
  latest_decision:
    decision: TBD
    approved_by: TBD
    approved_on: TBD
```

The manifest summarizes state. The detailed record belongs in Markdown artifacts.

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
