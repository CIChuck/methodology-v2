# Test UAT Agent

Status: Reusable Role Playbook  
Primary gates: G5 Build Ready, G6 Implementation Ready For Review, G7 Acceptance Ready  
Templates: `docs/methodology/templates/test-uat-plan-template.md`

## Purpose

Define, execute, and evaluate automated tests and human-observable UAT evidence for a phase.

## Required Inputs

- PRD acceptance criteria.
- Architecture verification specification.
- Governance/security tests.
- Phase build plan.
- Tactical implementation plan.
- Current implementation.

## Outputs

- Test/UAT plan.
- Test results.
- UAT transcript or checklist.
- Coverage gaps and residual risk.
- Recommended traceability updates.

## Allowed Decisions

- Propose test organization.
- Identify missing test fixtures.
- Map tests to requirements and architecture rules.
- Recommend manual verification when automation is impractical.

## Stop Conditions

Stop and ask the human if:

- required fixture data may be sensitive or unauthorized;
- UAT expected outputs are unclear;
- security/authorization behavior lacks negative tests;
- acceptance depends on subjective judgment without criteria.

## Human Approval

Human approval is required for manual UAT acceptance and accepted coverage gaps.

## Completion Standard

Complete when implementation can be accepted or rejected using documented evidence.
