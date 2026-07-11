# Governance And Security Specification: Team Task Tracker

Status: Accepted

## Scope

This specification governs Phase 1 board, task, comment, and activity behavior.

## Identity Model

| Actor | Type | Description |
| --- | --- | --- |
| Workspace member | human | Authenticated user assigned to a workspace. |
| System | service | Application code enforcing authorization and audit behavior. |

## Roles And Permissions

| Role | Permitted Actions | Forbidden Actions |
| --- | --- | --- |
| Workspace member | Manage boards and tasks in assigned workspace. | Access another workspace. |
| System | Write activity records for approved mutations. | Skip authorization or write secrets to activity. |

## Authorization Rules

| Action | Required Authorization | Positive Test | Negative Test |
| --- | --- | --- | --- |
| View board | Workspace membership | Member can view board. | Non-member receives denial. |
| Edit task | Workspace membership for board. | Member can edit task. | Non-member cannot infer task existence. |
| Add comment | Workspace membership for board. | Member can comment. | Non-member is denied. |

## Audit Model

Activity records are required for:

- task creation;
- status change;
- assignment change;
- comment creation.

Each record includes actor ID, workspace ID, board ID, task ID where applicable, event type, and
timestamp.

## Secrets Handling

Authentication secrets and database credentials are environment-managed and must never be stored in
activity records, logs, comments, or client-visible payloads.

## Security Tests

- Deny board read across workspace.
- Deny task mutation across workspace.
- Verify task mutation writes matching activity event.
- Verify activity event payload excludes secret-like fields.
