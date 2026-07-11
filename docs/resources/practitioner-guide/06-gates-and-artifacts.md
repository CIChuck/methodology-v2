# 06. Gates And Artifacts

## Purpose

This chapter explains how GenDev gates and artifacts work together. Gates (explicit lifecycle
checkpoints where the team decides whether the project is ready to move forward) define lifecycle
state (where the project sits in the overall process). Artifacts (durable project documents or
records) hold the durable content that proves the project is ready to advance. Evidence means the
specific documents, records, tests, reviews, or approvals that support a readiness claim.
G0 through G9 are shorthand labels for the ordered GenDev gates.

## Gate Status Versus Artifact Status

A gate and an artifact are related but not the same.

Artifact status (the readiness state of a document) describes a document:

```text
Draft
Ready for Review
Ready for Approval
Accepted
Stale
Superseded
Complete
```

Gate status (the readiness state of a lifecycle checkpoint) describes project movement:

```text
pending
drafting
ready_for_review
ready_for_approval
approved
blocked
superseded
```

An artifact may be `Ready for Approval` before the gate is approved. The gate becomes `approved`
only after human approval is recorded in durable project authority (accepted repository state that
future humans and agents should trust).

`Stale` means an upstream authority changed after the artifact recorded the revision it was derived
from. A stale artifact may still be useful context, but it should not support gate approval until it
has been reconciled. `Superseded` means the artifact has been replaced by newer accepted authority.
`Complete` is used for evidence artifacts such as review reports and close-out records.

Gate approvals should be recorded as structured gate-log events in
`docs/project/approvals/gate-log.md`. A structured event is a Markdown section containing a small
YAML block with the gate transition, decision, approver, evidence, accepted risks, and a `checked`
statement naming what the approver actually verified. Gate events should also name the enforcement
class (whether checks are mechanically enforced or human-attested) so future agents can understand
how the methodology controls were applied when the gate moved.

## Artifact Provenance

Provenance (the record of where an artifact came from) makes authority falsifiable. A future human
or agent should be able to tell who produced an artifact, when it was produced, whether an agent was
involved, and what upstream artifacts or prompts it depends on.

GenDev project artifacts use a lightweight header:

```text
Produced by: TBD
Produced on: YYYY-MM-DD
Produced with: human | agent | human-agent collaboration
Agent identity: TBD model/version/session, or N/A
Derived from:
  - path: docs/project/vision/vision.md
    revision: TBD
```

Revision pinning means recording the specific version of an upstream artifact used as input. In a
Git repository, this is usually a commit SHA, tag, or pull request revision. Draft work can use
`TBD`, but accepted gate evidence should be pinned when a durable revision exists.

When an upstream artifact changes, downstream artifacts that cite the old revision may become
`Stale`. The agent should stop, explain what changed, and ask whether to reconcile the downstream
artifact before using it as evidence.

## Amendment Versus Regression

Amendment is a controlled change to accepted authority while the current gate holds. Regression is a
formal move back to an earlier gate because the change invalidates gate entry conditions.

Use amendment when the project can stay oriented at the current gate while affected artifacts are
reviewed or updated. Use regression when the project no longer satisfies a gate it has already
passed.

Example:

```text
Current gate: G6
Change: Add a missing PRD acceptance criterion that fits existing architecture and phase scope.
Likely action: structural amendment to the PRD, mark tests and traceability stale, reconcile them,
then continue at G6.
```

Regression example:

```text
Current gate: G6
Change: Add a new requirement that requires a different data model and authorization behavior.
Likely action: regress to G3 or G4 because architecture and governance entry conditions are no
longer satisfied.
```

The practical question is:

```text
Can we reconcile the dirty subtree while the current gate holds, or did the change invalidate an
earlier gate decision?
```

## Canonical Naming and Supporting Artifacts

Per-project artifacts use fixed, role-based filenames that are the same in every
project: `vision.md`, `prd.md`, `architecture.md`, `phase-plan.md`, and so on. A
filename names the artifact's role, never the project. The project slug lives only
in `project.yaml`; it is never baked into a filename or a cross-reference path.
Every per-project authority artifact carries a `project:` front-matter field that
matches the slug in `project.yaml`. Because names are fixed, `AGENTS.md` and other
authority pointers reference artifacts by their canonical path, and those pointers
are correct for every project without per-project editing. (Constitution Rule 14.)

