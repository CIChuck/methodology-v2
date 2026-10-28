# 05. Working With The Agent

## Purpose

This chapter explains the practical interaction pattern between the human team member (the person
who owns product intent and approval) and the lead agent (the AI agent coordinating the GenDev
process).

## Use Short Prompts Deliberately

GenDev supports short operational prompts (brief commands such as "Proceed" or "What's next?")
because the methodology gives the agent a process to follow.

Common prompts:

```text
Let's begin.
What's next?
Continue.
Proceed.
Pause.
Resume.
Switch to advisory mode.
Lead proactively.
```

The agent should interpret those prompts through
`docs/methodology/guides/start-and-next-step-protocol.md`, not as generic permission to do anything.

For GenDev 1.0 work, the agent should begin by running:

```bash
./scripts/gendev-doctor.sh
```

If the project is initialized, it should also run:

```bash
./scripts/project-state.sh
```

The agent should summarize the reported current gate, next artifact, required approver, and
recommended validation before making changes. If the project is not initialized, `gendev-doctor.sh`
reports the initialization command.

## "What's Next?"

Use `What's next?` when you want the agent to orient from current project state (the manifest,
approval log, active artifact, and relevant project files) and recommend the next
methodology-aware action (the next action that follows GenDev rather than generic coding instinct).

When a required late-lifecycle artifact is missing, ask the agent to create it through the canonical
artifact generator instead of inventing a path:

```bash
./scripts/new-artifact.sh --kind final-code-review
./scripts/new-artifact.sh --kind deployment-readiness
./scripts/new-artifact.sh --kind project-as-built
```

Generated artifacts still require normal review, evidence, and approval; the generator only prevents
path and template drift.

Expected response shape:

```text
Current gate:
Current mode:
Blast-radius class:
Enforcement class:
Current artifact:
Readiness:
Approval state:
Active amendments or stale evidence:
Recommended next step:
Human decision needed:
```

If the agent gives only a vague answer, ask it to re-orient:

```text
Re-read docs/project/project.yaml and answer using the GenDev next-step format.
```

## "Proceed"

`Proceed` means "continue with the immediate proposed action." It does not automatically approve a
gate (lifecycle checkpoint), accept risk (permit a known risk to carry forward), or authorize
production (release to an operating environment).

If the immediate action is low-risk drafting, the agent may continue.

If the immediate action is a gate transition (moving from one lifecycle checkpoint to another), the
agent should restate the approval record:

```text
I understand this as approval for:
Gate:
Evidence:
Blast-radius class:
Enforcement class:
Known risks accepted:
Next gate:
Next role:
Record locations:
```

If any field is missing, the agent should ask for the missing field instead of advancing.

## Changing Accepted Authority

Use amendment language when you need to change an artifact that has already been accepted.
Amendment means a controlled change to accepted authority while the current gate holds. Regression
means formally moving the current gate backward because the change invalidates gate entry
conditions.

Good human prompt:

```text
Amend the accepted PRD to add this missing acceptance criterion. Classify the amendment, identify
downstream artifacts that may become stale, and tell me whether regression is required.
```

Expected agent response:

```text
Current gate:
Artifact to amend:
Amendment class:
Why:
Downstream reconciliation:
Regression required:
Approval needed:
Record updates:
```

If the agent simply edits an accepted artifact without classification, ask it to stop and follow
`docs/methodology/guides/amendment-and-regression-protocol.md`.

## "Pause" And "Resume"

Use `Pause` when you want the agent to stop active work and record a resume point (the exact state
and next instruction needed to restart safely).

Expected response:

```text
Current state:
Pending decisions:
Files touched:
Resume point:
Recommended next prompt:
```

Use `Resume` when returning later. The agent should not rely on memory alone (chat or tool memory
that may be incomplete). It should re-read the manifest and active artifact (the document currently
controlling the gate).

## Correcting The Agent

Correction is normal. Use specific corrections tied to methodology authority (the accepted rules,
artifacts, and records that govern the project).

Examples:

```text
You are moving too far ahead. Stay in G1 and revise the vision only.
```

```text
That requirement introduces an integration that is not in the approved vision. Mark it deferred
(recorded for later rather than included now) or ask for approval to change scope.
```

```text
Do not treat the sub-agent report as authority. Reconcile it (compare it with source authority and
turn it into one coherent proposal) and propose changes for human review.
```

```text
The PRD acceptance criteria (observable conditions that prove a requirement is satisfied) are not
measurable. Rewrite them so each baseline requirement has an observable test or UAT signal
(user acceptance testing signal).
```

## Give The Agent Enough Context

The agent can draft faster when the human provides:

- the user or customer segment;
- business objective;
- constraints;
- non-goals (things the team is explicitly choosing not to build now);
- risk tolerance (how much uncertainty or downside the human is willing to accept);
- technology preferences;
- operational requirements;
- existing systems or integrations;
- deployment target assumptions.

You do not need to provide everything up front. The agent should ask only questions that materially
affect the current artifact or gate.

## Require Evidence

For any claim of readiness, ask:

```text
What evidence supports that status?
```

For implementation, evidence (proof or support for a readiness claim) may include:

- tests run;
- UAT results;
- code review findings;
- traceability entries (links from requirements to implementation, tests, and review evidence);
- deployment validation;
- monitoring checks.

For planning, evidence may include:

- accepted artifacts;
- recorded approvals;
- amendment or reconciliation records;
- resolved open questions;
- documented risk acceptance.

## Agent Output Should Be Operational

Good agent output should tell you:

- what it inspected;
- what it changed or proposes to change;
- what remains uncertain;
- what human decision is needed;
- what file records the state;
- what the next step is.

Weak output says only:

```text
What do you want me to do next?
```

In GenDev, the methodology usually supplies the next step. The agent should recommend it and ask for
confirmation when the current mode requires confirmation.


## Brainstorming Artifacts With The Agent

Brainstorming is allowed before an artifact is ready, but it must not become hidden authority. Use the agent to explore candidate goals, users, requirements, risks, or architecture options, then ask it to map only accepted material into the artifact template. Keep speculative ideas labeled as options, open questions, or rejected alternatives until a human accepts them.

Traceability should begin early and become more precise as artifacts mature. Vision discussions may produce outcome-level criteria. PRD work turns those criteria into stable requirement IDs and acceptance criteria. Architecture work binds requirements to components, verification strategy, and coverage expectations. The traceability matrix can therefore evolve progressively, but each row must name its source authority and must not claim verification before matching evidence exists.
