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

## Additive-Within-Scope Amendment

An additive-within-scope amendment is a semantic change to accepted authority that adds detail
without changing accepted boundaries. It clarifies what is already in scope.

Examples:

- adding an example that fits an accepted requirement;
- naming a test case already implied by acceptance criteria;
- adding detail to a workflow without adding a new workflow;
- clarifying a non-blocking open question.

Because it changes accepted authority, it should receive lightweight human approval and downstream
review. It should not require gate regression unless the added detail invalidates a passed gate.

## Active Artifact

The active artifact is the document currently being drafted, reviewed, approved, or used as the
controlling source for the current gate. At G1, the active artifact is usually the vision document.
At G2, it is the PRD. At G5, it is the phase plan (the build partition). Inside the phase loop
(the G5.x checkpoints), the active artifact is the phase build plan, tactical plan, construction
directive, or build prompt for the phase currently being planned.

When an agent resumes work, it should identify the active artifact before making changes.

## Active Project

The active project is the initialized product instance under `docs/project/`. It is distinct from
the reusable methodology under `docs/methodology/` and the initialization skeleton under
`docs/project-template/`.

The active project contains the documents that govern the actual product being built.

## Amendment

An amendment is a controlled change to accepted authority while the current project gate stays in
place. Amendments let the team adapt without pretending the project has fully moved backward.

Examples:

- correcting an accepted PRD requirement;
- adding an acceptance criterion during implementation;
- clarifying an architecture rule after code review exposes ambiguity;
- changing a phase plan after a dependency changes.

Amendments are classified by impact:

- editorial;
- additive-within-scope;
- structural.

The higher the impact, the more approval and downstream reconciliation is required.

## Amendment Event

An amendment event is the structured gate-log record that captures a change to accepted authority.
It should record the amendment ID, class, current gate, artifact path, prior revision, new revision,
decision, approver, downstream reconciliation, whether regression is required, accepted risks, and
manifest update state.

Amendment events live in `docs/project/approvals/gate-log.md`.

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

## Agent Identity

Agent identity is the bounded record of which AI tool, model, role, or session helped produce an
artifact or implementation. It does not need to be a long transcript. It should be enough for a
future reviewer to understand whether the work was produced by a human, an agent, or human-agent
collaboration.

Examples:

- `Codex, lead agent, session 2026-06-10`;
- `Claude Code, architecture review sub-agent`;
- `N/A, human-authored`.

Agent identity is part of artifact provenance. It helps future reviewers evaluate context, but it
does not replace human approval.

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

## Approval Latency

Approval latency is the elapsed time between `approval_requested_on` and `decided_on` in a
structured gate event. It measures how long a gate waited for the human approval decision after the
team believed the evidence was ready.

Approval latency is not a scorecard for the human approver. It is a process signal. Long latency
may mean the approver is overloaded, the approval prompt was unclear, the evidence was weak, or the
gate is too broad.

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

## Blast Radius

Blast radius is the plausible harm, cost, reversibility problem, operational impact, data exposure,
or governance impact of a mistake. In GenDev, blast radius determines whether the methodology may
be compressed or must become stricter.

Low blast radius does not mean no discipline. It means the team may use a lighter shape when the
work is contained and reversible. High blast radius means the team should increase review depth,
evidence sampling, enforcement, and approval discipline.

## Blast-Radius Class

Blast-radius class is the declared project classification recorded in
`docs/project/project.yaml`. GenDev uses three classes:

- `C1 Contained`;
- `C2 Standard`;
- `C3 Critical`.

The class should be chosen early, explained in the manifest, and revisited when the project starts
touching new data, users, integrations, deployment targets, automation, or irreversible actions.

## C1 Contained

`C1 Contained` is the lowest GenDev blast-radius class. It applies to work such as internal tools,
reversible outputs, no sensitive data, and low operational risk.

C1 projects may use GenDev Lite, meaning a lightweight form of the methodology where some gates or
artifacts are combined. C1 still requires explicit problem framing, requirements, architecture
assumptions, security assumptions, build-ready approval, verification evidence, and close-out.

## C2 Standard

`C2 Standard` is the default GenDev blast-radius class. It applies to ordinary product work with
moderate operational risk, moderate data risk, normal production release discipline, or meaningful
future maintenance concerns.