This follows from a deeper principle, Technique Neutrality: GenDev governs how work
earns authority and is gated, but it does not specify how the work is conceived,
modeled, or built. The method fixes the form of an artifact; the technique
determines its content. That is why naming is fixed (form) while what you put in a
data model or a state diagram is yours (content).

Because of that, the method does not enumerate every artifact a project might
produce. A project using a particular analysis or design technique will create
artifacts the canonical set does not name: a data model, an object-interaction
model, a state-transition model, a user-story set, a UX specification. These are
**supporting artifacts**. They attach to a canonical gate artifact through that
artifact's **Supporting Artifacts** section, as typed references:

```text
implements:     docs/project/design/order-model.md       - the entities this architecture builds on
satisfies:      docs/project/design/user-stories.md       - the stories this design fulfills
tested-by:      docs/project/testing/phase-1-test-uat-plan.md - what verifies this phase
constrained-by: docs/project/design/ux-spec.md            - the UX limits this must honor
refines:        docs/project/build-plan/phase-plan.md     - the slice this build plan details
```

Each reference carries a relationship type from a fixed vocabulary (`implements`,
`satisfies`, `tested-by`, `constrained-by`, `refines`). The type declares the
coherence obligation and which artifact holds authority. References run from the
canonical artifact to its supporters, form an acyclic graph (no cycles), and are
one level deep. Supporting artifacts obey the same form discipline as everything
else: a valid kebab-case filename, a canonical location, the required `project:`
field, and a typed relationship. However, their content and name are whatever the
technique calls for. (Constitution Rules 12 and 13.)

The point of this structure is to give an AI coding agent coherent, complete
context: the reference graph is what the agent walks to understand what it is
building. A dangling reference or a cycle is misleading context, which is why the
graph is disciplined.

## Blast-Radius Scaling

Blast-radius scaling means adjusting the amount of ceremony to the risk and exposure of the work.
The class belongs in `docs/project/project.yaml` under `scaling.blast_radius_class`.

Use:

- `C1 Contained` for internal tools, reversible outputs, no sensitive data, and low operational
  risk;
- `C2 Standard` for ordinary product work with moderate operational or data risk;
- `C3 Critical` for regulated data, irreversible actions, external integrations,
  production-sensitive automation, agentic runtime behavior, or high operational impact.

The class affects gate handling:

| Class | Practical gate handling |
| --- | --- |
| C1 | Early gates may be combined into one framing artifact if the artifact still contains the vision, requirements, architecture assumptions, security assumptions, and test expectations. |
| C2 | Use the full default chain unless the human records a specific reason to combine gates. |
| C3 | Do not combine gates; add stronger review, evidence sampling, enforcement, and production discipline. |

GenDev Lite means the C1 lightweight path. It is not permission to skip thinking. It is permission
to combine form when the risk is genuinely contained and the required content remains visible.

When gates are combined, record:

```text
affected gates
blast-radius class
justification
preserved content
approver
approval date
evidence path
```

The checker warns when combined gates appear without a recorded justification.

## Gate Overview

## G0: Project Initialized

G0 confirms that the baseline repository (the reusable GenDev repository before product-specific
setup) has been initialized for a specific product.

Primary evidence:

- `docs/project/project.yaml`;
- starter project folders;
- rendered artifact templates;
- declared enforcement class and attestation cadence;
- current gate set to G1.

Human approval is not required unless initialization overwrote existing project state (existing
product-specific files or manifest values).

## G1: Vision Ready

G1 establishes why the product exists and what success means.

Primary artifact:

```text
docs/project/vision/vision.md
```

The vision should define:

- problem statement;
- target users;
- user pain or opportunity;
- desired outcomes;
- success criteria with a measure, target, read timing, owner, and evidence source;
- non-goals (things the team is explicitly choosing not to build now);
- assumptions (beliefs being used for planning before they are proven);
- risks;
- open questions.

Do not let the agent turn G1 into an implementation plan. The vision explains the problem and
success conditions. It does not authorize code.

## G2: Requirements Ready

G2 converts the vision into testable product requirements (specific product behaviors and
constraints that can be reviewed and tested).

Primary artifact:

```text
docs/project/prd/prd.md
```

The PRD should define:

- product objective;
- stable requirement IDs;
- functional requirements (what the product must do);
- non-functional requirements (qualities such as performance, reliability, security, or
  maintainability);
