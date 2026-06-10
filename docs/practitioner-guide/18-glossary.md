# 18. Glossary

## Purpose

This glossary defines terms used throughout the GenDev Practitioner Guide. GenDev is the
documentation-first methodology in this repository for building software with AI-assisted coding
agents. It is intentionally verbose. A novice practitioner should be able to use it to learn both
GenDev terminology and the GenDev mindset.

The most important mindset shift is this:

```text
GenDev treats durable project authority, meaning accepted repository documents and records, as the
control system for AI-assisted development.
```

That means the project is not governed by whatever the human and agent last discussed in chat. It is
governed by the current accepted artifacts, manifest state, approval records, traceability evidence,
and as-built documentation.

## Accepted

`Accepted` is an artifact status meaning the human has approved the artifact as current authority
for its scope. An accepted PRD governs requirements. An accepted architecture governs structure and
technical boundaries. An accepted governance/security specification governs identity, authorization,
data sensitivity, audit, and tool behavior.

Accepted does not mean perfect. It means good enough to govern the next stage, with known risks and
open questions recorded. If material facts change later, the artifact should be revised, superseded,
or supplemented by a decision record.

## Acceptance

Acceptance is the human decision that an artifact, implementation, phase, or release state is
sufficient to move forward. Acceptance is broader than a casual approval in chat. It should be
recorded when it changes project authority or lifecycle state.

Examples:

- accepting the vision so the project can move to PRD;
- accepting the PRD so architecture can begin;
- accepting residual review risk after remediation;
- accepting a phase after tests and review evidence exist.

## Acceptance Criteria

Acceptance criteria are observable conditions that prove a requirement or artifact is satisfied.
They should be specific enough to become tests, UAT scenarios, review checks, or operational
validation steps.

Weak acceptance criterion:

```text
The system is easy to use.
```

Better acceptance criterion:

```text
Given a seeded contract inventory, a user can locate a target active contract by vendor name or
status filter within the UAT scenario.
```

The GenDev mindset is that acceptance criteria are not decorative. They are the bridge from
requirements to tests and review evidence.

## Active Artifact

The active artifact is the document currently being drafted, reviewed, approved, or used as the
controlling source for the current gate. At G1, the active artifact is usually the vision document.
At G2, it is the PRD. At G5, there may be several active planning artifacts, including phase build
plan, tactical implementation plan, test/UAT plan, and construction directive.

When an agent resumes work, it should identify the active artifact before making changes.

## Active Project

The active project is the initialized product instance under `docs/project/`. It is distinct from
the reusable methodology under `docs/methodology/` and the initialization skeleton under
`docs/project-template/`.

The active project contains the documents that govern the actual product being built.

## Advisory

Advisory means useful but not authoritative. Sub-agent output is advisory. Suggestions from a review
agent are advisory until they are accepted into an artifact, approval record, decision record,
traceability matrix, or as-built close-out.

The advisory/authority distinction prevents parallel agents from accidentally changing project
scope or risk posture.

## Advisory Mode

`advisory` is a collaboration mode where the agent analyzes, critiques, and recommends, but does not
edit project artifacts unless the human explicitly authorizes the edit. Use advisory mode when the
human wants analysis without state changes.

Example:

```text
Use advisory mode. Review the PRD for testability gaps, but do not edit files.
```

## Agent

An agent is an AI coding assistant operating in the repository. In GenDev, "agent" usually refers to
the lead agent unless the text specifically says sub-agent. The agent may draft documents, inspect
code, run commands, propose plans, coordinate sub-agents, implement authorized scope, review work,
and update documentation.

The agent does not own product intent, business risk, or gate approval.

## Agent CLI

An agent CLI is a command-line interface for an AI coding agent, such as Codex or Claude Code. The
CLI is the operational surface the practitioner uses to start sessions, send prompts, approve tool
actions, and review agent output.

GenDev does not depend on a specific CLI. It depends on the agent reading the repository authority
and preserving gate discipline.

## Agent Role

An agent role is the lifecycle stance the lead agent should take. Role playbooks live under
`docs/methodology/agents/roles/`.

Examples:

- product vision agent;
- PRD agent;
- architecture agent;
- security governance agent;
- phase planning agent;
- implementation agent;
- code review agent;
- remediation agent;
- deployment readiness agent;
- as-built close-out agent.

The role helps the agent focus on the right work at the right gate.