C2 projects should usually use the full gate chain. Gate combination is possible only with a
recorded justification and human approval.

## C3 Critical

`C3 Critical` is the highest baseline GenDev blast-radius class. It applies to regulated data,
irreversible actions, external integrations, production-sensitive automation, agentic runtime
behavior, or high operational impact.

C3 projects should not combine lifecycle gates. They should use stronger independent review,
evidence sampling at major gates, stricter override policy, explicit production approval, and
mechanical enforcement where practical.

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
Stale
Superseded
Complete
```

`Complete` is used for evidence/reporting artifacts such as close-out or review records. `Accepted`
is used for planning authority artifacts. `Stale` means the artifact depends on upstream authority
that has changed since the pinned revision. `Superseded` means the artifact has been replaced by
newer accepted authority.

## Artifact Provenance

Artifact provenance is the record of where an artifact came from. It answers:

- who produced it;
- when it was produced;
- whether an agent participated;
- which upstream artifacts or prompts it depends on;
- which revisions of those upstream sources were used.

The baseline provenance header is:

```text
Produced by:
Produced on:
Produced with:
Agent identity:
Derived from:
  - path:
    revision:
```

Provenance does not make an artifact correct by itself. It makes the artifact inspectable. A future
human or agent can ask whether the artifact still matches the authority it was derived from.

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

## Attestation

Attestation is a named human statement that a required methodology control was checked. It is used
when the project relies on attested enforcement rather than a mechanical binding.

An attestation should record:

- what requirement or gate was checked;
- who checked it;
- when it was checked;
- what evidence was reviewed;
- whether the check passed, warned, or failed;
- what exception or override applies, if any.

Attestation is not weaker because it is human. It is weaker only when it is vague. A useful
attestation is specific enough that a future agent can reconstruct which methodology obligation was
met.

## Attested Enforcement

Attested enforcement is an enforcement class where named humans perform methodology checks on a
declared cadence and record the result. The project is still bound by the methodology. The
difference is that a human confirmation, rather than a hook or CI workflow, provides the control.

Attested enforcement is the normal baseline state for a newly initialized GenDev project because it
does not require platform-specific tooling. It should declare cadence, required attester, exception
rules, and override policy in `docs/project/project.yaml`.

## Attested Conformance

Attested conformance means the project conforms to a methodology requirement because a named human
checked the requirement and recorded the result. It is the human-recorded counterpart to mechanical
enforcement.

Attested conformance should name the requirement checked, evidence reviewed, attester, date, result,
and any exception or override. It is valid at baseline, but it should not be vague.

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

## Binding

A binding is a concrete implementation of a methodology rule on a specific platform or toolchain.
For example, a pre-commit hook, CI workflow, protected-branch rule, or repository policy can bind a
GenDev enforcement requirement to actual repository behavior.

A binding should not be claimed until it exists and is active. A project may say `class: enforced`
only when the binding can actually block, warn, or report against the declared requirement.

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

Build Ready is G5. It means the build has been partitioned into ordered,
independently testable phases and that partition is accepted. The artifact G5
certifies is the phase plan (with its requirement coverage map and integration
criteria). The per-phase build plan, tactical plan, construction directive, and
build prompt are produced inside the phase loop, at the interior `G5.x`
checkpoints, not at G5 itself.

The phrase "build ready" should make practitioners ask: ready to build which
phases, in what order, each tested how, and exiting on what?

## Checkpoint

A checkpoint is an interior progress address within the G5 to G6 span, written
`G5.<phase-id>.<n>`. It marks the acceptance of a phase planning artifact or the
exit of a phase. A checkpoint is not a gate: the gate enumeration is G0 through
G9, and checkpoints carry no separate gate-approval ceremony. See the phase loop
guide and the "G5 Interior" section of gates.md.

## Phase Loop

The phase loop is the process interior to the G5 to G6 span by which a project
builds one phase at a time: for each phase, author the build plan
(`G5.<id>.1`), tactical plan (`G5.<id>.2`), and construction directive with
build prompt (`G5.<id>.3`), then build, test, and exit (`G5.<id>.4`). Build
plans lead the wave; tactical plans and directives are authored just in time and
informed by prior-phase learnings.

## Phase Plan

The phase plan is the artifact G5 certifies. It partitions the build into
ordered, independently testable phases, maps every in-scope requirement to an
owning phase, states cross-phase rules and the partitioning rationale, and
declares integration criteria. Phase ids are stable labels; order is defined by
the plan, never computed from the id.

## Canonical Naming

Per-project artifacts use fixed, role-based filenames that are identical across all projects:
`vision.md`, `prd.md`, `architecture.md`, `phase-plan.md`, and so on. The filename names the
artifact's role, never the project. The project slug appears only in `project.yaml`, never baked into
a filename or cross-reference path. Every per-project authority artifact carries a `project:`
front-matter field matching the slug. Because names are fixed, authority pointers such as `AGENTS.md`
reference artifacts by canonical path and are correct for every project. (Constitution Rule 14.)

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

In GenDev, code review should be independent of the implementation context. The reviewer should
start from authority, diff, and evidence, not from the implementation agent's chat session.

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

## Combined Gate

A combined gate is a deliberate compression of two or more lifecycle gates into one artifact or
approval path. Combined gates are allowed only when the required content remains present and the
decision is recorded.

Example:

```text
C1 project combines G1-G4 into one framing artifact that includes problem, requirements,
architecture assumptions, governance/security assumptions, and test expectations.
```

A combined gate should record affected gates, blast-radius class, justification, preserved content,
approver, approval date, and evidence path. A combined gate is not a shortcut around approval.

## Combined-Gate Justification

Combined-gate justification is the recorded reason a project may compress gates. It should explain
why the blast radius allows compression, what required content is preserved, and what approval
still applies.

Weak justification:

```text
Small project.
```

Useful justification:

```text
G1-G4 are combined because this is a C1 local utility with reversible output, no sensitive data, no
external integrations, and the combined artifact preserves vision, requirements, architecture
assumptions, security assumptions, and test expectations.
```

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

## Context Provenance

Context provenance is the review-report record of what information was provided to a reviewer.

Minimum fields include:

- reviewing agent;
- model or version;
- review context creation date;
- inputs provided;
- authority document revisions used;
- implementation diff or commit reviewed;
- whether the implementer session was shared;
- exceptions.

Context provenance helps future humans and agents decide whether a review was independent enough to
support acceptance.

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

## Dirty Subtree

The dirty subtree is the set of downstream artifacts and evidence potentially affected by an
amendment.

Conceptually:

```text
amended artifact
  -> artifacts derived from it
     -> traceability rows citing it
        -> plans, tests, reviews, implementation evidence, deployment evidence, or close-out
