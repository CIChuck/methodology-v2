# 07. Approvals And Risk

## Purpose

This chapter explains how approval (a human decision that work may move forward) and risk
acceptance (a human decision to carry a known risk forward) work in practice.

## Why Approval Must Be Explicit

AI agents can infer too much from casual language. In ordinary conversation, `proceed` may mean
"continue drafting." At a gate boundary (a point where moving forward requires approval), it may
sound like "approve the artifact (durable project document or record) and move on." In GenDev, the
agent must disambiguate (separate the possible meanings and ask for the missing decision).

The rule is:

```text
Approval must be explicit enough that a future agent can see who approved what, when, based on what
evidence, and with what risks accepted.
```

## Approval Records

Approval is recorded in three places when applicable:

1. The approved artifact.
2. `docs/project/approvals/gate-log.md`.
3. `docs/project/project.yaml`.

The artifact holds the content. The gate log (the durable approval history) holds the historical
approval record. The manifest (the compact `project.yaml` project-state summary) summarizes the
current state.

## What Requires Human Approval

Human approval is required for:

- vision acceptance;
- PRD acceptance;
- semantic amendments to accepted authority;
- gate regression decisions;
- technology stack acceptance (approval of the main languages, frameworks, services, and storage
  choices);
- architecture acceptance;
- governance/security acceptance;
- phase scope acceptance;
- tactical implementation plan acceptance;
- construction directive acceptance;
- accepting critical or major review findings without remediation (fixing the finding);
- destructive migration (a data or schema change that can lose data or be hard to reverse);
- new external integration (a dependency on a service, API, system, or vendor outside the product);
- production deployment (release to an operating environment);
- rollback decision (decision to return to a previous known-good state);
- phase close-out.

The agent may draft, analyze, and recommend. The human approves.

## Approval Prompt Shape

Before asking for gate approval (approval to move from one GenDev gate to the next), the agent
should present:

```text
Gate:
Artifact status:
Evidence reviewed:
Evidence revisions:
Enforcement class:
Attestation or enforcement evidence:
Open questions:
Known risks:
Risks requiring acceptance:
Checked:
Proposed next gate:
Proposed next role:
Manifest updates to record:
```

This prompt should be specific. It should not ask:

```text
Do you approve?
```

without context.

## Amendment Approval

Before asking for amendment approval, the agent should present:

```text
Amendment:
Current gate:
Artifact to amend:
Current artifact revision:
Proposed amendment class:
Reason:
Semantic impact:
Downstream artifacts requiring reconciliation:
Regression required:
Risks accepted:
Manifest updates to record:
```

Editorial amendments do not normally require approval. Additive-within-scope amendments require
lightweight approval when the artifact is already accepted. Structural amendments require explicit
approval and downstream reconciliation before stale artifacts can support a gate transition.

## Good Approval Language

Good human approval:

```text
I approve G1 -> G2 based on the current vision document. I accept the risk that integration needs
may appear during PRD discovery, and I want that tracked as an open PRD question. Move to PRD Agent
next.
```

Good agent record:

````markdown
## Gate Event: G1 -> G2

```yaml
event_type: gate_transition
from_gate: G1
to_gate: G2
decision: approved
decided_by: Chuck
decided_on: 2026-06-09
enforcement_class: attested
artifact_status: Accepted
evidence:
  - path: docs/project/vision/vendor-contract-tracker-vision.md
    revision: TBD
    status: Accepted
checked: "Confirmed that the vision keeps integrations deferred and names integration scope as a PRD question."
known_risks_accepted:
  - risk: Integration needs may emerge during PRD discovery.
    rationale: Acceptable for G1 because integrations remain deferred unless explicitly approved.
open_questions_carried_forward:
  - question: Exact integration scope.
    owner: Chuck
    target_gate: G2
conditions:
  - PRD must keep integrations deferred unless explicitly approved.
next_role: prd-agent
next_artifact: docs/project/prd/vendor-contract-tracker-prd.md
manifest_updated: true
```
````

`Checked` is the key difference between a ceremonial approval and a useful approval. It forces one
plain statement of what the approver actually verified.

`revision` records the specific version of the artifact that was reviewed. Use `TBD` only while the
artifact is still draft or has not yet been committed. `status` records whether the evidence was
`Ready for Approval`, `Accepted`, `Complete`, `Stale`, or `Superseded` at the time of approval.
Stale or superseded evidence should trigger reconciliation before the gate advances.

`enforcement_class` records whether the project relied on `attested` controls (named humans confirm
the required methodology checks on the configured cadence) or `enforced` controls (a mechanical
binding, such as a hook or CI policy, blocks nonconforming changes). At baseline, GenDev projects
usually start as `attested`. A gate approval should still identify what was attested or what
mechanical evidence was reviewed.

## Weak Approval Language

Weak approval:

```text
Looks good.
```

The agent should ask:

```text
Should I record this as approval for G1 -> G2? If yes, please confirm the approver and any known
risks accepted or state N/A. Also provide one checked statement naming something you verified.
```

Weak approval:

```text
Proceed.
```

The agent should interpret this only in context. If the previous agent message proposed a gate
approval, the agent should restate the approval record before acting.

## Risk Acceptance

Risk acceptance means the human understands a material risk (a risk significant enough to affect
scope, quality, security, schedule, operations, or production) and permits the project to continue.
It does not mean the risk is solved.

Examples:

- "We accept that integrations are deferred, even if some users ask for them."
- "We accept manual deployment for the first internal pilot."
- "We accept that renewal calculations will be simple until legal language is better defined."

Risk acceptance should include:

- the risk;
- the reason it is acceptable now;
- any condition or follow-up;
- where it will be tracked.

## Open Questions

Not every open question (an unresolved decision or unknown) blocks progress. The agent and human
should distinguish:

- blocking questions (questions that must be answered before the gate advances);
- non-blocking questions (questions that can carry forward without invalidating the approval);
- future questions that belong in a later phase.

Before approval, the agent should list carried-forward questions (questions intentionally moved into
a later gate or phase) explicitly.

## Evidence Sampling

At least once per implementation phase, before phase close-out, the approver should sample one
traceability row (one requirement-to-evidence mapping) and verify it end to end.

The sampling question is:

```text
Can I follow this requirement from the PRD, through architecture and planning, into implementation,
test/UAT evidence, review confirmation, and close-out?
```

If the sampled row does not hold together, the phase should not close until the discrepancy is
explained, remediated, or explicitly accepted as risk.

## Manifest Rules

Do not set `approvals.current_gate.status` to `ready_for_approval` while required approver,
evidence (proof supporting the readiness claim), or risk disposition (what will happen to known
risks) is unknown.

Do not set it to `approved` unless:

- `approved_by` is set;
- `approved_on` is set;
- evidence is listed;
- evidence revisions and statuses are recorded where practical;
- enforcement class and required attestation or enforcement evidence are visible;
- risk disposition is recorded;
- the next gate, role, and artifact are known.

Use `N/A` with a reason when there are no risks or no open questions.

## Practitioner Checklist

Before approving a gate, confirm:

```text
[ ] I know what artifact I am approving.
[ ] I know which artifact revision I reviewed.
[ ] I confirmed required evidence is not stale or superseded.
[ ] I know the enforcement class for this gate.
[ ] I know what attestation or enforcement evidence supports this gate.
[ ] I know whether active amendments affect this gate.
[ ] I know which gate is advancing.
[ ] I understand unresolved questions.
[ ] I understand known risks.
[ ] I can state one specific thing I checked.
[ ] I know what role and artifact come next.
[ ] I expect the agent to record this in gate-log.md and project.yaml.
```