## AGENTS.md

`AGENTS.md` is the root instruction file for agents that support this convention. In this
repository, it tells agents where methodology authority lives, how to treat `docs/project/`, which
guides to follow, and how to preserve approvals.

In GenDev, `AGENTS.md` is a durable instruction surface, not the place for all project decisions.
Project decisions belong under `docs/project/`.

## Approval

Approval is a human control point. It is the explicit decision that an artifact, gate transition,
phase, risk acceptance, deployment, rollback, or close-out may proceed.

Approval should record:

- what was approved;
- who approved it;
- when it was approved;
- what evidence was reviewed;
- what the approver checked;
- what risks were accepted;
- what conditions apply;
- what happens next.

Tool approval is not the same as GenDev approval. Approving an agent command only lets the tool
perform an action. It does not approve a lifecycle gate.

## Approval Boundary

An approval boundary is a point where the agent must stop and ask the human for explicit approval.
Examples include G1 to G2, PRD acceptance, stack decision acceptance, production deployment, and
accepting major review findings without remediation.

The practitioner should expect the agent to stop at approval boundaries even in proactive mode.

## Approval-Gated Mode

`approval-gated` is a collaboration mode where the agent pauses for explicit human approval before
gate movement or major artifact finalization. It is the default conservative mode for a newly
initialized project.

Approval-gated mode is useful when the team is still developing trust in the methodology, the agent,
or the project direction.

## Approval Log

The approval log is `docs/project/approvals/gate-log.md`. It is the durable historical record of
gate approvals, material risk acceptance, open questions carried forward, deployment approval,
rollback decisions, and phase close-out approvals.

The manifest summarizes the latest state. The approval log preserves the history.

## Approval State

Approval state is the current status of a gate or approval process as recorded in
`docs/project/project.yaml`.

Typical values:

```text
pending
drafting
ready_for_review
ready_for_approval
approved
blocked
superseded
```

The agent should report approval state when responding to `What's next?`.

## Checked

`Checked` is the approval-record field where the approver states one specific thing they actually
verified. It is intentionally small but important.

Weak checked statement:

```text
Looks good.
```

Useful checked statement:

```text
Confirmed that the PRD acceptance criteria are measurable for REQ-001 through REQ-006.
```

The point is not to turn approval into a long review essay. The point is to make approval
meaningful enough that a future human or agent can tell the approver engaged with the evidence.

## Approver

The approver is the human authorized to approve a gate, artifact, risk acceptance, deployment, or
phase close. The approver may be the same person as the project owner in a small project. In larger
projects, different gates may have different approvers.

An agent should not mark a gate `ready_for_approval` or `approved` if the required approver is
unknown.

## Architecture

Architecture is the durable description of system structure and technical boundaries. It explains
how the product will be organized and how implementation should proceed without inventing core
structure during coding.

Architecture should cover:

- terminology and domain model;
- system boundaries;
- component responsibilities;
- runtime model;
- data model;
- state lifecycle;
- interfaces;
- failure behavior;
- security-sensitive boundaries;
- deferred architecture.

## Architecture Ready

Architecture Ready is G3. It means the architecture and major technical decisions are accepted
enough for governance/security work and build planning to proceed. It does not mean every detail is
implemented. It means implementation will not need to invent the core system design.

## Artifact

An artifact is a durable project document that captures authority, evidence, or lifecycle state.
Artifacts are not just paperwork. They are the control surfaces that guide the agent.

Examples:

- vision document;
- PRD;
- architecture specification;
- governance/security specification;
- ADR;
- phase build plan;
- tactical implementation plan;
- test/UAT plan;
- construction directive;
- code review report;
- traceability matrix;
- as-built close-out;
- gate approval log.

## Artifact Status

Artifact status describes the maturity of a document.

Common values:

```text
Draft
Ready for Review
Ready for Approval
Accepted
Superseded
Complete
```

`Complete` is used for evidence/reporting artifacts such as close-out or review records. `Accepted`
is used for planning authority artifacts.

## As-Built Close-Out

As-built close-out is the final documentation step that records what actually exists after
implementation, review, remediation, and possibly deployment. It reconciles planned work with
actual behavior.

It should record:

- implemented behavior;
- deviations from plan;
- known limitations;
- deferred items;
- test and UAT evidence;
- traceability status;
- production status, if deployed;
- next-phase or backlog recommendations.