```

The dirty subtree helps the lead agent decide what must be marked `Stale`, reviewed, updated, or
superseded.

## Derived From

`Derived from` is the provenance field that lists the upstream sources used to create an artifact.
Each entry should include a path and a revision.

Example:

```text
Derived from:
  - path: docs/project/prd/prd.md
    revision: 4f3a2c1
```

The field is important because downstream artifacts can become stale when an upstream source
changes. If the PRD changes after architecture has pinned an older PRD revision, the architecture
may need reconciliation before it can continue to govern implementation.

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

## Editorial Amendment

An editorial amendment changes wording, formatting, spelling, organization, or examples without
changing meaning.

Editorial amendments usually do not require gate re-approval. They may still be recorded when the
artifact is accepted and the change could confuse future readers.

## Enforced

Enforced means a mechanical binding blocks or reports nonconforming changes according to the
project enforcement contract. Enforced controls are useful for objective checks such as required
files, allowed gate values, stale evidence, provenance headers, or protected implementation paths.

Enforced does not mean no human judgment is needed. Humans still approve gates, accept risk, and
decide whether an override is justified.

## Enforced Conformance

Enforced conformance means the project conforms to a methodology requirement because a mechanical
binding checks or blocks the condition. Examples include a local hook, CI workflow, protected-branch
rule, policy check, or equivalent platform binding.

Enforced conformance is strongest for objective checks. Human approval still controls intent, risk,
gate movement, production decisions, and override judgment.

## Enforcement

Enforcement is the set of controls that make methodology rules visible, checkable, and difficult to
skip by accident. In GenDev, enforcement is declared in the project manifest and governed by
`docs/methodology/guides/enforcement-contract.md`.

Enforcement answers practical questions:

- which branch is treated as protected project authority;
- which paths count as implementation paths;
- whether checks are mechanical or human-attested;
- which exceptions are allowed;
- how overrides are approved and recorded.

The goal is not bureaucracy. The goal is to prevent an agent or human from moving past a gate,
changing protected implementation paths, or bypassing provenance and approval records without a
durable trace.

## Enforcement Class

Enforcement class is the manifest field that states whether a project is operating in `attested` or
`enforced` mode.

`attested` means named humans confirm the checks and record attestation evidence. `enforced` means
a mechanical binding performs the check. A project can run mostly enforced while keeping specific
requirements attested if the exception is documented.

## Enforcement Contract

The enforcement contract is `docs/methodology/guides/enforcement-contract.md`. It defines the
requirements that make GenDev controls enforceable or attestable, including gate transition
authority, protected implementation paths, checker execution, provenance, branch isolation, and
override records.

The contract is tool-agnostic. It defines what must be true. Tool-specific addenda or local
bindings can define how a particular repository enforces those requirements.

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

## Escape Rate

Escape rate is the rate at which defects, scope drift, missing tests, or operational issues are
found after the review or gate that should have caught them. It is a stronger quality signal than
the raw number of review findings.

Escape rate disciplines review behavior. A team with very few review findings but many escaped
issues is not reviewing effectively.

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

## Fresh Context

Fresh context is a review setup where the reviewer starts without inheriting the implementation
agent's session transcript, private reasoning, or broad chat history. The reviewer receives the
accepted authority documents, pinned revisions, implementation diff or artifact, test/UAT evidence,
traceability evidence, and explicit review questions.

Fresh context reduces the risk that the reviewer simply repeats the implementer's assumptions.

Fresh context does not mean no context. It means controlled context.

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

## Gate Cycle Time

Gate cycle time is the elapsed time between `gate_started_on` and `decided_on` in a structured gate
event. It measures how long a gate took from meaningful work beginning to a durable human decision.

Gate cycle time helps locate friction. It does not prove quality by itself. A fast gate may be
excellent or superficial; a slow gate may be careful or blocked.

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

## GenDev Lite

GenDev Lite is the lightweight C1 path through the methodology. It is used when work is contained,
reversible, non-sensitive, low-risk, and small enough that separate early artifacts would add cost
without improving decisions.

GenDev Lite may combine early gates or phase records, but it does not remove the required content.
A GenDev Lite project still needs durable statements of problem, users, requirements, architecture
assumptions, security assumptions, build scope, verification, approval, review, and close-out.

GenDev Lite should stop being Lite when blast radius changes. Examples include sensitive data,
external integrations, production automation, irreversible changes, or high operational impact.

## Goodhart Warning

The Goodhart warning is the caution that a metric can stop being useful when people or agents
optimize for the metric instead of the intended outcome. In GenDev, finding counts, cycle time, and
approval latency are signals, not goals.

Outcome metrics outrank activity metrics. A high review finding count does not automatically mean
good review quality. A low finding count does not automatically mean good implementation quality.
Escape rate, value review results, traceability samples, and missed criteria help discipline those
signals.

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

## Independent Review

Independent review is conformance review performed in a context separate from the implementation
context. The reviewer compares the implementation against accepted authority and evidence without
relying on the implementer session transcript or reasoning trace.

Independent review may still be performed by an AI agent. Independence comes from the review
context boundary, not from whether the reviewer is human or automated.

If implementation-session context is shared with the reviewer, the review report should record the
exception under context provenance.

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

It also records enforcement state: contract version, enforcement class, protected branch,
implementation paths, excluded paths, binding paths, attestation cadence, exceptions, and override
policy.

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

## Methodology Metrics

Methodology metrics are on-demand measurements derived from required GenDev records. The baseline
command is:

```bash
./scripts/methodology-metrics.sh docs/project
```

The project records are the data source. GenDev does not require a separate metrics database at
baseline.

## Metrics Snapshot

A metrics snapshot is the text report generated by `scripts/methodology-metrics.sh` and copied or
linked from phase close-out. The snapshot preserves the state of process telemetry at a meaningful
moment, usually G9 or production close-out.

Snapshots should not become a dashboard-writing exercise. They exist so future humans and agents can
see what the gate log, traceability matrix, enforcement records, and value review said at close-out.

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

## Override

An override is a deliberate, approved bypass of a methodology control. It exists for emergencies or
exceptional cases where blocking work would be more harmful than proceeding.

An override is not a silent skip. It should record who approved the override, why it was necessary,
which requirement was bypassed, what risk was accepted, how long the override applies, and how the
project will reconcile afterward.

Override records belong in `docs/project/approvals/gate-log.md` unless the project manifest names a
different durable record path.

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

## Process Telemetry

Process telemetry is evidence about how the methodology operated. Examples include gate cycle time,
approval latency, amendment frequency, regression count, traceability sample discrepancies, and
enforcement override count.

Process telemetry helps the team ask better questions. It is not a substitute for product judgment.

## Project Authority

Project authority is the active, durable source of truth for a product under `docs/project/`. It
includes accepted artifacts, approvals, traceability, decision records, and as-built documentation.

## Project Template

`docs/project-template/` is the initialization skeleton used by `scripts/init-project.sh`. It is not
the active project. It defines what a new `docs/project/` should look like.

## Protected Branch

The protected branch is the branch the project treats as authoritative project state. In many Git
repositories this is `master` or `main`.

GenDev does not require Git specifically, but it assumes the team has some version-control system
with immutable revisions, diffable changes, and branch or review boundaries. In the default Git
case, the protected branch should not receive agent-generated implementation changes that bypass
the configured enforcement or attestation process.

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

In the amendment context, reconciliation means reviewing downstream artifacts after accepted
authority changes. Reconciliation may update an artifact, confirm no change is required, mark an
artifact `Superseded`, or leave it `Stale` until later work.

## Reference Graph

The directed, acyclic, one-level graph formed by supporting-artifact references. A canonical gate
artifact references its supporting artifacts through its Supporting Artifacts section, using typed
relationships (`implements`, `satisfies`, `tested-by`, `constrained-by`, `refines`). Each type
declares a coherence obligation and which artifact holds authority. Cycles are forbidden. The graph
is the coherent context an AI coding agent walks to understand what it is building. (Constitution
Rule 12.)

## Regression

Regression is a formal move back to an earlier GenDev gate because an amendment invalidated gate
entry conditions.

Regression is not punishment and it is not a synonym for editing. It is a state correction. Use it
when the project can no longer honestly claim that a previously passed gate remains satisfied.

Examples:

- a PRD amendment requires a new architecture model, so the project regresses to G3;
- a governance/security amendment changes authorization behavior, so build authorization at G5 is
  no longer valid;
- a phase scope amendment invalidates the construction directive, so the project regresses to G5.

Do not regress for editorial amendments or clarifications that can be reconciled while the current
gate holds.

## Regression Event

A regression event is the structured gate-log record that captures a formal move from a later gate
to an earlier gate. It should record the source gate, target gate, reason, triggering amendment,
invalidated gate entry conditions, stale artifacts, required reconciliation, approver, date, and
manifest update state.

## Remediation

Remediation is the work of fixing review findings, adding missing tests, correcting scope drift, or
updating documentation after review. Remediation should address findings without broadening scope.

## Remediation Ratio

Remediation ratio compares findings fixed before acceptance with findings accepted as residual risk
or deferred. It is a review-quality and risk signal, not a productivity score.

At baseline, GenDev records enough review and close-out information to compute this more precisely
later. A team should avoid treating a high or low ratio as good without reading the underlying
findings.

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

## Revision Pinning

Revision pinning is the practice of recording the specific version of an upstream source used to
create or approve an artifact. In Git, the pinned revision is often a commit SHA, tag, branch
snapshot, pull request revision, or release identifier.

Revision pinning matters because GenDev artifacts depend on each other. If a PRD changes after an
architecture document was derived from an older PRD revision, the architecture may be stale. Without
the pinned revision, future agents cannot tell whether the architecture reflects the current PRD or
an earlier one.

Draft artifacts may use `TBD` until there is a durable revision to pin. Accepted gate evidence
should use a real revision when practical.

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

## Semantic Change

A semantic change alters the meaning of accepted authority. It may affect scope, requirements,
acceptance criteria, architecture, governance/security behavior, phase boundaries, tests,
deployment risk, or operational procedures.

Semantic changes require amendment classification. They should not be handled as ordinary editing
after an artifact is accepted.

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

## Stale

`Stale` is an artifact status meaning an upstream authority changed after the artifact pinned that
authority. The artifact may still contain useful information, but it should not support a gate
transition until it is reconciled.

Example:

```text
Architecture status: Stale
Derived from:
  - path: docs/project/prd/prd.md
    revision: old-prd-commit
