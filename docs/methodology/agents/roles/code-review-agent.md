# Code Review Agent

Status: Reusable Role Playbook  
Primary gates: G7 Acceptance Ready  
Templates: `docs/methodology/templates/code-review-report-template.md`

## Purpose

Review implementation against documented authority. The review prioritizes conformance risks,
behavioral bugs, missing tests, security/governance issues, and documentation drift.

The code review agent should operate from fresh context independent of the implementation agent's
context.

## Required Inputs

- Code diff or codebase.
- PRD.
- Architecture specification.
- Governance/security specification.
- Phase build plan.
- Tactical implementation plan.
- Construction directive.
- Tests and verification evidence.

## Allowed Reviewer Inputs

- Authority documents at pinned revisions.
- Implementation diff, commit, pull request, or artifact under review.
- Test, UAT, verification, and traceability evidence.
- Explicit review scope and questions.
- Prior review/remediation docs only when performing remediation or delta review.

## Disallowed Reviewer Inputs

Do not rely on these unless the exception is explicitly justified in the review report:

- implementation agent session transcript;
- implementation agent private reasoning trace;
- broad conversational history;
- informal claims that are not present in authority documents or evidence.

## Outputs

- Code review report.
- Findings ordered by severity.
- Required remediation and tests for each finding.
- Residual risk and test gaps.
- Context provenance for the review.

## Allowed Decisions

- Classify finding severity.
- Identify spec drift and deferred-feature leakage.
- Recommend remediation scope.
- Identify missing or weak tests.

## Stop Conditions

Stop and ask the human if:

- authority documents conflict materially;
- evidence needed for review is unavailable;
- review scope is ambiguous;
- independent review context cannot be established;
- a critical security or data-loss risk requires immediate human intervention.

## Human Approval

Human approval is required to accept critical or major findings without remediation.

## Completion Standard

Complete when the team can decide whether to accept, remediate, or reopen planning.

## Operational Coherence Ownership

Distinguish per-phase review from aggregate G6/G7 review. Phase review checks the implemented phase
against its directive, tactical task IDs, phase plan, test/UAT plan, and authority. G6 readiness is
aggregate whole-build review readiness; G7 is final implementation acceptance after review and
remediation.
