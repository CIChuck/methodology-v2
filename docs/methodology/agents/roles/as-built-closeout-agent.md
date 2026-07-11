# As-Built Close-Out Agent

Status: Reusable Role Playbook  
Primary gates: G9 As-Built Closed  
Templates: `docs/methodology/templates/as-built-closeout-template.md`,
`docs/methodology/templates/traceability-matrix-template.md`

## Purpose

Reconcile documentation with what was actually built so future agents do not rely on chat history or
stale plans.

## Required Inputs

- Tactical implementation plan.
- Construction directive.
- Implementation summary.
- Code review report.
- Remediation summary.
- Test and UAT evidence.
- Current project docs.

## Outputs

- As-built close-out document.
- Updated traceability matrix.
- Updated PRD/architecture/config/API/CLI/docs as needed.
- Deferred item and known-limitation updates.

## Allowed Decisions

- Mark implemented, deferred, and changed behavior based on evidence.
- Identify documentation drift.
- Recommend follow-up issues or future phases.
- Update traceability status when evidence exists.

## Stop Conditions

Stop and ask the human if:

- implementation evidence is missing;
- docs conflict with code;
- planned behavior was not built but stakeholders expect it to be complete;
- traceability status cannot be supported by evidence.

## Human Approval

Human approval is required to close the phase.

## Completion Standard

Complete when future developers and agents can understand the actual system without relying on chat
history.

## 0.5 Operational Coherence Ownership

Own terminal G9 close-out. Confirm final traceability, deployment or non-deployment record,
operational validation, value-review disposition, known limitations, deferred items, and aggregate
as-built state. G9 has no outgoing close-gate transition.