The GenDev mindset is that future agents should not have to infer reality from old plans.

## Assumption

An assumption is something the team believes or is temporarily using as a working premise, but has
not fully verified. Assumptions are allowed, but they must be visible.

Example:

```text
Assume the first customer manages 25 to 500 vendor contracts.
```

If an assumption could materially affect scope, architecture, security, or production, it should be
validated or carried forward as an open question.

## Authority

Authority is the set of documents and records that govern project work. GenDev distinguishes
authority from conversation. Chat can contain ideas and decisions, but durable documents must record
anything that affects scope, risk, implementation, tests, or production.

Authority includes:

- constitution;
- active project artifacts;
- accepted decision records;
- approval log;
- manifest;
- traceability matrix;
- as-built documentation.

## Authority Drift

Authority drift occurs when the agent or team starts acting on information that is not recorded in
the governing documents. It often happens when decisions stay in chat, sub-agent findings are
silently adopted, or implementation changes behavior without updating docs.

Correction usually requires re-orienting from `project.yaml`, updating the relevant artifact, and
recording approval or risk acceptance if needed.

## Backlog

The backlog is the set of future work items, deferred features, known limitations, or follow-up
tasks that are not in current scope. GenDev does not prescribe a specific backlog tool. The key is
that deferred or future work must not be confused with current authorized scope.

## Baseline

Baseline means required for initial delivery or current phase delivery. A baseline requirement is
not optional. It must have acceptance criteria and a verification path.

## Blocking Question

A blocking question is an unresolved issue that prevents the current gate from advancing safely.

Example:

```text
Should this system be single-tenant or multi-tenant?
```

If the answer materially changes architecture, security, or scope, the question blocks the relevant
gate. Non-blocking questions may be carried forward if recorded with owner, timing, and risk.

## Build Plan

A build plan defines the scope and acceptance surface for an implementation phase. It says what the
phase will deliver, what is out of scope, what workstreams exist, what tests are expected, and what
documentation must be reconciled.

The build plan bounds the phase. It is not a substitute for the tactical implementation plan or
construction directive.

## Build Ready

Build Ready is G5. It means the team has enough accepted authority to begin a bounded implementation
phase. Build-ready work normally requires accepted vision, PRD, architecture, governance/security,
phase plan, tactical plan, test/UAT plan, and construction directive.

The phrase "build ready" should make practitioners ask: ready to build exactly what, under which
authority, with which tests, and with which stop conditions?

## Carry Forward

To carry an open question forward means the team explicitly allows it to remain unresolved while the
project advances. Carrying forward should be recorded. It should include why the question is
non-blocking, who owns it, and when it must be resolved.

## Chat History

Chat history is the conversation between the human and agent. It is useful for context, but it is
not durable project authority. Future agents may not have the same chat context, and even when they
do, chat can be ambiguous.

The GenDev rule is:

```text
If it matters, record it in project authority.
```

## CLAUDE.md

`CLAUDE.md` is Claude Code's persistent instruction file. Claude Code reads `CLAUDE.md`, not
`AGENTS.md`, so a Claude Code project should create a `CLAUDE.md` that imports `AGENTS.md`.

Example:

```markdown
@AGENTS.md
```

Claude-specific instructions may be added below the import.

## Close-Out

Close-out is the act of completing the documentation and evidence needed to preserve the actual
state of the project after work is done. Close-out includes as-built documentation, traceability
updates, known limitations, deferred items, test evidence, and next steps.

Close-out prevents future agents from treating old plans as current reality.

## Code Review

Code review is the conformance check after implementation. It compares the actual changes against
the construction directive, tactical plan, PRD, architecture, governance/security spec, and tests.

In GenDev, review is not primarily a style preference exercise. It prioritizes:

- bugs;
- scope drift;
- missing tests;
- security issues;
- documentation drift;
- unaccepted residual risk.

## Codex

Codex is OpenAI's AI coding agent. In this guide, Codex-specific notes describe how to point Codex
at GenDev authority, how to use `AGENTS.md`, and how to distinguish Codex tool approvals from GenDev
gate approvals.

Codex is a tool surface. It does not change the GenDev lifecycle.

## Collaboration Mode

Collaboration mode is the human-selected operating style for the agent. It controls how proactive
or conservative the agent should be within the methodology.

Common modes:

