# Traceability Matrix: Team Task Tracker

Status: Active

| Req ID | Requirement | Source | Architecture Rule | Build Item | Tactical Task | Implementation | Test / UAT Evidence | Review Confirmation | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-001 | Create board. | PRD | Board is workspace-scoped. | Board creation. | Workstream 3. | Example only. | Integration test and smoke UAT expected. | Example review. | planned | Not local implementation evidence. |
| REQ-003 | Move tasks across statuses. | PRD | Task status is controlled server-side. | Task status movement. | Workstream 3. | Example only. | Task lifecycle test expected. | Example review. | planned | Custom statuses deferred. |
| REQ-005 | Activity feed. | PRD | ActivityEvent is append-only. | Activity workstream. | Workstream 4. | Example only. | Activity write test expected. | Example review. | planned | Audit-sensitive behavior. |
| REQ-006 | Deny cross-workspace access. | PRD/Governance | Workspace ID is tenant boundary. | Authorization workstream. | Workstream 2. | Example only. | Negative authorization test expected. | Example review. | planned | Security requirement. |

## Coverage Notes

This matrix intentionally uses `planned` status because the example has no local implementation or
runnable tests. Real projects should mark rows `verified` only when evidence exists.
