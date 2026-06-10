# 17. Common Failure Modes

## Purpose

This chapter helps practitioners diagnose and correct common methodology failures. A failure mode
means a recurring way the process can break down. A symptom means what the practitioner observes. A
risk means the likely harm if the symptom is ignored. A correction means the prompt or action that
brings the work back under GenDev control. Build-ready means approved to begin implementation.
Manifest means the compact `project.yaml` state summary. Artifact means a durable project document
or record.

## Agent Starts Coding Too Early

Symptom:

```text
The agent begins creating source files while the project is still at G1, G2, G3, or G4.
```

Risk:

- requirements, architecture, and security are invented during implementation (the build step
  where source files are created or changed).

Correction:

```text
Stop. We are not build-ready. Re-read project.yaml and gates.md. Identify the current gate and the
missing authority before making code changes.
```

## Approval Is Ambiguous

Symptom:

```text
The human says "looks good" or "proceed" and the agent advances the gate (moves to the next
lifecycle checkpoint).
```

Risk:

- future agents cannot tell what was approved or what risk was accepted (known risk allowed to
  carry forward).

Correction:

```text
Do not advance the gate yet. Prepare the approval summary with evidence (proof supporting the
readiness claim), known risks, open questions, next gate, next role, and manifest updates. Ask for
explicit approval.
```

## Manifest And Artifact Status Drift

Symptom:

```text
project.yaml says ready_for_approval but the artifact still says Draft.
```

Risk:

- state becomes ambiguous and future agents may advance incorrectly.

Correction:

```text
Reconcile artifact status (the document's readiness state) and manifest gate status (the
`project.yaml` gate readiness state). If the artifact is not ready, set the gate back to drafting
or ready_for_review. If it is ready, update the artifact status and approval summary.
```

## Stale Evidence Used For Approval

Symptom:

```text
The gate evidence cites an artifact whose upstream PRD, architecture, governance, or phase plan has
changed since the evidence revision was pinned.
```

Risk:

- the team approves a gate using authority that no longer matches the current project record.

Correction:

```text
Stop gate movement. Mark the downstream artifact Stale, compare it against the changed upstream
authority, and either reconcile the artifact, supersede it, or record explicit human risk
acceptance before proceeding.
```

## Missing Provenance

Symptom:

```text
An authority or evidence artifact does not say who produced it, when it was produced, whether an
agent participated, or which upstream revisions it derives from.
```

Risk:

- future reviewers cannot tell whether the artifact is current, what authority it used, or whether
  a later upstream change invalidated it.

Correction:

```text
Add the provenance header. Fill Produced by, Produced on, Produced with, Agent identity, and
Derived from path/revision. Use revision TBD only for draft work that has not yet been pinned.
```

## PRD Is Too Vague

Symptom:

```text
Requirements say "users can manage contracts" without specific behavior or acceptance criteria
(observable conditions proving the requirement is satisfied).
```

Risk:

- architecture and tests cannot be derived.

Correction:

```text
Rewrite each baseline requirement with a stable ID, one behavior, observable acceptance criteria,
and testability notes.
```

## Architecture Invented During Implementation

Symptom:

```text
The implementation agent chooses persistence, routing, authorization, or deployment patterns not
covered by architecture.
```

Risk:

- system structure becomes accidental.

Correction:

```text
Stop implementation. Update architecture and ADRs (architecture decision records) first, then
revise the tactical plan and construction directive if needed.
```

## Governance Is Deferred Too Long

Symptom:

```text
The product has users, roles, sensitive data, or external tools, but no governance/security spec
(the artifact defining identity, authorization, data, audit, tool, and approval rules).
```

Risk:

- authorization, audit, data handling, and tool access become implicit.

Correction:

```text
Move to G4. Draft governance/security before build planning. Define actors, roles, permitted and
forbidden actions, audit behavior, data classification, and negative tests.
```

## Tests Do Not Trace To Requirements

Symptom:

```text
Tests exist, but no one can say which requirement they prove.
```

Risk:

- implementation may pass tests while failing product acceptance.

Correction:

```text
Update the traceability matrix (the map from requirements to tests, implementation, and evidence).
Map each baseline requirement to tests, UAT evidence (user acceptance testing evidence),
implementation references, and review confirmation.
```

## Sub-Agents Conflict Silently

Symptom:

```text
Multiple sub-agents (specialized AI workers assigned bounded review or analysis) reviewed an
artifact, but the lead agent returns only a smooth summary.
```

Risk:

- important disagreements are hidden.

Correction:

```text
Return the sub-agent synthesis (the reconciled summary of sub-agent findings) with conflicts,
authority cited by each side, impact, recommended resolution, and required human decisions.
```

## Deployment Treated As Implementation Detail

Symptom:

```text
The implementation is accepted and the agent proceeds directly to production deployment (release to
an operating environment).
```

Risk:

- no rollback (return to a previous known-good state), monitoring (health and error observation),
  runbook (operator procedure), or deployment approval.

Correction:

```text
Stop. Deployment is G8. Prepare deployment readiness with release scope, deployment target,
configuration, migration, rollback, monitoring, validation, known risks, and post-deployment owner.
```

## As-Built Close-Out Is Skipped

Symptom:

```text
Work is merged or deployed, but docs still describe planned behavior rather than actual behavior.
```

Risk:

- future agents inherit false authority.

Correction:

```text
Perform G9 close-out. Update as-built documentation (the record of what actually exists),
traceability, known limitations, deferred items, production status, and next-phase recommendations.
```

## Over-Correcting Into Bureaucracy

Symptom:

```text
The team spends more time filling templates (starter artifact documents) than clarifying decisions.
```

Risk:

- practitioners abandon the methodology.

Correction:

```text
Keep artifacts as lightweight as the risk allows, but preserve the required content: scope, non-goals,
approval, risk, tests, and evidence.
```

GenDev is not about document volume. It is about durable, inspectable authority.