- `proactive`;
- `approval-gated`;
- `advisory`;
- `execution-focused`.

Mode changes do not override required approvals.

## Complete

`Complete` is a status used for evidence or close-out artifacts that record completed work. It is
similar to `Accepted` but is usually used when the artifact is not future planning authority.

Example:

```text
Status: Complete
```

on an as-built close-out document means the close-out record itself is complete.

## Construction Directive

The construction directive is the controlling implementation instruction for a phase. It tells the
implementation agent what to build, what not to build, which authority to follow, which tests to
run, and when to stop.

It should include:

- source authority and precedence;
- implementation objective;
- allowed scope;
- non-goals;
- workstreams;
- tests and verification;
- security/governance constraints;
- documentation close-out requirements;
- stop conditions.

The construction directive is what turns planning into authorized implementation.

## Context

Context is the information available to the agent in the current session. Context may include chat,
files, tool output, instructions, and memory. Context is not automatically authority. The agent must
distinguish what it knows from what the project has accepted.

## Deferred

Deferred means intentionally excluded from current scope and moved to future consideration. A
deferred item should have a reason and, when possible, a suggested future phase or decision point.

Deferred does not mean forgotten. It means visible but not authorized now.

## Deployment

Deployment is the act of releasing the accepted implementation to a target environment. Deployment
requires its own readiness and approval. Implementation acceptance does not automatically approve
deployment.

Deployment planning should include:

- target environment;
- configuration and secrets;
- migration;
- rollback;
- validation;
- monitoring;
- owner.

## Deployment Approval

Deployment approval is explicit human permission to release to a deployment target. It should record
release scope, target, rollback review, monitoring review, known risks, and post-deployment owner.

Deployment approval must not be inferred from "the implementation is accepted."

## Deployment Ready

Deployment Ready is G8. It means the team has accepted the implementation and has enough operational
planning to deploy responsibly.

Deployment-ready does not always mean automated deployment. For a small first release, manual steps
may be acceptable if they are documented and the risk is accepted.

## Deployment Target

The deployment target is the environment where the product will run. Examples include local demo,
internal staging, internal production, customer production, or a managed cloud environment.

The deployment target matters because secrets, monitoring, rollback, privacy, and operational risk
depend on where the product runs.

## Durable Record

A durable record is a file committed or maintained in the project that future humans and agents can
inspect. In GenDev, durable records include project artifacts, approval logs, decision records,
traceability matrices, and as-built close-out docs.

## Edge Case

An edge case is an unusual, boundary, or error condition that the system must handle. Edge cases
belong in the PRD and test/UAT planning because they affect acceptance and implementation.

Example:

```text
What happens when a contract has a renewal date but no notice deadline?
```

## Evidence

Evidence is the material that supports a readiness, acceptance, verification, or deployment claim.

Examples:

- accepted artifact status;
- approval log entry;
- test output;
- UAT result;
- code review report;
- traceability row;
- deployment validation;
- monitoring check.

The GenDev mindset is that claims of readiness should have evidence.

## Execution-Focused Mode

`execution-focused` is a collaboration mode used after planning is accepted. The agent should
implement authorized scope, run required verification, report blockers, and avoid reopening product
or architecture decisions unless blocked.

Use this mode for implementation only when build-ready authority exists.

## Failure Mode

A failure mode is a recurring way the methodology can break down. Examples include coding too early,
ambiguous approval, missing tests, authority drift, skipped close-out, or production deployment
without rollback.

Chapter 17 describes common failure modes and correction prompts.

## Gate

A gate is a lifecycle checkpoint that defines whether the project is ready to move from one kind of
work to the next. Gates are the backbone of GenDev.

A gate is not just a label. It has:

- required artifacts;
- readiness criteria;
- stop conditions;
- approval expectations;
- evidence requirements;
- next role and next artifact.

Example:

```text
G2 Requirements Ready
```

means the PRD is accepted, requirements are testable, edge cases and deferred items are visible, and
architecture can begin without inventing product scope.

The GenDev mindset is that gates prevent hidden decisions. If a project cannot pass a gate, the
agent should not improvise around it. It should identify the missing authority.

## Gate Approval

Gate approval is the human decision that the project may move from one gate to the next. It should
be recorded in the gate log and summarized in the manifest.

Gate approval should include:

- gate transition;
- decision;
- approver;
- date;
- evidence reviewed;
- checked statement;
- known risks accepted;
- open questions carried forward;
- next role;
- next artifact.