- primary workflows;
- edge cases (unusual but plausible inputs, states, or user actions);
- out-of-scope behavior;
- deferred items;
- dependencies;
- security and governance requirements;
- observability and audit requirements;
- testability notes.

The PRD is ready only when baseline requirements have observable acceptance criteria (conditions
that prove a requirement is satisfied). For C2 and C3 projects, those criteria are written in EARS
form (the Easy Approach to Requirements Syntax), five sentence shapes that make a criterion
structurally a test rather than a sentence open to interpretation:

```text
Ubiquitous:  The system shall <response>.                      (always true)
Event:       When <trigger>, the system shall <response>.      (triggered)
State:       While <state>, the system shall <response>.       (state-bound)
Unwanted:    If <condition>, then the system shall <response>. (error or negative path)
Optional:    Where <feature>, the system shall <response>.     (feature-conditional)
```

The value of EARS is that "When a claim is submitted, the system shall validate the member ID"
converts to a test with no reinterpretation: trigger the event, assert the response. It also forces
the error paths into the open, because the unwanted-behavior shape is a named slot that is visibly
empty when you have only written the happy path. A small contained project (C1) may use plain
observable criteria instead, but the moment a requirement has real failure modes, the discipline
earns its keep. EARS governs form, not correctness: a criterion can be perfectly shaped and still
wrong, which is why a human still approves the requirements. It only guarantees the criterion is
precise enough to be worth approving and to become a test later without a second act of
interpretation.

## G3: Architecture Ready

G3 defines system structure (how the product is organized technically and where boundaries exist).

Primary artifacts:

```text
docs/project/architecture/architecture.md
docs/project/decisions/0001-technology-stack.md
```

The architecture should define:

- terminology and domain model (the important product concepts and how they relate);
- system boundaries (what the system owns and what it depends on externally);
- component responsibilities;
- runtime model;
- data model;
- lifecycle and state transitions (how important records or workflows move from one state to
  another);
- interfaces;
- failure behavior;
- technology stack decision;
- deferred architecture;
- a verification specification;
- a design-verification interrogation.

Implementation should not need to invent core structure after G3.

The last two items are where Verification First (Chapter 02) becomes concrete. The **verification
specification** takes the G2 acceptance criteria and records, for each requirement, how it will be
proven correct across the three questions (behavioral, design, implementation) plus the
user-acceptance scenario. Its defining property is the approval: a human signs off on this
specification as a faithful encoding of intent, separately from and before any code exists, and
that approval is what later lets the build loop grade code against an approved standard rather than
against the agent's reading of the prose. The evidence itself (test results, reports) does not live
here; it attaches later as a supporting artifact through a typed reference. How this specification
drives the build loop, and how its evidence is gathered during implementation, is covered in
Chapter 09.

The **design-verification interrogation** is the design question asked on paper, before code can
hide the answer. Proportional to blast radius, it records what failure modes the design must survive
(partition, network loss, crash and restart, resource exhaustion), where it might not scale, where
it might paint the project into an evolutionary corner, and what happens when a security boundary it
relies on fails. A C1 project may answer briefly, including an honest "no failure modes beyond
single-process operation." A C3 project expands each into real analysis. The point is that the
questions are asked and answered while the design is still cheap to change, not discovered in an
incident.

## G4: Governance Ready

G4 makes security, policy, identity, audit (records of important events), and agent/tool behavior
explicit.

Primary artifact:

```text
docs/project/security-governance/governance-security-spec.md
```

The specification should define:

- identity model;
- roles and permissions;
- authorization rules (what each actor is allowed or forbidden to do);
- approval model;
- audit model;
- secrets handling (how credentials, tokens, and private configuration are protected);
- data sensitivity (how confidential or regulated the data is);
- trust boundaries (places where data or control crosses between actors, systems, or privileges);
- external tool rules (limits on tools, services, or integrations outside the repository);
- agent stop conditions (situations where the agent must pause and ask the human);
- security and negative tests.

G4 is especially important for products with users, sensitive data, automation, integrations, or
production deployment.

## G5: Build Ready

G5 ratifies the phase partition: it certifies the phase plan that governs how the
build proceeds. The implementation itself happens in the phase loop interior to
the G5 to G6 span (the G5.x checkpoints).

Primary artifact:

```text
docs/project/build-plan/phase-plan.md
```

The per-phase build plan, tactical implementation plan, construction directive,
and build prompt are produced at the interior checkpoints, not at G5. See
docs/methodology/guides/phase-loop.md.

