# Product Requirements Document: Team Task Tracker

Status: Accepted

## Product Objective

Provide a small-team SaaS task tracker where workspace members can manage project boards, tasks,
status changes, comments, and recent activity.

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Status |
| --- | --- | --- | --- |
| REQ-001 | Users can create a workspace-scoped project board. | Creating a board records name, owner, workspace, and created timestamp. | baseline |
| REQ-002 | Users can create tasks on a board. | Task has title, optional description, status, assignee, due date, and creator. | baseline |
| REQ-003 | Users can move tasks between `todo`, `doing`, and `done`. | Status changes persist and appear in recent activity. | baseline |
| REQ-004 | Users can add comments to tasks. | Comments display author, timestamp, and body. | baseline |
| REQ-005 | Users can view recent board activity. | Activity includes task creation, status change, assignment change, and comments. | baseline |
| REQ-006 | Users cannot view boards outside their workspace. | Unauthorized access returns a denial without leaking board details. | baseline |
| REQ-007 | Users can invite workspace members. | Deferred until Phase 2; Phase 1 uses seeded workspace membership. | deferred |

## Non-Functional Requirements

| ID | Category | Requirement | Acceptance Criteria | Status |
| --- | --- | --- | --- | --- |
| REQ-NF-001 | Security | Workspace access must be enforced server-side. | Tests deny cross-workspace board and task access. | baseline |
| REQ-NF-002 | Audit | Task changes must create activity records. | Tests verify activity rows for create, status, assignment, and comment events. | baseline |
| REQ-NF-003 | Reliability | Phase 1 data writes must be transactional where activity records are required. | Task mutation tests fail if task changes persist without activity. | baseline |

## Primary Workflow

1. User opens a workspace board list.
2. User creates a board.
3. User creates a task on the board.
4. User assigns the task and moves it to `doing`.
5. System records activity.
6. User views the board activity feed.

## Out Of Scope

- Billing.
- External integrations.
- Notifications.
- Custom workflow statuses.
- Public sharing.

## Open Questions

| Question | Owner | Blocking |
| --- | --- | --- |
| Which authentication provider should Phase 1 use? | Product owner | Architecture |
