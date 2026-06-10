# 16. Checklists

## How To Use These Checklists

These checklists are operational reminders, not replacements for the artifacts themselves. A
baseline repository means the reusable GenDev repo before product-specific initialization. The
active project means the initialized product under `docs/project/`. A gate means a lifecycle
checkpoint. An artifact means a durable project document or record. Approval means the human
decision that a gate, artifact, risk, phase, or release may move forward. Evidence means proof that
supports a readiness claim.
Checked means the approver records one specific thing they actually verified. A structured gate-log
event means a Markdown approval entry containing a small YAML block that future agents and tools can
read consistently.

Several checklist terms are compact by design. PRD means product requirements document. UAT means
user acceptance testing. ADR means architecture decision record. Traceability means mapping
requirements to implementation, tests, and evidence. As-built means the record of what actually
exists after implementation. Rollback means returning to a previous known-good state. N/A means a
check is not applicable, but the reason should still be clear when risk is involved.

## New Project Checklist

```text
[ ] baseline repository cloned
[ ] working branch selected
[ ] ./scripts/init-project.sh "Project Name" run
[ ] docs/project/project.yaml created
[ ] docs/project/approvals/gate-log.md created
[ ] ./scripts/check-methodology.sh passes
[ ] AI agent started from repository root
[ ] owner identified
[ ] gate approver identified
[ ] collaboration mode selected
[ ] current gate confirmed as G1
```

## First Agent Session Checklist

```text
[ ] agent read AGENTS.md
[ ] agent read docs/project/project.yaml
[ ] agent identified current gate
[ ] agent identified active artifact
[ ] agent identified approval state
[ ] agent confirmed mode
[ ] agent asked only material startup questions
[ ] agent did not begin implementation
```

## G1 Vision Checklist

```text
[ ] problem statement is clear
[ ] target users are clear
[ ] desired outcomes are stated
[ ] success criteria are observable
[ ] non-goals are explicit
[ ] assumptions are separate from facts
[ ] risks are listed
[ ] open questions have owners or timing
[ ] approval summary is prepared
[ ] approver can provide a checked statement
```

## G2 PRD Checklist

```text
[ ] product objective traces to vision
[ ] stable requirement IDs exist
[ ] baseline requirements are testable
[ ] acceptance criteria are observable
[ ] edge cases are captured
[ ] deferred items have reasons
[ ] dependencies are listed
[ ] security/governance requirements are visible
[ ] architecture-blocking questions are resolved or assigned
[ ] approver can provide a checked statement
```

## G3 Architecture Checklist

```text
[ ] terminology is defined
[ ] system boundaries are explicit
[ ] components have responsibilities
[ ] runtime model is clear
[ ] data model is clear
[ ] lifecycle/state transitions are clear
[ ] interfaces are identified
[ ] failure behavior is addressed
[ ] stack ADR is accepted or ready for approval
[ ] implementation will not need to invent core structure
[ ] approver can provide a checked statement
```

## G4 Governance Checklist

```text
[ ] actors are identified
[ ] roles are defined
[ ] permitted actions are explicit
[ ] forbidden actions are explicit
[ ] authorization tests include positive and negative cases
[ ] audit behavior is defined
[ ] data sensitivity is classified
[ ] secrets handling is defined
[ ] external tool access rules are defined
[ ] agent stop conditions are defined
[ ] approver can provide a checked statement
```

## G5 Build-Ready Checklist

```text
[ ] phase scope is bounded
[ ] out-of-scope items are explicit
[ ] workstreams are defined
[ ] file/module ownership expectations exist
[ ] test requirements are defined
[ ] UAT expectations are defined
[ ] verification commands are defined
[ ] migration behavior is documented or N/A
[ ] rollback behavior is documented where applicable
[ ] construction directive is ready for implementation
[ ] approver can provide a checked statement
```

## G6 Review-Ready Checklist

```text
[ ] implementation summary exists
[ ] changed files are known
[ ] tests were added or updated
[ ] verification commands ran or skips are justified
[ ] known deviations are documented
[ ] deferred features did not leak into scope, or leakage is reported
```

## G7 Acceptance Checklist

```text
[ ] code review completed
[ ] critical findings remediated
[ ] major findings remediated or explicitly accepted
[ ] verification evidence exists
[ ] UAT evidence exists where required
[ ] traceability matrix updated
[ ] residual risk documented
[ ] phase acceptance approval recorded
[ ] traceability row sampled before close-out, if this is the phase close-out approval
```

## G8 Deployment Checklist

```text
[ ] release scope accepted
[ ] deployment target approved
[ ] configuration/secrets documented
[ ] deployment procedure documented
[ ] migration procedure documented or N/A
[ ] rollback procedure documented
[ ] monitoring/validation plan documented
[ ] post-deployment owner named
[ ] deployment approval recorded
[ ] deployment approval includes a checked statement
```

## G9 As-Built Checklist

```text
[ ] as-built close-out completed
[ ] implemented behavior documented
[ ] deviations documented
[ ] known limitations documented
[ ] deferred items tracked
[ ] test/UAT evidence recorded
[ ] production status recorded, if deployed
[ ] traceability updated
[ ] traceability sample result recorded
[ ] next phase or backlog state clear
```
