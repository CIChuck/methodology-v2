# Phase 1 Construction Directive: Board And Task Foundation

Status: Accepted

## AI Builder Role

You are implementing a bounded Phase 1 workflow from documented authority. Implement only the board,
task, comment, activity, and workspace authorization behavior authorized by the tactical plan.

## Source Authority

- PRD: `prd.md`
- Architecture: `architecture.md`
- Governance/Security: `governance-security.md`
- Phase Build Plan: `phase-1-build-plan.md`
- Tactical Plan: `phase-1-tactical-plan.md`

## Allowed Scope

- Data models needed for Phase 1.
- Server-side validation and authorization.
- Board/task/comment/activity mutations.
- Minimal UI for the Phase 1 workflow.
- Required tests and UAT support.

## Non-Goals

Do not implement invitations, billing, notifications, external integrations, custom statuses, or
admin dashboards.

## Required Tests

- Workspace membership positive and negative tests.
- Task lifecycle integration tests.
- Activity-event write tests.
- Invalid input tests.
- Smoke UAT for create board, create task, move task, comment, and view activity.

## Stop Conditions

Stop if implementation requires a new external service, a changed authentication provider,
authorization behavior not covered by governance, or a deferred feature.

## Reporting

Report changed files, tests added, commands run, skipped verification, risks, and documentation
updates.