The build-ready state should define:

- phase scope;
- non-goals;
- workstreams (groups of related implementation tasks);
- file or module ownership expectations;
- verification commands (commands that prove the work builds, tests, or checks correctly);
- UAT expectations (user acceptance testing expectations);
- migration and rollback implications (data or release changes and how to reverse them if needed);
- documentation close-out requirements (docs that must be updated after work is complete).

No meaningful implementation should begin before G5 unless the human explicitly decides to bypass
the methodology for a throwaway experiment.

## G6: Implementation Ready For Review

G6 means implementation work is complete enough for conformance review (checking the work against
accepted authority rather than personal taste).

Evidence should include:

- implementation summary;
- changed files;
- tests added or updated;
- verification commands run or skipped with reasons;
- enforcement or attestation evidence required by the project enforcement block;
- known deviations (places where the implementation differs from the accepted plan).

G6 does not mean the work is accepted. It means the work is ready to be reviewed against authority.

## G7: Acceptance Ready

G7 decides whether implementation can be accepted after review and remediation (fixing review
findings or explicitly accepting the remaining risk).

Required evidence:

- code review report;
- remediation summary, if findings existed;
- passing verification evidence or accepted exceptions;
- enforcement or attestation evidence for required methodology checks;
- test/UAT evidence;
- updated traceability matrix;
- residual risk statement (the risk that remains after remediation).

Human approval is required for phase acceptance and for accepting critical or major residual risk.

## G8: Deployment Ready

G8 confirms that the accepted product state can be deployed or released (moved into an operating
environment).

Required evidence:

- release scope;
- deployment target;
- configuration and secrets expectations;
- migration plan;
- rollback plan (how to return to a previous known-good state if deployment fails);
- operational checks (checks an operator performs before or after release);
- monitoring plan (how the team will observe health, errors, and important signals);
- deployment approval;
- post-deployment owner.

Deployment approval is separate from implementation acceptance.

## G9: As-Built Closed

G9 preserves the implemented and operational state for future work.

Required evidence:

- as-built close-out;
- updated docs;
- known limitations;
- deferred backlog (items intentionally postponed for later work);
- final traceability update;
- metrics snapshot or explicit deferral;
- value review status, if production or measurable value occurred;
- production status, if deployed;
- next phase or operational follow-up.

The project is not truly done until future agents can understand the actual state without relying on
chat history.

## Practitioner Rule

At each gate, ask:

```text
What artifact proves readiness?
What revision of that artifact am I relying on?
Is any required evidence stale or superseded?
Is there an active amendment or regression that affects this evidence?
What human approval is required?
What did the approver actually check?
What enforcement class applies, and what attestation or enforcement evidence exists?
What blast-radius class applies, and is any gate combination justified?
What measurement or value-review evidence is now due?
What risk is being accepted?
What happens next?
```

## 0.5 Operational Coherence Notes

The current lifecycle has two layers. G0 through G9 remain the only gates. The `G5.x` addresses are
checkpoints inside the G5-to-G6 phase loop; they are not new gates and they do not create a
separate approval ceremony unless the active project records one.

G5.0 accepts the aggregate phase plan. Each implementation phase then moves through its own
checkpoint ladder:

```text
G5.<phase>.1 phase build plan
G5.<phase>.2 tactical implementation plan with stable workstream/task IDs
G5.<phase>.3 construction directive and issued build prompt
phase implementation and phase evidence
phase review, remediation disposition, traceability update, and per-phase as-built record
```

Only after every declared live phase has exited can the project move from G5 to G6. G6 is aggregate
whole-build review readiness. G7 is aggregate final acceptance after review and remediation. G8 is
release or non-deployment readiness. G9 is terminal as-built close-out.

Coverage is project-declared, not a universal percentage. The coverage contract names the
requirements, verification criteria, phases, tests, UAT evidence, and review evidence required for
the project. Supporting artifacts must be referenced with typed target kinds such as `implements`,
`satisfies`, `tested-by`, `constrained-by`, or `refines`, and the referenced artifact must exist at
the declared target kind.

For G2, C2 and C3 projects use EARS-form acceptance criteria. C1 projects may use plain observable
criteria when the work is genuinely contained, but every class still records unwanted behavior for
failure and abuse paths where those paths exist. G3 must convert those criteria into a
human-approved verification specification with stable criterion IDs before implementation planning
uses them.
