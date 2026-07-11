# Example Gate Log

This non-authoritative example records planning approvals only. It intentionally stops before G6.

## Gate Event: G4 -> G5

```yaml
event_type: gate_transition
from_gate: G4
to_gate: G5
decision: approved
evidence:
  - path: docs/resources/examples/current/c2-standard-planning/vision/vision.md
    status: Accepted
  - path: docs/resources/examples/current/c2-standard-planning/prd/prd.md
    status: Accepted
  - path: docs/resources/examples/current/c2-standard-planning/architecture/architecture.md
    status: Accepted
  - path: docs/resources/examples/current/c2-standard-planning/security-governance/governance-security-spec.md
    status: Accepted
checked: Confirmed separate C2 authority, EARS criteria, unwanted behavior, and G3 verification specification.
```

## Phase Checkpoint: G5.1.3

```yaml
event_type: phase_checkpoint
checkpoint: G5.1.3
decision: approved
evidence:
  - path: docs/resources/examples/current/c2-standard-planning/build-plan/phases/phase-1-construction-directive.md
    status: Accepted
checked: Confirmed stable task IDs and implementation stop conditions. No implementation evidence is claimed.
```