## Gate Log

The gate log is `docs/project/approvals/gate-log.md`. It records durable gate decisions and material
risk acceptance. It is the historical counterpart to `project.yaml`.

New gate-log entries should use structured gate-log events so future agents and checker scripts can
read the decision consistently.

## Gate Status

Gate status is the current lifecycle status recorded in the manifest.

Values include:

```text
pending
drafting
ready_for_review
ready_for_approval
approved
blocked
superseded
```

Gate status should align with artifact status. If the manifest says `ready_for_approval` while the
artifact says `Draft`, the project state is ambiguous.

## GenDev

GenDev is the methodology represented by this repository. It is a documentation-first,
human-approved, agent-assisted development workflow that moves a product from idea to production
operation through durable artifacts, gates, evidence, review, and close-out.

## Governance

Governance is the set of rules that determine who may do what, what requires approval, what must be
audited, and how agents/tools are allowed to interact with the system. In the guide, governance is
usually paired with security because identity, authorization, data handling, audit, and tool access
are tightly related.

## Governance Ready

Governance Ready is G4. It means the governance/security specification is accepted enough for build
planning. Authorization, audit, data sensitivity, secrets, tool access, and security tests should be
explicit.

## Human Team Member

The human team member is the person collaborating with the agent. The human owns intent, product
judgment, approval, risk acceptance, and production decisions.

The human may delegate drafting and analysis to agents, but not accountability.

## Implementation

Implementation is the coding and configuration work that builds the accepted scope. In GenDev,
implementation follows the construction directive. It should not be the place where product,
architecture, governance, or test strategy are invented.

## Implementation Ready For Review

Implementation Ready For Review is G6. It means implementation work is complete enough for code
review and conformance review. It does not mean the phase is accepted.

## Lead Agent

The lead agent is the primary agent coordinating the work. It orients from project authority,
recommends next steps, drafts artifacts, coordinates sub-agents, reconciles outputs, updates
records, and stops for approval.

The lead agent owns process orchestration. The human owns approval.

## Manifest

The manifest is `docs/project/project.yaml`. It summarizes active project state:

- project identity;
- current gate;
- human owner and approvers;
- collaboration mode;
- authority paths;
- current approval state;
- evidence;
- risk disposition;
- next gate, role, and artifact;
- phase paths.

The manifest is not a replacement for artifacts. It is the map and state summary that lets a future
agent resume correctly.

## Material

Material means important enough to affect scope, risk, architecture, implementation, acceptance,
deployment, or future work. Material decisions should be recorded. Material risks require explicit
human disposition.

## Methodology

Methodology is the reusable system of principles, gates, guides, templates, roles, and protocols
under `docs/methodology/`. It defines how projects should proceed. It is distinct from the active
project under `docs/project/`.

## Methodology Checker

The methodology checker is `scripts/check-methodology.sh`. It validates baseline structure,
initialized project structure, manifest paths, approval-state invariants, ready/accepted artifact
placeholders, phase-plan sections, and traceability evidence signals.

Passing the checker does not prove the product is correct. It proves certain methodology invariants
are not obviously broken.

## Non-Goal

A non-goal is something the project explicitly will not do in the current scope. Non-goals protect
against scope creep and accidental implementation.

Example:

```text
Native calendar integration is not a Phase 1 goal.
```

Non-goals should be visible in vision, PRD, phase planning, and construction directives.

## Open Question

An open question is an unresolved issue that may affect the project. Open questions should have an
owner, timing, and blocking status.

Open questions are healthy when visible. They are dangerous when hidden.

## Owner

The owner is the human accountable for the project or artifact. The owner may also be the approver
in a small project. Ownership means responsibility for direction and follow-through, not necessarily
that the owner writes every document.

## Phase

A phase is a bounded unit of implementation and delivery. It should be small enough to plan, build,
test, review, remediate, and close out coherently.

Phases help prevent the agent from trying to build an entire product in one uncontrolled pass.

## Phase Acceptance

Phase acceptance is the human decision that a phase is acceptable after implementation, review,
remediation, tests, and traceability updates. It is part of G7.

Phase acceptance may include residual risk acceptance.

## Phase Build Plan

The phase build plan defines phase scope, non-goals, workstreams, acceptance criteria, test
strategy, and documentation close-out expectations. It answers "what is this phase supposed to
deliver?"

