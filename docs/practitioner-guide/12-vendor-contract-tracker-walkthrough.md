# 12. Vendor Contract Tracker Walkthrough

## Purpose

This chapter shows a thin end-to-end path (a minimal complete journey from idea to production
operation) through the methodology using a Vendor Contract Tracker. The example is intentionally
lightweight. It demonstrates lifecycle movement (progression through GenDev gates) rather than
fully populating every production-grade artifact (document or record).

## Scenario

The team wants to build a product that helps small businesses track vendor contracts, owners,
renewal dates, notice deadlines, status, and basic operational risk (risk that affects day-to-day
business operation).

The human starts with:

```text
Let's begin.
```

The lead agent (the primary AI agent coordinating the methodology) should not start coding. It
should initialize or inspect `docs/project/`, identify G1 (the vision gate), and begin the vision
loop (draft, review, and approval of the vision artifact).

## Initialize

Command:

```bash
./scripts/init-project.sh "Vendor Contract Tracker"
```

Expected active project paths:

```text
docs/project/project.yaml
docs/project/approvals/gate-log.md
docs/project/vision/vendor-contract-tracker-vision.md
docs/project/prd/vendor-contract-tracker-prd.md
docs/project/architecture/vendor-contract-tracker-architecture.md
```

Initial manifest state (the compact `project.yaml` tracking record):

```yaml
project:
  name: "Vendor Contract Tracker"
  current_gate: G1

approvals:
  current_gate:
    gate: G1
    status: pending
```

## G1: Vision

Human prompt:

```text
Lead proactively. Draft the G1 vision for a Vendor Contract Tracker. The first users are small
business operations and finance teams. Keep enterprise contract lifecycle management out of scope.
```

Expected agent work:

- draft the vision document;
- identify target users;
- define non-goals (things the first version is explicitly not trying to build);
- identify assumptions (planning beliefs not yet proven);
- identify risks;
- list open questions;
- keep the gate unapproved.

Representative vision excerpt:

```text
Problem:
Small businesses manage vendor contracts across email, shared drives, spreadsheets, and individual
department records. They lack one reliable view of active vendors, owners, renewal dates, notice
deadlines, and contract status.

Non-goals:
- contract drafting;
- redlining;
- e-signature;
- enterprise procurement workflows;
- external vendor portal.
```

Before approval (the human decision to move the gate forward), the agent should present:

```text
Gate: G1 -> G2
Artifact status: Ready for Approval
Evidence reviewed: docs/project/vision/vendor-contract-tracker-vision.md
Known risks: integrations may be needed earlier than assumed
Open questions: exact customer segment, attachment scope, role model
Next gate: G2
Next role: prd-agent
```

Human approval:

```text
I approve G1 -> G2. Accept the risk that integrations may be requested earlier than planned. Keep
integrations deferred unless approved during PRD or architecture.
```

Expected records:

- vision status becomes `Accepted`;
- gate log receives a G1 -> G2 record (a durable approval history entry);
- manifest current gate advances to G2 (the requirements gate).

## G2: PRD

Human prompt:

```text
Proceed to G2. Draft the PRD from the accepted vision. Make every baseline requirement testable.
Keep integrations deferred.
```

Expected PRD (product requirements document) content:

- requirement IDs (stable labels for individual requirements);
- baseline status;
- deferred integration requirements;
- user workflows;
- edge cases;
- acceptance criteria (observable conditions proving a requirement is satisfied);
- testability notes (notes about how the requirement can be tested or verified).

Representative requirements:

```text
REQ-001: A user can create a vendor contract record with vendor name, internal owner, status, start
date, renewal date, notice deadline, and notes.

Acceptance:
Given an editor user, when required fields are supplied, the system persists the contract record and
shows it in the contract inventory.
```

```text
REQ-002: A user can filter contracts by status and upcoming renewal window.

Acceptance:
Given seeded contracts with different renewal dates, when a user selects a 90-day renewal window,
the system shows only matching active contracts.
```

G2 approval should not occur until acceptance criteria are measurable and open questions
(unresolved decisions or unknowns) are either resolved or explicitly carried forward (allowed to
move into a later gate or phase).

## G3: Architecture

Human prompt:

```text
Draft the architecture and stack decision from the accepted PRD. Keep the first phase simple. Prefer
a small SaaS MVP (software-as-a-service minimum viable product) with explicit tenant and
authorization boundaries.
```

Expected architecture (system structure and technical boundary) topics:

- application boundary (what the application owns and what it leaves outside);
- user roles;
- contract record lifecycle;
- data model (the records, fields, and relationships the system stores);
- attachment decision;
- tenant model (how data and access are separated between customers or organizations);
- service boundaries;
- failure behavior;
- deferred integrations;
- stack ADR (architecture decision record for the technology stack).

Representative architecture decision:

```text
Phase 1 will use a single application boundary with server-rendered or API-backed UI, relational
storage, and explicit role checks. External calendar, email, accounting, and document-storage
integrations remain deferred.
```

G3 approval requires the human to accept the stack (main technology choices) and architecture
boundaries.

## G4: Governance And Security

Human prompt:

```text
Draft the governance/security specification. Treat contract metadata and attachments as
confidential business information. Define positive and negative authorization tests.
```

