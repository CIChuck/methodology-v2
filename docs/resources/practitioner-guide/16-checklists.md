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
check is not applicable, but the reason should still be clear when risk is involved. Enforcement
means the methodology controls declared in `docs/project/project.yaml`; attested enforcement means
named humans confirm the checks, while enforced means a mechanical binding blocks nonconforming
changes.
Metrics means on-demand measurement derived from required project records, not a separate reporting
system.
Blast-radius class means the declared estimate of how much harm or cost a mistake could plausibly
cause. `C1` means contained, low-risk, reversible work. `C2` means ordinary product work. `C3`
means critical work with higher data, operational, integration, automation, or irreversible-action
exposure.

For the three document gates (G1 vision, G2 PRD, G3 architecture), the G1-G3 checklists below are
the same items `scripts/close-gate.sh` reads from the templates and walks the approver through at
closing time. Running the script is the operational way to work these three checklists: it refuses
to close unless every item is affirmed, and it records the affirmations in the gate log. The other
checklists here remain manual reminders.

## New Project Checklist

```text
[ ] baseline repository cloned
[ ] working branch selected
[ ] ./scripts/init-project.sh "Project Name" run
[ ] docs/project/project.yaml created
[ ] docs/project/approvals/gate-log.md created
[ ] enforcement block present in docs/project/project.yaml
[ ] enforcement.class confirmed as attested or enforced
[ ] enforcement attestation cadence and override record path visible
[ ] enforcement binding paths point to existing reference binding files
[ ] scaling.blast_radius_class confirmed as C1, C2, or C3
[ ] scaling.classification_reason recorded
[ ] scaling.combined_gates empty or justified
[ ] ./scripts/check-methodology.sh passes
[ ] optional local hook installed, if the team wants pre-commit checks
[ ] AI agent started from repository root
[ ] owner identified
[ ] gate approver identified
[ ] collaboration mode selected
[ ] current gate confirmed as G1
```

## Blast-Radius Classification Checklist

```text
[ ] class selected: C1, C2, or C3
[ ] classification reason written in docs/project/project.yaml
[ ] sensitive or regulated data considered
[ ] external integrations considered
[ ] irreversible actions considered
[ ] production automation considered
[ ] agentic runtime behavior considered
[ ] operational impact considered
[ ] reclassification triggers listed when uncertainty exists
[ ] combined gates recorded with justification, if any
[ ] C3 projects use no combined gates
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

## Sub-Agent Budget Checklist

```text
[ ] each sub-agent assignment has a role
[ ] each assignment has source authority
[ ] each assignment has scope and non-goals
[ ] each assignment has a budget
[ ] each assignment has budget escalation conditions
[ ] lead agent reconciles outputs before changing authority
[ ] material conflicts are surfaced to the human
```

## G1 Vision Checklist

```text
[ ] problem statement is clear
[ ] target users are clear
[ ] desired outcomes are stated
[ ] success criteria have measure, target, read timing, owner, and evidence source
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
[ ] enforcement or attestation evidence recorded
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
[ ] enforcement or attestation evidence reviewed
[ ] override policy reviewed if any control was bypassed
[ ] post-deployment owner named
[ ] value review trigger and owner named
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
[ ] methodology metrics snapshot recorded or explicitly deferred
[ ] value review status recorded, if production or measurable value occurred
[ ] next phase or backlog state clear
```

## Additional Operational Checks

G2 criteria checks:

```text
[ ] C2/C3 acceptance criteria use EARS form
[ ] C1 criteria are concrete and observable when EARS is intentionally not used
[ ] unwanted behavior is specified for every known error or abuse path
[ ] each requirement has a stable ID
```

G3 verification checks:

```text
[ ] verification specification has stable criterion IDs
[ ] each criterion traces to G2 requirements or unwanted behavior
[ ] design interrogation is proportional to C1/C2/C3 blast radius
[ ] human approval confirms the specification faithfully encodes intent
```

Phase-exit checks:

```text
[ ] phase evidence cites stable tactical task IDs
[ ] test/UAT commands and results are recorded honestly
[ ] independent phase review records exact reviewed revision
[ ] remediation disposition exists even when remediation is not required
[ ] traceability rows point to real evidence, not templates or plans
[ ] per-phase as-built close-out records actual behavior and deviations
```