```

Stale is different from superseded. A stale artifact may become current again after review confirms
that no changes are needed, or after the artifact is updated. A superseded artifact has been
replaced by newer accepted authority.

## Structural Amendment

A structural amendment changes accepted boundaries, behavior, risk, or approval criteria.

Examples:

- adding a new baseline requirement;
- changing acceptance criteria;
- changing architecture ownership or data model;
- changing authorization, audit, data sensitivity, or tool access;
- changing phase scope, migration behavior, rollback, or deployment risk.

Structural amendments require explicit human approval and downstream reconciliation. If they
invalidate gate entry conditions, they require regression.

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
approver, evidence path, evidence revision, evidence status, checked statement, accepted risks, and
next role or artifact.

Structured events are still human-readable, but they are also easier for future tools to validate.
They are the bridge between lightweight Markdown records and mechanical enforcement or metrics.

## Sub-Agent

A sub-agent is a bounded secondary agent used for specialized analysis or work. In GenDev,
sub-agents are advisory unless the human explicitly delegates a bounded write task and the lead
agent reconciles the output.

Good sub-agent tasks are bounded, source-aware, and review-oriented.

## Sub-Agent Budget

Sub-agent budget is the explicit effort limit for a sub-agent assignment. The budget may be stated
as time, tokens, dollars, number of review passes, or rough effort. The point is to prevent runaway
delegation and to keep the lead agent's synthesis useful to the human.

A budget does not tell a reviewer to ignore risk. It tells the reviewer when to stop and escalate
instead of continuing silently.

## Sub-Agent Budget Escalation

Sub-agent budget escalation is the condition where a sub-agent or lead agent must pause and ask the
human whether to continue, narrow scope, add another reviewer, or reclassify the project.

Examples:

- the assignment reaches its budget and material risk remains unresolved;
- the reviewer discovers C3-level exposure in a C1 or C2 project;
- the reviewer needs source authority outside the assignment;
- the review requires a different specialist;
- the amount of output would overwhelm the human without improving the decision.

## Supporting Artifact

A project-specific artifact produced by whatever analysis or design technique a project uses — a data
model, an object-interaction model, a state-transition model, a user-story set, a UX specification.
Supporting artifacts are not part of the canonical artifact set; they attach to a canonical gate
artifact through its Supporting Artifacts section as typed references. They are form-disciplined
(valid kebab-case filename, canonical location, required `project:` field, typed relationship) but
their content and name are determined by the technique, not the method. (Constitution Rules 12 and
13.)

## Superseded

Superseded means an artifact or decision has been replaced by a newer accepted artifact or decision.
Superseded documents should remain available for history but should not govern current work.

## Tactical Implementation Plan

The tactical implementation plan turns phase scope into executable workstreams. It defines tasks,
file/module ownership expectations, tests, verification commands, migration steps, and close-out
requirements.

It answers "how will this phase be implemented?"

## Technique Neutrality

A first-order principle of GenDev: the method governs how work earns authority and how that authority
is gated, reviewed, and kept coherent, but it does not specify how the work is conceived, modeled, or
built. The method fixes the form of an artifact (naming, location, references); the technique
determines its content. This is why object-oriented, data-driven, event-driven, and not-yet-invented
approaches all fit within GenDev: their artifacts enter through the same fixed
authority-and-reference discipline. Maxim: the method does not specify the technique, but the
technique must blend with the method.

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

## Traceability Coverage

Traceability coverage is the share of traceability rows that have reached verified status with test
or UAT evidence and review confirmation. It is one signal of whether requirements have been carried
through to implementation and validation.

Coverage is not useful if rows are invented after the fact or marked verified without evidence.

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

## Value Review

Value review is the post-deployment or post-value-event comparison of G1 success criteria against
actual evidence. Each due criterion should be reported as `met`, `missed`, or `unmeasurable`.

Value review keeps the project honest. It prevents the team from declaring success merely because
software was delivered.

## Value Review Trigger

A value review trigger is the event or date that tells the team when to read actuals against the G1
success criteria. Examples include "30 days after internal launch," "after ten completed customer
workflows," or "after the first renewal cycle completes."

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
