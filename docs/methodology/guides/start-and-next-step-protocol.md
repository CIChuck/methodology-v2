# Start And Next-Step Protocol

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines how the lead agent responds to short operational prompts such as:

```text
Let's begin.
What's next?
Continue.
Proceed.
Pause.
Resume.
Change mode.
```

The goal is to make agent behavior predictable without requiring the human to restate the whole
methodology.

## Universal Orientation

Before recommending a next action, the agent checks:

```text
1. Current branch/workspace status, if relevant.
2. AGENTS.md.
3. docs/project/project.yaml.
4. Current gate.
5. Current collaboration mode.
6. Current active artifact.
7. Current approval state and approval log.
8. Blocking missing authority.
```

If `docs/project/` does not exist, the next action is initialization.

## "Let's Begin"

Use when starting a new product instance or a new session.

Agent response:

```text
1. Confirm whether docs/project exists.
2. If missing, recommend running ./scripts/init-project.sh "Project Name".
3. If initialized, read project.yaml and identify current gate.
4. Ask for or confirm collaboration mode.
5. Ask for or confirm project owner and gate approver before any approval boundary.
6. Recommend the first actionable step.
```

If no project name exists, ask for it.

If the project is initialized at G1, begin the vision loop.

First-run preflight should capture:

```text
Project owner:
Gate approver:
Deployment approver, if known:
Collaboration mode:
Sub-agents allowed:
Initial product/project objective:
```

The agent may draft G1 while some authority fields are unknown. It should not mark G1
`ready_for_approval` until the owner, required approver, evidence path, open-question status, and
risk disposition are known.

## "What's Next?"

Use when the human wants the methodology-driven next step.

Agent response:

```text
Current gate:
Current mode:
Current artifact:
Readiness:
Approval state:
Recommended next step:
Human decision needed:
```

The agent should not skip forward. It recommends the next gate-aware step.

Examples:

- If vision is missing, recommend drafting the vision document.
- If vision is accepted, recommend PRD drafting.
- If PRD is accepted, recommend architecture and stack decision.
- If implementation is complete, recommend conformance review.
- If review is complete, recommend remediation or acceptance.

## "Continue"

Use when the human wants to keep working within the current approved step.

Agent response:

```text
1. Resume the current loop.
2. State what artifact or section is being continued.
3. Identify any assumptions.
4. Continue until the next natural review point or stop condition.
```

The agent may proceed within the current artifact if the collaboration mode permits it.

## "Proceed"

Use when the human approves the immediate proposed action.

Agent response:

```text
1. Confirm what "proceed" applies to.
2. Check whether formal approval is required.
3. If approval is sufficient, execute the next procedural step.
4. If approval must be recorded, ask for or record the approval.
```

"Proceed" does not bypass gate approvals, security approvals, or production approvals.
It also does not approve semantic amendments to accepted authority unless the amendment, class,
downstream reconciliation, and regression decision are clear enough to record.

If `Proceed` could mean gate approval, the agent should restate the approval record before acting:

```text
I understand this as approval for:
Gate:
Evidence:
Known risks accepted:
Next gate:
Next role:
Record locations:
```

If any field is unknown, ask for the missing field instead of advancing.

If `Proceed` could mean approval for an amendment, the agent should restate the amendment record
before acting:

```text
I understand this as approval for:
Amendment:
Current gate:
Artifact:
Class:
Downstream reconciliation:
Regression required:
Record locations:
```

If any field is unknown, ask for the missing field instead of editing accepted authority.

## "Pause"

Use when the human wants work to stop.

Agent response:

```text
1. Stop active work.
2. Summarize current state.
3. Identify pending decisions.
4. State the resume point.
```

No new artifact changes should be made after pause unless the human explicitly asks for a status
record.

## "Resume"

Use when returning after a pause or context shift.

Agent response:

```text
1. Re-orient from project.yaml and current docs.
2. State previous resume point if known.
3. Identify drift or missing context.
4. Recommend the next action.
```

If the resume point is unclear, the agent asks a concise clarification rather than guessing across a
gate boundary.

## "Change Mode"

Use when the human wants to change collaboration style.

Agent response:

```text
Mode set to:
Scope of mode:
What changes:
What still requires approval:
```

Mode changes should be reflected in `docs/project/project.yaml` when the human wants persistent
state.

## Premature Implementation Guard

The agent must not move to code implementation unless:

- current gate is build-ready or later;
- construction directive exists and is accepted;
- required tests and verification are defined;
- security/governance implications are resolved or explicitly marked N/A;
- collaboration mode permits execution.

If these are missing, the next step is planning, not implementation.

## Next-Step Recommendation Format

Use this concise format:

```text
Current gate:
Current state:
Recommended next step:
Why:
Human input needed:
Agent role:
```

## Completion Standard

This protocol is working when short human prompts produce predictable, gate-aware, mode-aware
responses that move the project forward without bypassing approval or authority.
