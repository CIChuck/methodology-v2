# Phase 1 Build Plan: Board And Task Foundation

Status: Accepted

## Phase Objective

Build the first usable board/task workflow for one seeded workspace: board creation, task creation,
task status movement, comments, activity records, and server-side workspace authorization.

## Phase Scope

| Item | Requirement |
| --- | --- |
| Board creation | REQ-001 |
| Task creation and status movement | REQ-002, REQ-003 |
| Comments | REQ-004 |
| Activity feed | REQ-005, REQ-NF-002 |
| Workspace authorization | REQ-006, REQ-NF-001 |

## Out Of Scope

- Invitations.
- Billing.
- Notifications.
- External integrations.
- Custom statuses.

## Workstreams

| Workstream | Description |
| --- | --- |
| Data model | Workspace, board, task, comment, activity tables. |
| Authorization | Workspace membership checks for all board/task access. |
| Mutations | Board/task/comment server actions with validation. |
| Activity | Append activity records for required mutations. |
| UI | Minimal board and task workflow. |
| Tests | Unit, integration, negative authorization, and smoke UAT. |

## Test Strategy

| Workstream | Unit Tests | Integration Tests | Negative Tests | UAT |
| --- | --- | --- | --- | --- |
| Authorization | Membership helper | Board/task access | Cross-workspace denial | Denied access smoke |
| Mutations | Schema validation | Task lifecycle | Invalid workspace/task IDs | Create and move task |
| Activity | Event builder | Transactional write | Missing activity failure | Activity feed visible |

## CLI And UAT Strategy

Manual smoke test:

1. Sign in as seeded workspace member.
2. Create board.
3. Create task.
4. Move task to `doing`.
5. Add comment.
6. Confirm activity feed shows all events.

## Acceptance Criteria

| Criterion | Verification Method |
| --- | --- |
| Member can create board and task. | Integration test and smoke UAT. |
| Status changes write activity. | Integration test. |
| Cross-workspace access denied. | Negative authorization test. |
| Comments appear in activity. | Integration test and smoke UAT. |

## Documentation Close-Out Requirements

```text
[ ] architecture docs reflect as-built state
[ ] traceability matrix updated
[ ] known limitations documented
[ ] test evidence recorded
```
