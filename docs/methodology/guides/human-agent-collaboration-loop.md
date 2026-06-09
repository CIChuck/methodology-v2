# Human-Agent Collaboration Loop

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines the repeated collaboration loop between a human team member and a lead AI agent.
It is the procedural bridge between a simple prompt such as `Let's begin` and a completed,
production-ready project.

The loop is:

```text
orient -> ask -> draft -> review -> revise -> approve -> record -> next step
```

The loop repeats for every major artifact, gate, implementation phase, review, remediation, and
production operation.

## Roles

| Role | Responsibility |
| --- | --- |
| Human team member | Owns goals, scope approval, business decisions, risk acceptance, and production approval. |
| Lead agent | Orchestrates the methodology, drafts artifacts, coordinates sub-agents, synthesizes recommendations, and keeps state visible. |
| Sub-agents | Provide bounded advisory or review outputs under lead-agent coordination. |

Sub-agent output is advisory until accepted into active project documents or approval records.

## Step 1: Orient

The lead agent begins by inspecting available authority.

Required orientation sources:

```text
AGENTS.md
docs/project/project.yaml
docs/methodology/constitution/gendev.md
docs/methodology/guides/gates.md
current active project artifact for the gate
```

If `docs/project/` does not exist, the next step is initialization.

The lead agent should report:

```text
Current project:
Current gate:
Current collaboration mode:
Current active artifact:
Known blockers:
Recommended next action:
```

## Step 2: Ask

The agent asks only questions that materially affect the next artifact or gate.

Good questions affect:

- product scope;
- target users;
- acceptance criteria;
- technology stack;
- architecture boundaries;
- data sensitivity;
- permissions and approvals;
- phase boundaries;
- deployment risk.

Avoid asking questions that the agent can answer from local authority documents.

If assumptions are necessary, the agent labels them:

```text
Assumption:
Impact if wrong:
How to verify:
```

## Step 3: Draft

The agent drafts the next artifact or artifact section using the relevant template and role playbook.

Drafts should:

- cite source authority;
- separate facts from assumptions;
- name open questions;
- include non-goals;
- include testability implications;
- avoid overbuilding beyond the current gate.

For larger artifacts, the agent may propose a structure first, then draft section by section.

## Step 4: Review

The human reviews the draft for correctness, intent, and risk.

The lead agent should provide a review frame:

```text
Please review for:
- scope accuracy
- missing users or workflows
- unacceptable assumptions
- security or compliance concerns
- acceptance criteria that do not match your intent
```

For complex artifacts, the lead agent may coordinate sub-agent reviews. The lead agent must surface
conflicts and not hide dissenting findings in a summary.

## Step 5: Revise

The agent revises the artifact based on human feedback and any accepted sub-agent findings.

Revision rules:

- do not silently discard prior human decisions;
- keep a short update summary for material changes;
- update related docs if a change affects scope, architecture, governance, or tests;
- ask before broadening scope.

## Step 6: Approve

At approval points, the agent asks for explicit human approval.

Recommended approval record:

```text
Decision:
Approved by:
Date:
Scope approved:
Known risks accepted:
Next gate:
```

Approval may be recorded in the artifact, gate log, or another active project document. The manifest
should carry a summary state.

## Step 7: Record

After approval or major decision, the lead agent records state.

Record updates may include:

- artifact status;
- `docs/project/project.yaml` gate and approval summary;
- traceability matrix;
- decision record;
- deferred item list;
- known limitations;
- next artifact path.

The record step prevents decisions from living only in chat.

## Step 8: Next Step

Every loop ends with a concrete next recommendation.

Recommended response shape:

```text
Current status:
Next recommended step:
Why this is next:
Required human input:
Agent role to use:
Stop conditions:
```

The agent should not say only "what do you want to do next?" when the methodology provides an
obvious next step. It should recommend the next step and ask for confirmation if the current mode
requires it.

## Collaboration Loop By Gate

| Gate | Loop Output |
| --- | --- |
| G1 Vision Ready | Accepted vision document. |
| G2 Requirements Ready | Accepted PRD with testable requirements. |
| G3 Architecture Ready | Accepted architecture and stack decision. |
| G4 Governance Ready | Accepted governance/security specification. |
| G5 Build Ready | Accepted phase plan, tactical plan, test/UAT plan, and construction directive. |
| G6 Implementation Ready For Review | Implementation summary and verification evidence. |
| G7 Acceptance Ready | Review/remediation evidence and acceptance decision. |
| G8 Deployment Ready | Deployment approval, runbook, rollback, and operational checks. |
| G9 As-Built Closed | As-built close-out and updated traceability. |

## Stop Conditions

The lead agent must stop when:

- active project authority is missing;
- current gate cannot be identified;
- human approval is required;
- requested work conflicts with non-goals;
- requested work changes architecture or governance without approval;
- sub-agent findings materially conflict;
- production action, destructive migration, or rollback decision is needed.

## Completion Standard

The loop is working when the human can start with a simple prompt, the lead agent can identify the
current gate, ask only material questions, draft the right artifact, record approval, and recommend
the next step without relying on hidden assumptions.
