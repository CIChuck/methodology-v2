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
docs/project/vision/vision.md
docs/project/prd/prd.md
docs/project/architecture/architecture.md
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

scaling:
  blast_radius_class: C2
```

The Vendor Contract Tracker is a C2 project in this walkthrough. C2 means standard product work:
the app is useful enough to deserve the full gate chain, and it handles confidential business
metadata, but it is not yet classified as regulated, irreversible, or production-critical C3 work.
If the project later adds external integrations, automated contract actions, regulated records, or
agentic runtime behavior, the team should reclassify before continuing.

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
Evidence reviewed: docs/project/vision/vision.md
Enforcement class: attested
Blast-radius class: C2
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

Representative structured approval event:

```yaml
event_type: gate_transition
from_gate: G1
to_gate: G2
decision: approved
decided_by: Chuck
gate_started_on: 2026-06-10
ready_for_approval_on: 2026-06-10
approval_requested_on: 2026-06-10
decided_on: 2026-06-10
enforcement_class: attested
blast_radius_class: C2
combined_gates: N/A
combined_gate_justification: N/A
artifact_status: Accepted
evidence:
  - path: docs/project/vision/vision.md
    revision: TBD
    status: Accepted
checked: Confirmed integrations remain deferred and success criteria are measurable.
known_risks_accepted:
  - risk: Integrations may be requested earlier than planned.
    rationale: Acceptable because integrations remain deferred unless explicitly approved.
next_role: prd-agent
next_artifact: docs/project/prd/prd.md
manifest_updated: true
```

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

Representative provenance header:

```text
Produced by: Lead agent with human review
Produced on: 2026-06-10
Produced with: human-agent collaboration
Agent identity: Codex lead agent, session TBD
Derived from:
  - path: docs/project/vision/vision.md
    revision: TBD
```

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

G4 approval is required before build planning. Build planning starts with the
phase plan (the build partition), which G5 certifies; the per-phase build plan,
tactical plan, and construction directive are then produced inside the phase
loop.

## G5: Build Ready

Human prompt:

```text
Create the phase plan: partition this build into ordered, independently testable
phases with a requirement coverage map and integration criteria. For a small
tracker this may be a single phase delivering contract inventory, ownership,
status, renewal-window filtering, and role-based access tests; do not include
external integrations. Then create the Phase 1 build plan at checkpoint G5.1.1,
with the phase exit test defined.
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

G5 approval authorizes the phase loop; implementation begins only after the phase's accepted construction directive and build prompt at G5.<id>.3.

Amendment example during G5:

```text
Discovery: The PRD forgot to require a contract owner email field needed for renewal escalation.
Likely classification: additive-within-scope amendment if it only clarifies owner contact data
already implied by the owner workflow.
Required action: record amendment approval, update PRD, mark affected architecture, tests, and
traceability rows stale until reconciled, then continue at G5 if build-ready conditions still hold.
Regression: not required unless the new field changes authorization, data model assumptions, or
phase scope beyond what G3/G4 approved.
```

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
- context provenance (what the reviewer received and what was excluded);
- documentation drift;
- remediation recommendation (what should be fixed, deferred, or explicitly accepted as risk).

Representative review context provenance:

```text
Reviewing agent: Independent code review agent
Inputs provided: PRD, architecture, governance/security spec, construction directive, diff, test output
Authority document revisions used: TBD until committed
Implementation diff or commit reviewed: Phase 1 branch diff
Implementer session shared with reviewer: No
Exceptions: None
```

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
- value review trigger and owner;
- enforcement class, blast-radius class, and override status;
- post-deployment owner;
- known limitations.

Deployment approval:

```text
I approve deployment of Phase 1 to the internal production environment. I accept manual rollback for
this release. Post-deployment owner is Chuck. Value review is due after 30 days of internal use.
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

Representative value review row:

```text
Criterion: Reduce missed renewal follow-up
Measure: Internal sample of active contracts with owner and notice date recorded
Target: 95% of active contracts have owner and notice date by day 30
Actual: 92%
Result: missed
Evidence Source: Day-30 production export and owner review
Follow-up: Add import cleanup and owner reminder workflow to next-phase candidates.
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

## Walkthrough Reading Note

This walkthrough is practitioner teaching material, not executable example evidence. Read it through
the current 1.0 lifecycle: C2 criteria use EARS form and include unwanted behavior, G3 approves a
verification specification with criterion IDs, G5.0 accepts the phase plan, each phase uses the
G5.<phase>.1 through G5.<phase>.3 checkpoint ladder before implementation, G6 is aggregate review
readiness, G7 is final acceptance, G8 records deployment or approved non-deployment, and G9 is
terminal as-built close-out. Current executable and planning examples live under
`docs/resources/examples/current/`.

## Production Close-Out Illustration

For 1.0, the walkthrough should be read as reaching terminal close-out, even when the product is
not deployed to a live environment. The following excerpts show the expected shape. They are
illustrative, not substitute evidence for a real project.

### Aggregate Review Excerpt

```text
Status: Complete
project: vendor-contract-tracker
Candidate revision: abc1234
Changed files reviewed:
  - src/contracts/importer.py
  - src/contracts/repository.py
  - tests/test_contract_import.py
Integration regression result: pass
Residual findings: none blocking
Reviewer independence: fresh context; implementation transcript not used
```

### Deployment Readiness Excerpt

```text
Status: Complete
Deployment is intended now: no
Release artifact: local operator package
Deployment target: no production target for walkthrough
Approval owner: Vendor Ops Owner
Non-deployment trigger: internal workflow validation only
Rollback readiness: restore prior repository revision
Monitoring owner: Vendor Ops Owner
```

### Gate-Log Event Excerpt

```text
event_id: evt-g8-nondeploy-001
schema_version: 2
event_type: deployment_approval
gate: G8
deployment_intent: non_deployment
release_candidate: abc1234
approved_by: Vendor Ops Owner
approved_on: 2026-07-11
evidence_event_ids:
  - evt-g7-final-acceptance-001
```

### Terminal Close-Out Excerpt

```text
Status: Complete
Deployment disposition: approved non-deployment
Operations result: no live operations started
Value disposition: not_due
Final traceability: current
As-built close-out: complete
Known residuals: none blocking
Next review trigger: first real production deployment request
```

The lead agent should generate missing late-lifecycle artifacts with:

```bash
./scripts/new-artifact.sh --kind final-code-review
./scripts/new-artifact.sh --kind aggregate-remediation
./scripts/new-artifact.sh --kind deployment-readiness
./scripts/new-artifact.sh --kind production-runbook
./scripts/new-artifact.sh --kind deployment-record
./scripts/new-artifact.sh --kind project-value-review
./scripts/new-artifact.sh --kind project-as-built
```

The human must still approve G8 deployment or non-deployment and G9 close-out. Generated files do
not advance gates by themselves.
