# Architecture Specification: Team Task Tracker

Status: Accepted

## Technology Stack

Example stack: TypeScript, Next.js App Router, PostgreSQL, Prisma, Zod, Vitest, Playwright.

The stack is illustrative. A real project must record its accepted stack in
`docs/project/decisions/0001-technology-stack.md`.

## Domain Model

- Workspace: tenant boundary for all boards and tasks.
- User: authenticated actor with workspace membership.
- Board: workspace-scoped project board.
- Task: board-scoped work item.
- Comment: task-scoped discussion entry.
- ActivityEvent: append-only board/task activity record.

## Component Ownership

| Component | Responsibility |
| --- | --- |
| Web UI | Forms, board display, activity feed display. |
| Server actions/API | Validate inputs, enforce workspace access, perform mutations. |
| Data layer | Persist boards, tasks, comments, and activity events. |
| Authorization helper | Resolve workspace membership and deny cross-workspace access. |

## Runtime Model

User requests flow through authenticated server actions. Server actions validate input with schemas,
authorize workspace access, write domain changes, and write activity records in the same transaction
when activity is required.

## Security Boundaries

- Workspace ID is a tenant boundary.
- All board/task/comment reads and writes must verify workspace membership.
- Client-provided workspace, board, and task IDs are untrusted.
- Activity records must not include secrets or auth tokens.

## Deferred Architecture

- Invite flow.
- Notification service.
- Webhook integrations.
- Custom workflow engine.

## Verification Specification

- Cross-workspace access is denied in tests.
- Status changes produce activity records.
- Task mutation and activity record writes are transactional.