## Post-Deployment Validation

Post-deployment validation is the check performed after deployment to confirm that the release is
actually working in the target environment. It may include smoke tests, logs, health checks, metrics,
manual workflow validation, or incident review.

## PRD

PRD means Product Requirements Document. It translates the accepted vision into testable product
requirements. The PRD should use stable requirement IDs and observable acceptance criteria.

The PRD should not invent a new product direction that contradicts the vision. If the direction
changes, update the vision or record the decision.

## Proactive Mode

`proactive` is a collaboration mode where the agent leads the process, recommends next steps,
drafts artifacts when enough context exists, and asks for approval at control points.

Proactive mode does not allow the agent to skip gate approvals.

## Production

Production is the environment where real users, real operations, or real business consequences are
present. For an internal product, production may be an internal deployment. For a customer product,
production may be a customer-facing cloud environment.

Production requires deployment readiness, monitoring or validation, rollback thinking, ownership,
and explicit approval.

## Production Operations

Production operations are the activities after deployment that keep the product understandable and
supportable. They include monitoring, incident response, rollback decisions, operational ownership,
runbooks, known limitations, and follow-up work.

## Project Authority

Project authority is the active, durable source of truth for a product under `docs/project/`. It
includes accepted artifacts, approvals, traceability, decision records, and as-built documentation.

## Project Template

`docs/project-template/` is the initialization skeleton used by `scripts/init-project.sh`. It is not
the active project. It defines what a new `docs/project/` should look like.

## Ready For Approval

`Ready for Approval` is an artifact status. `ready_for_approval` is a gate status. Both mean the
work is believed to be mature enough for human approval, but approval has not yet been granted.

Before marking something ready for approval, the agent should ensure:

- evidence exists;
- open questions are resolved or explicitly carried forward;
- known risks are listed;
- required approver is known;
- next gate, role, and artifact are identified.

## Ready For Review

`Ready for Review` means the artifact or work is ready for human or agent critique but is not yet
presented for final approval. It is a useful intermediate state when the team expects revisions.

## Reconciliation

Reconciliation is the lead agent's process of combining feedback, sub-agent outputs, review
findings, and human corrections into one coherent update. Reconciliation should surface conflicts
instead of hiding them.

## Remediation

Remediation is the work of fixing review findings, adding missing tests, correcting scope drift, or
updating documentation after review. Remediation should address findings without broadening scope.

## Residual Risk

Residual risk is risk that remains after mitigation or remediation. Residual risk may be accepted by
the human, but it must be visible.

Example:

```text
Manual rollback remains a residual operational risk for the first internal pilot.
```

## Review

Review is the activity of checking an artifact or implementation against its governing authority.
Review may happen before approval, after implementation, before deployment, or during close-out.

In GenDev, review should be evidence-based and tied to source authority.

## Risk

Risk is a condition that may cause harm, rework, delay, security exposure, operational failure, or
product mismatch. Risks should be visible before approval.

Examples:

- security expectations are underspecified;
- scope may expand into enterprise workflow;
- integrations may be required earlier than assumed;
- rollback may be incomplete;
- tests may not cover authorization failure paths.

## Risk Acceptance

Risk acceptance is the human decision to continue despite a known risk. It should record the risk,
why it is acceptable now, conditions, follow-up, and owner where appropriate.

Agents should challenge unclear risk acceptance and ask the human to make it explicit.

## Role Playbook

A role playbook is a methodology document that tells the agent how to behave in a lifecycle role.
Role playbooks live in `docs/methodology/agents/roles/`.

They are reusable guidance, not project-specific authority.

## Rollback

Rollback is the procedure for returning the system to a prior acceptable state after a failed or
risky deployment. Rollback may be automated or manual. If rollback is not possible, the deployment
risk must be explicitly accepted.

Rollback planning should identify trigger, owner, steps, data impact, and validation after rollback.

## Runbook

A runbook is an operational document that tells a future operator how to deploy, validate, monitor,
troubleshoot, and roll back the system. A runbook should be practical enough to use during an
incident or deployment window.

## Scope

Scope is the set of work authorized for a product, artifact, phase, or implementation directive.
Scope should include both in-scope and out-of-scope items. Clear scope lets the agent move quickly
without silently broadening the product.

## Scope Creep

