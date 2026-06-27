# 15. Prompt Library

## Purpose

This chapter provides prompt patterns (reusable wording for common human-to-agent instructions) for
common GenDev moments. Practitioners should adapt them to the current project rather than copying
blindly.

The prompts intentionally use GenDev terms. In this chapter, a gate means a lifecycle checkpoint, an
active artifact means the document currently governing the work, approval state means the recorded
status of the current gate or artifact, authority means the accepted documents and records the
agent must follow, a collaboration mode means the operating style that tells the agent whether to
lead, pause for approval, advise only, or execute an accepted plan, and a construction directive
means the accepted build instruction that controls implementation.
Blast-radius class means the declared C1, C2, or C3 risk/exposure level that controls whether
GenDev can be lightweight or must be stricter.

Other prompt terms are compact because prompts need to be usable. PRD means product requirements
document. UAT means user acceptance testing. A non-goal is something the team explicitly chooses not
to build now. A workstream is a group of related implementation tasks. Verification means running
checks that prove the work behaves as expected. Remediation means fixing review findings or
explicitly resolving them. Residual risk means risk that remains after remediation. Deployment
means release to an operating environment. Rollback means returning to a previous known-good state.
Monitoring means observing health, errors, and important signals. Validation means confirming that
the released or implemented product actually works. A sub-agent is a specialized AI worker assigned
a bounded review or analysis task.

## Start

```text
Let's begin. Follow AGENTS.md and docs/project/project.yaml. Use the GenDev start-and-next-step
protocol and tell me the current gate, blast-radius class, active artifact, approval state, and
recommended next step.
```

## Set Mode

```text
Lead proactively. Draft current-gate artifacts when enough context exists, but preserve all required
human approvals and stop before advancing gates.
```

```text
Use advisory mode. Analyze the current artifact and recommend changes, but do not edit files.
```

```text
Use execution-focused mode for the accepted construction directive. Implement only authorized scope.
```

## Re-Orient

```text
Re-orient from AGENTS.md, docs/project/project.yaml, docs/project/approvals/gate-log.md, and the
current active artifact. Report current gate, mode, blast-radius class, artifact status, approval
state, blockers, and next recommendation.
```

## Classify Blast Radius

```text
Classify this project as C1, C2, or C3 before we proceed. Record the classification reason,
reclassification triggers, and whether any gate combination is appropriate. Do not combine gates
unless the justification is durable in project.yaml and the approval record.
```

## Draft Vision

```text
Draft the G1 vision/problem framing document. Focus on the problem, target users, desired outcomes,
success criteria with measure, target, read timing, owner, and evidence source, non-goals,
assumptions, risks, and open questions. Do not propose implementation details beyond constraints.
```

## Draft PRD

```text
Draft the G2 PRD from the accepted vision. Use stable requirement IDs. Make every baseline
requirement testable with observable acceptance criteria. Identify deferred items and blocking open
questions.
```

## Draft Architecture

```text
Draft the G3 architecture and stack decision from the accepted PRD. Define terminology, boundaries,
component responsibilities, runtime model, data model, lifecycle, interfaces, failure behavior,
security-sensitive boundaries, and deferred architecture.
```

## Draft Governance/Security

```text
Draft the G4 governance/security specification. Define actors, roles, permitted actions, forbidden
actions, authorization tests, audit behavior, secrets handling, data sensitivity, trust boundaries,
tool rules, and stop conditions.
```

## Build Planning

```text
Create the G5 phase plan: partition the build into ordered, independently
testable phases, with a requirement coverage map and integration criteria. Then,
for the first phase, create its phase build plan at checkpoint G5.1.1 (objective,
scope, non-goals, workstreams, exit test, verification commands, negative tests,
documentation close-out, stop conditions). The tactical plan and construction
directive follow at G5.1.2 and G5.1.3.
```

## Implementation

```text
Implement Phase 1 in execution-focused mode. Follow the accepted construction directive as
controlling authority. Do not broaden scope. Run required verification. Stop if implementation
requires unapproved product, architecture, governance, migration, or deployment decisions.
```

## Review

```text
Review the implementation for conformance against the PRD, architecture, governance/security spec,
tactical plan, construction directive, and test/UAT plan. Prioritize bugs, scope drift, missing
tests, security issues, and documentation drift. Findings first, ordered by severity.
```

## Remediation

```text
Remediate the review findings exactly once each. Do not broaden scope. Add or update tests required
by the findings. Report verification results and any residual risks that require human acceptance.
```

## Deployment Readiness

```text
Prepare deployment readiness for the accepted implementation. Include release scope, deployment
target, configuration and secrets expectations, migration steps, rollback steps, monitoring,
post-deployment validation, known risks, and post-deployment owner.
```

## Gate Approval

```text
Prepare the approval summary for the current gate. Include gate, artifact status, evidence reviewed,
enforcement class, blast-radius class, combined-gate justification if applicable, open questions,
known risks, risks requiring acceptance, proposed next gate, proposed next role, and manifest
updates to record.
```

## Sub-Agent Review

```text
Use bounded sub-agents for review. Assign one reviewer to security/governance, one to testability,
and one to architecture or maintainability. Give each reviewer a budget and budget escalation
condition. Do not edit files. Return a reconciled findings list, conflicts, and required human
decisions.
```

## Enforcement Attestation

```text
Prepare the enforcement attestation for this gate. Identify the enforcement class, checks reviewed,
checker or guard output, implementation-path status, exceptions, attester, and gate-log record to
update.
```

## Override Record

```text
Prepare an override record. Name the control being bypassed, why the override is needed, who must
approve it, what risk is accepted, what compensating action applies, when normal control resumes,
and where the record will live.
```

## Value Review

```text
Prepare the value review for the current phase. Compare each due G1 success criterion against
actual evidence. Mark each criterion met, missed, or unmeasurable. Do not reframe missed criteria
as success without a decision record.
```

## Pause

```text
Pause work. Summarize current state, files touched, pending decisions, blocked items, and the exact
resume point.
```

## Resume

```text
Resume from durable project state, not chat memory. Re-read project.yaml, gate-log.md, and the
active artifact. Identify drift and recommend the next action.
```
