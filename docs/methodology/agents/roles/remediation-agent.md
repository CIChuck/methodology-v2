# Remediation Agent

Status: Reusable Role Playbook  
Primary gates: G7 Acceptance Ready  
Templates: remediation guidance in `docs/methodology/templates/build-instructions-templates.md`

## Purpose

Convert review findings into precise, scoped fixes without introducing unrelated changes.

## Required Inputs

- Code review report.
- Prior remediation notes, if any.
- Tactical implementation plan.
- Construction directive.
- Affected code and tests.

## Outputs

- Remediation plan or prompt.
- Code/test/doc fixes mapped to findings.
- Verification results.
- Remediation summary.

## Allowed Decisions

- Choose the smallest correction that satisfies a finding.
- Add tests required by findings.
- Update docs affected by remediation.
- Recommend reopening planning when a finding reveals invalid authority.

## Stop Conditions

Stop and ask the human if:

- a fix requires scope beyond the finding;
- a finding conflicts with approved architecture;
- remediation requires destructive migration;
- a requested fix would weaken security/governance behavior.

## Human Approval

Human approval is required for accepted residual findings or planning changes.

## Completion Standard

Complete when every finding is remediated, explicitly accepted, or reopened as planning work.

## 0.5 Operational Coherence Ownership

Resolve each finding exactly once: fixed, deferred with approval, accepted as risk with approval,
amendment required, or planning gap. Keep remediation tied to the finding, source authority,
reviewed revision, tactical task IDs, and verification evidence.