Scope creep is the expansion of work beyond what was approved. It often appears when the agent adds
"nice to have" behavior during implementation. Non-goals, deferred items, and construction
directives protect against scope creep.

## Security

Security covers the protection of users, data, systems, secrets, tools, deployment environments, and
operations. In GenDev, security is addressed explicitly in governance/security work before build
planning.

## Smoke Test

A smoke test is a quick validation that the deployed or implemented system is basically functional.
It does not replace full verification. In production operations, smoke tests are useful immediately
after deployment or rollback.

## Source Authority

Source authority is the document or record that governs a claim or task. When an agent reviews code,
the source authority may be the construction directive, PRD, architecture, and governance/security
spec. When drafting a PRD, the source authority is the accepted vision.

Asking "what is the source authority?" is one of the fastest ways to re-orient an agent.

## Stop Condition

A stop condition is a situation where the agent must pause and ask for human input or planning
review. Stop conditions prevent the agent from solving ambiguity by inventing hidden decisions.

Examples:

- approval is ambiguous;
- architecture is missing;
- security behavior is implicit;
- tests cannot be run;
- implementation requires new scope;
- deployment lacks rollback.

## Structured Gate-Log Event

A structured gate-log event is a Markdown section in `docs/project/approvals/gate-log.md` that
contains a small YAML block. The YAML block records the event type, gate transition, decision,
approver, evidence, checked statement, accepted risks, and next role or artifact.

Structured events are still human-readable, but they are also easier for future tools to validate.
They are the bridge between lightweight Markdown records and mechanical enforcement or metrics.

## Sub-Agent

A sub-agent is a bounded secondary agent used for specialized analysis or work. In GenDev,
sub-agents are advisory unless the human explicitly delegates a bounded write task and the lead
agent reconciles the output.

Good sub-agent tasks are bounded, source-aware, and review-oriented.

## Superseded

Superseded means an artifact or decision has been replaced by a newer accepted artifact or decision.
Superseded documents should remain available for history but should not govern current work.

## Tactical Implementation Plan

The tactical implementation plan turns phase scope into executable workstreams. It defines tasks,
file/module ownership expectations, tests, verification commands, migration steps, and close-out
requirements.

It answers "how will this phase be implemented?"

## Template

A template is a reusable starting document under `docs/methodology/templates/`. Templates are not
complete artifacts. They become project artifacts only after initialization and human/agent
collaboration.

## Test/UAT Plan

The test/UAT plan defines how the team will prove the phase works. It should include automated
tests, negative tests, security tests, fixtures, UAT scenarios, verification commands, and expected
evidence.

## Tool Approval

Tool approval is permission for an agent tool to perform an action, such as editing files or running
a command. It is not the same as GenDev gate approval.

This distinction matters because a practitioner may approve a shell command without approving a
product decision.

## Traceability Matrix

The traceability matrix maps requirements to architecture, implementation, tests, UAT evidence,
review confirmation, and status. It prevents the project from claiming requirements are verified
without evidence.

Traceability is one of the main tools for future-agent continuity.

## Traceability Sample

A traceability sample is an approver's spot check of one traceability row. The approver follows one
requirement from source requirement through architecture, build plan, implementation, test/UAT
evidence, review confirmation, and close-out.

Sampling does not prove every row is correct. It changes the incentive structure: agents and humans
know that traceability claims may be opened and checked, not merely summarized.

## UAT

UAT means User Acceptance Testing. In GenDev, UAT is the human-executable or user-representative
acceptance surface. It verifies whether the system satisfies important workflows from the user's
perspective.

UAT may be manual, automated, or a combination.

## Verification

Verification is the process of proving that work satisfies requirements, architecture rules,
governance rules, or operational expectations. Verification may include automated tests, manual
checks, UAT, review, traceability, deployment validation, and monitoring evidence.

## Vision

The vision is the G1 artifact that explains why the product exists and what success means. It should
describe the problem, target users, desired outcomes, success criteria, non-goals, assumptions,
risks, and open questions.

The vision should not become a solution design.

## Vision Ready

Vision Ready is G1. It means the project has a clear enough problem, audience, success definition,
non-goals, risks, and open questions to proceed to PRD drafting after human approval.

## Workstream

A workstream is a coherent slice of phase work. It should have clear scope, implementation
expectations, tests, and close-out requirements.

Good workstreams help agents implement in bounded units rather than broad, vague tasks.