Expected governance topics (security, policy, identity, audit, and tool rules):

- actors (users, systems, or agents that can take actions);
- roles;
- permitted actions;
- forbidden actions;
- audit events (important actions that should be recorded);
- data classification (how sensitive the data is);
- retention assumptions (how long records are expected to be kept);
- secrets handling (how credentials and private configuration are protected);
- agent/tool stop conditions (situations where the agent must pause and ask the human);
- security test requirements.

Representative rule:

```text
Viewer users may read contract records they are permitted to access. Viewer users must not create,
edit, delete, export, or upload attachments. Negative authorization tests are required for each
forbidden action.
```

G4 approval is required before build planning (creating the phase plan, tactical plan, test plan,
and construction directive).

## G5: Build Ready

Human prompt:

```text
Create the Phase 1 build plan, tactical implementation plan, test/UAT plan, and construction
directive. Phase 1 should deliver contract inventory, ownership, status, renewal-window filtering,
and role-based access tests. Do not include external integrations.
```

Expected phase scope (what Phase 1 includes and excludes):

```text
In scope:
- create/list/edit contract records;
- status and owner fields;
- renewal-window filtering;
- basic role model;
- authorization tests;
- UAT fixture records.

Out of scope:
- e-signature;
- contract redlining;
- external calendar integration;
- accounting integration;
- AI contract interpretation.
```

Expected construction directive (the controlling build instruction):

- source authority order (which documents govern and which wins if they conflict);
- allowed files/modules;
- workstreams;
- tests;
- verification commands;
- stop conditions.

G5 approval authorizes implementation (building the approved scope).

## G6: Implementation Ready For Review

Implementation prompt:

```text
Use execution-focused mode for Phase 1. Follow the construction directive. Implement only authorized
scope, add required tests, run verification, and stop for review.
```

Expected implementation report (the agent's summary of what changed and how it was verified):

```text
Implemented:
- contract record model;
- create/edit/list flows;
- status and renewal filtering;
- role checks;
- unit and integration tests;
- UAT fixture data.

Verification:
- lint passed;
- unit tests passed;
- integration tests passed;
- UAT smoke passed.

Skipped:
- none, or listed with reason.
```

G6 means ready for review (ready to be checked against authority), not accepted.

## G7: Acceptance Ready

Review prompt:

```text
Review Phase 1 for conformance against the PRD, architecture, governance/security spec, tactical
plan, construction directive, and test/UAT plan. Prioritize bugs, scope drift, missing tests, and
security issues.
```

Expected review outputs:

- findings by severity;
- file references;
- missing test coverage;
- documentation drift;
- remediation recommendation (what should be fixed, deferred, or explicitly accepted as risk).

If remediation is needed:

```text
Remediate the review findings without broadening scope. Add or update tests required by the review.
```

Acceptance requires human approval after critical and major findings are remediated (fixed) or
explicitly accepted.

## G8: Deployment Ready

Human prompt:

```text
Prepare deployment readiness for the accepted Phase 1 MVP. Assume a small internal production
environment. Include deployment procedure, rollback, monitoring, smoke tests, and post-deployment
owner.
```

Expected deployment readiness content (evidence that the release can safely enter production):

- release scope;
- environment assumptions;
- secrets/configuration list (protected credentials and runtime settings);
- deployment steps (release procedure);
- migration steps (data, schema, configuration, or environment changes);
- rollback steps (how to return to a previous known-good state);
- monitoring/logging checks (how health, errors, and important signals are observed);
- smoke test (small validation of the most important workflow);
- post-deployment owner;
- known limitations.

Deployment approval:

```text
I approve deployment of Phase 1 to the internal production environment. I accept manual rollback for
this release. Post-deployment owner is Chuck.
```

## G9: As-Built Closed

Close-out prompt:

```text
Complete G9 as-built close-out (the final record of what actually exists). Record the implemented
state, test evidence, deployment result, known limitations, deferred items, and next-phase
recommendations.
```

Expected close-out:

- as-built document complete;
- traceability updated (requirements mapped to implementation, tests, and evidence);
- methodology metrics snapshot generated or explicitly deferred;
- value review status recorded;
- deployment result recorded;
- rollback status recorded;
- known limitations documented;
- next phase identified.

Value review example:

```text
After 30 days of internal use, compare the G1 success criteria against actual usage, renewal
tracking accuracy, and owner feedback. Mark each due criterion as met, missed, or unmeasurable.
```

Representative next-phase backlog (future work intentionally postponed or newly discovered):

```text
Future candidates:
- attachment handling;
- renewal reminder notifications;
- CSV import/export;
- organization-level tenant model hardening;
- calendar integration;
- audit report export.
```

## Walkthrough Lesson

This walkthrough demonstrates the motion:

```text
idea -> vision -> PRD -> architecture -> governance -> build plan -> implementation -> review ->
acceptance -> deployment -> operation -> as-built close
```

The documents can be lightweight at first. The gate discipline should not be lightweight. Every gate
needs enough evidence (proof supporting readiness) and human approval to let future agents
understand why the project moved forward. The value review keeps the project honest about whether
the delivered product achieved the success criteria declared at the start.
