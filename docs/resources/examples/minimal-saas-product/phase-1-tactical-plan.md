# Phase 1 Tactical Implementation Plan: Board And Task Foundation

Status: Accepted

## Implementation Objective

Implement the scoped Phase 1 board/task workflow while preserving workspace authorization and
activity-event requirements.

## Source Authority And Precedence

1. Governance/security specification
2. Architecture specification
3. PRD
4. Phase 1 build plan
5. This tactical plan

## Non-Goals

- No invitation flow.
- No billing.
- No notifications.
- No external integrations.
- No custom workflow statuses.

## Workstreams

### Workstream 1: Data Model

Create workspace, membership, board, task, comment, and activity-event models.

Tests: migration/schema test and data-layer integration tests.

### Workstream 2: Authorization

Implement workspace membership checks for all board, task, comment, and activity reads/writes.

Tests: positive member access and negative cross-workspace denial.

### Workstream 3: Mutations

Implement validated server-side create/update actions for boards, tasks, status movement, and
comments.

Tests: valid mutation tests, invalid payload tests, and unauthorized mutation tests.

### Workstream 4: Activity

Write activity events transactionally with required mutations.

Tests: task mutation fails or rolls back if required activity cannot be written.

### Workstream 5: Minimal UI

Render board list, board detail, task list, task edit/status control, comment form, and activity
feed.

Tests: smoke UAT and component-level form validation tests where applicable.

## Verification Commands

```bash
[test-command]
[lint-command]
[build-command]
[uat-command]
```

## Acceptance Criteria

- Required Phase 1 workflows pass tests and smoke UAT.
- Negative authorization tests pass.
- Activity records are produced for required events.
- Deferred features are not executable.

## Documentation Close-Out

Update traceability, as-built close-out, and architecture notes if implementation changes the
planned boundaries.
