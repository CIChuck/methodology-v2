# AI-Assisted Software Engineering Documentation Constitution

Status: Reusable Standard  
Version: 1.0.2
License: CC BY 4.0 for documentation; see repository `LICENSE`.
Audience: Product owners, architects, engineering leads, AI-assisted coding operators, reviewers, and implementation agents  
Scope: Documentation, traceability, build governance, testability, and AI-assisted implementation process for software projects

## Purpose

This constitution defines a reusable documentation-first engineering method for building reliable, testable software with AI-assisted software engineering tools such as Codex, Claude Code, or similar implementation agents.

The method exists to ensure that software is not built from vague intent, chat history, or isolated prompts. It requires a traceable chain from vision to requirements, architecture, implementation planning, code generation, testing, review, remediation, and as-built documentation close-out.

The core objective:

```text
build software from explicit authority,
verify it against testable requirements,
preserve traceability from intent to implementation,
and prevent AI-assisted phase drift.
```

## Core Principle

No meaningful implementation should occur unless the implementer, human or AI, can answer:

```text
what are we building?
why are we building it?
who is it for?
what is in scope?
what is out of scope?
what architecture governs it?
what security and governance rules apply?
what tests prove it works?
what documentation must be reconciled when complete?
```

If those answers are not documented, the project is not ready for code generation.

## Technique Neutrality

This is a first-order principle of the methodology. The rules that follow —
canonical naming, the documentation scaffold, the supporting-artifact mechanism,
and the reference discipline — are its consequences.

GenDev governs how work earns authority and how that authority is gated,
reviewed, and kept coherent. It does not specify how the work is conceived,
modeled, or built. The method is the authority-and-gate machinery; the technique
is everything about how a team designs and constructs — object-oriented,
data-driven, event-driven, or an approach not yet invented. The method must not
couple itself to a technology stack or to a software-engineering approach.

The blend point is the artifact. A technique's artifacts enter the methodology
through a fixed authority-and-reference discipline: they are named, located,
provenanced, and referenced by the method's rules, and because they obey that
discipline the method can gate and coherence-check them without knowing which
technique produced them. The method is opinionated about how an artifact earns
authority; it is silent about what the artifact contains.

Stated as a maxim: the method does not specify the technique, but the technique
must blend with the method.

Every other rule in this constitution that concerns artifact structure,
naming, scaffolding, or references must remain consistent with this principle. A
future rule that couples the method to a specific technology stack or engineering
approach violates it.

## First Principles of Code Quality

This is a first-order principle of the methodology, and a deliberate complement
to Technique Neutrality. Technique Neutrality states what the method is silent
about: how the work is conceived, modeled, and built. This principle states what
the method is not silent about: six properties the produced code must have,
whatever technique produced it.

These six are constitutional, not technical. They do not tell a builder how to
design or which pattern to reach for. They state properties the result must hold
regardless of how it was built, the same way "the architecture must cohere with
the PRD" is a property of the result and not a technique for producing it. They
sit on the method side of the Technique Neutrality line, alongside blast radius
and accountability, not on the technique side alongside object-oriented or
data-driven design.

The six:

```text
YAGNI  You Aren't Gonna Need It. Build only what a current, approved requirement
       asks for. Do not build for a requirement that does not yet exist.
KISS   Keep It Simple. The simplest structure that satisfies the requirement is
       the correct one, not the most general or most extensible.
DRY    Don't Repeat Yourself. Logic that already exists is called, not rewritten.
SRP    Single Responsibility. Each unit does one coherent job.
LA     Least Astonishment. Behavior matches what an obvious reading of the
       requirement would lead a reader to expect.
NAA    No Undeclared Abstractions. Any authority-bearing abstraction the build
       introduces must already be declared in approved upstream authority or be
       introduced through an amendment before use. A build implements the
       approved model. It does not silently expand behavior, authority boundaries,
       or trust model.
```

These principles exist because a generator, left unconstrained, violates all six
by default. Verbosity, over-generalization, duplication, conflated
responsibilities, surprising behavior, and unrequested abstraction are the
standing tendencies of machine generation, not occasional lapses. A test suite
does not catch them, because all six can be present in code that passes every
test. The method therefore states them explicitly and binds them at the points
where generation happens.

The binding mechanism follows from this. These six are restated in full in every
construction directive's anti-drift section, at the point of generation, every
phase, without exception. They are checked at code review by a conformance
reviewer operating under the reviewer-independence rule.

For this methodology, NAA applies to authority-bearing abstractions:

```text
domain or business concepts and rules
persisted, shared, externally exchanged, or security-sensitive fields
public, externally consumed, or cross-component interfaces
architectural boundaries (components, services, storage, ownership)
trust, identity, authorization, audit, data sensitivity, and lifecycle control
```

A build may add implementation-local detail without amendment only when the build
task already authorizes it and all of these conditions hold:

```text
it is private to a component or test scope
it does not add product behavior, policy, or observable semantics
it does not add shared, persisted, or externally exchanged state
it does not add or alter public or cross-component contracts
it does not change acceptance, governance, or phase boundaries
it is proportionate under YAGNI, KISS, DRY, and SRP
```

Typical allowed categories are private helpers, local adapters, internal value
types, framework-generated types, test fixtures, fakes, and mocks.

Every other rule in this constitution that concerns what a build produces must
remain consistent with these six.

## Applicability

Use this standard for:

```text
new product development
feature phases
large refactors
security-sensitive systems
agent platforms
governance or permission subsystems
CLI-first UAT projects
AI-assisted implementation workflows
projects where traceability and testability matter
```

This standard may be scaled down for small work, but the traceability chain should not be abandoned.

## Verification-First Principle

A project must define how it will know the work is correct before it builds the work, and a human
must approve that definition of correctness in a form precise enough to test. Verification is a
design input, not a downstream check. This principle is the reason "what tests prove it works?" is
one of the questions the Core Principle requires answered before code generation.

Verification answers three distinct questions. They are exhaustive: there is nothing to verify
outside the requirement, the design, and the code.

```text
behavioral:     does the implementation do what is required, including the negative and edge
                cases, not only the happy path? (user acceptance is the user-facing slice)
design:         does the design hold under the conditions it must survive (partition, network
                loss, security boundary, degradation, scale, evolution)? this is evaluable the
                moment the design is written, before any code exists
implementation: is the code sound as an artifact and durable under change (correct types and
                contracts, no brittle assumptions that erode over time)?
```

What unifies the three is that each asks whether the work is correct under conditions the happy
path does not reveal: the requirement's edges, the design's failure modes, and time.

Verification-First is a methodological commitment, not a technique. The method requires the
verification and gates it; it does not prescribe how the verification is produced. Test-driven,
behavior-driven, acceptance-test-driven, property-based, and classic test-after development are
techniques, and the method stays neutral on them under the same reasoning as Technique Neutrality.
The philosophy is methodology; the practice is technique. The maxim: define how you will know it
works before you make it work.

This standard scales with blast radius (a small project may answer the three questions briefly,
including an honest "no failure modes beyond single-process operation"), but the questions should
not be left unasked.

## Blast-Radius Scaling Principle

GenDev ceremony scales with the blast radius of the work. Blast radius means the plausible impact
of a wrong requirement, bad implementation, unsafe deployment, missed review finding, or agent
misstep.

Every initialized project should declare a blast-radius class in `docs/project/project.yaml`:

```text
C1 Contained
  Internal tools, reversible outputs, no sensitive data, low operational risk.

C2 Standard
  Default product work, moderate operational or data risk, ordinary production release discipline.

C3 Critical
  Regulated data, irreversible actions, external integrations, production-sensitive automation,
  agentic runtime behavior, or high operational impact.
```

Scaling down is legitimate only when required content remains explicit. A C1 project may combine
early gates or artifacts, but it must still define the problem, requirements, architecture
assumptions, security assumptions, build plan, verification, approval, and close-out evidence.
Scaling down does not waive production approval, rollback thinking, or security assumptions when
the product is deployed or touches meaningful data.

Scaling up is mandatory when exposure increases. A C3 project should not combine lifecycle gates.
It should use stronger independent review, evidence sampling, explicit override discipline, and
stricter enforcement than the baseline.

Gate combination must be recorded with a justification, class, affected gates, preserved content,
approver, and evidence path. If the justification is missing, the methodology treats the combined
gate path as a process risk, not as an informal shortcut.

## Version-Control Assumption

This methodology assumes a version control system with immutable revision identifiers, diffable
history, and branch isolation. Git is the default implementation, but any system with equivalent
properties can support the methodology.

Revision control is not incidental. Provenance, amendment, review independence, enforcement, and
as-built close-out all depend on being able to identify what changed, when it changed, and what
authority governed the change.

## Constitutional Rules

### Rule 1: Documentation Is Build Authority

AI-assisted implementation must be grounded in authoritative documents.

Implementation prompts must cite or summarize the relevant authority:

```text
vision or product goal
PRD requirements
architecture specification
governance/security rules
phase build plan
tactical implementation plan
acceptance criteria
test expectations
documentation close-out requirements
```

The AI builder must not infer new product scope from casual conversation unless the operator explicitly authorizes that change and updates the relevant documentation.

### Rule 2: Traceability Is Mandatory

Every material requirement must map forward to implementation and verification.

Minimum traceability chain:

```text
requirement
  -> architecture rule or design decision
     -> build-plan scope item
        -> tactical implementation task
           -> test or UAT evidence
              -> code review confirmation
                 -> as-built documentation update
```

If a requirement cannot be traced to a test or UAT check, it is not yet implementation-ready.

### Rule 3: Verification Is a Design Input

As a consequence of the Verification-First Principle, tests and other verification are planned
before or during architecture and tactical planning, not treated as cleanup after code generation.

Architecture and implementation plans should identify:

```text
unit tests
integration tests
security tests
negative tests
migration tests
CLI/UAT scenarios
fixture requirements
acceptance scripts
manual verification steps when automation is not practical
```

The absence of tests must be explicit and justified.

### Rule 4: Security and Governance Are First-Class

Security, governance, identity, permission, audit, and policy behavior must be documented early.

Any system involving agents, tools, automation, workflow execution, file access, external APIs, user data, secrets, or persistent state must define:

```text
identity model
authorization model
permission boundaries
policy boundaries
approval requirements
audit records
failure behavior
revocation or deactivation behavior
data retention and sensitivity rules
observable side effects
```

These rules must be testable.

### Rule 5: Phase Boundaries Must Be Defended

Phase plans must define:

```text
in scope
out of scope
deferred features
non-goals
migration boundaries
acceptance criteria
documentation close-out
```

AI builders must not smuggle deferred features into the current phase.

If a deferred feature appears necessary, stop and update the plan before implementation continues.

### Rule 6: AI Build Prompts Are Controlled Artifacts

Prompts used to drive implementation are build artifacts.

They must be:

```text
precise
bounded
traceable to authority
explicit about non-goals
explicit about tests
explicit about migration behavior
explicit about documentation close-out
clear about what files or subsystems may change
clear about what must not change
```

Construction directives and large implementation prompts must be preserved with the directive text,
implementing agent identity when known, source authority revisions, and the resulting commit, diff,
or implementation reference. Implementation whose controlling directive cannot be produced is
treated as unreviewed until a human reviewer reconstructs and accepts the authority record.

### Rule 7: Code Review Verifies Conformance

Code review must evaluate whether the implementation matches the documentation authority.
Conformance review must be performed in a context independent of the implementation context.

Reviewer independence means the reviewer starts from:

```text
authority documents at pinned revisions
implementation diff or artifact under review
applicable test and UAT evidence
```

The reviewer should not receive the implementation agent's session transcript, private reasoning,
or broad conversational history unless the exception is explicitly justified in the review report.
The review should record context provenance so future humans and agents can see what the reviewer
was given and what was intentionally excluded.

Review must check:

```text
requirement conformance
architecture conformance
security/governance conformance
test completeness
CLI/UAT completeness
error handling
migration behavior
deferred-feature boundaries
documentation drift
engineering quality
```

Review findings should produce traceable remediation work.

### Rule 8: Remediation Must Be Precise

Remediation prompts or plans must map directly to findings.

Each finding should have:

```text
finding id
severity
affected requirement or architecture rule
affected files or modules, if known
required correction
required tests
acceptance criteria
documentation update, if needed
```

Remediation should not introduce unrelated scope.

### Rule 9: As-Built Documentation Is Definition of Done

A phase is not complete until documentation reflects what was actually built.

Close-out must reconcile:

```text
developer guides
architecture docs
CLI docs
configuration docs
API docs
examples
schema references
implemented-vs-planned status
deferred-feature lists
known limitations
test evidence
```

If the implementation differs from the plan, the documentation must say so.

### Rule 10: Decisions Must Be Durable

Important decisions must not live only in chat history.

Record:

```text
decision
rationale
alternatives considered
selected option
scope impact
test impact
security impact
deferred implications
date
owner or approver, when applicable
```

### Rule 11: The Documentation Scaffold Is Canonical and Architecture-Independent

The documentation scaffold — the docs/project/ directory tree and the canonical
filenames within it — is fixed and identical for every project, regardless of
technology stack or engineering approach. It is a consequence of Technique
Neutrality: the method owns how work is documented and gated, so the documentation
structure is the method's to fix.

The code scaffold — source layout, package structure, module organization — is
architecture-determined. The method does not prescribe it. The method only records
it, through the technology-stack decision artifact
(docs/project/decisions/0001-technology-stack.md) and the implementation_paths
field in the project manifest. This is the seam between the canonical documentation
layer and the technique-specific code layer: the method records where code lives so
tooling can reason about it, without dictating where code goes.

### Rule 12: Supporting Artifacts Attach Through a Typed, Acyclic Reference Graph

Canonical gate artifacts may reference project-specific supporting artifacts
(produced by whatever analysis or design technique a project uses — a data model,
an object-interaction model, a state-transition model, a user-story set, a UX
specification) through a Supporting Artifacts section. The references form a
directed acyclic graph rooted at canonical gate artifacts:

```text
the graph is rooted at canonical gate artifacts; a canonical artifact holds the
  Supporting Artifacts section and names the supporting artifacts it references, so
  edges run from the canonical (referencing) artifact to the supporting
  (referenced) artifact
cycles are forbidden and must be flagged
references are one level deep by default; supporting artifacts do not themselves
  carry supporting-artifact references, and greater depth is a declared, justified
  exception
```

Edge topology and authority direction are distinct. Topology is fixed: the
canonical artifact references the supporting artifact. Authority direction depends
on the relationship type below: for some types the referencing (canonical) artifact
is the one obligated to conform to the referenced artifact, and for others the
reverse. Each type states explicitly which artifact holds authority, so the
coherence obligation is unambiguous regardless of which end holds the reference.

Each reference carries a relationship type from this bounded vocabulary. In every
case the referencing artifact is the canonical gate artifact, and the referenced
artifact is the supporting artifact it names. The type declares the coherence
obligation and which end holds authority:

```text
implements     - the referencing artifact realizes a structure the referenced
                 artifact defines. Authority: the referenced artifact. Obligation:
                 every named element in the referencing artifact resolves to a
                 definition in the referenced artifact.
satisfies      - the referencing artifact fulfills requirements the referenced
                 artifact states. Authority: the referenced artifact. Obligation:
                 every requirement in the referenced artifact is covered by the
                 referencing artifact.
tested-by      - the referencing artifact's correctness is verified by the
                 referenced test artifact. Authority: the referencing artifact (the
                 test serves it). Obligation: the referenced test artifact exists,
                 covers the referencing artifact's claims, and passes.
constrained-by - the referencing artifact must not violate limits the referenced
                 artifact sets. Authority: the referenced artifact. Obligation: the
                 referencing artifact contains nothing the referenced artifact
                 forbids.
refines        - the referencing artifact adds detail within the scope the
                 referenced artifact sets. Authority: the referenced artifact.
                 Obligation: the referencing artifact stays within the referenced
                 artifact's scope, adding detail without contradicting or expanding
                 it.
```

The provenance relationship (which canonical artifact an artifact descends from)
is handled separately by the Derived from provenance header and is not part of this
vocabulary.

The purpose of this structure is to present coherent context to an AI coding
assistant: the reference graph is the context an agent walks to understand what it
is building, and a cycle or a drifted reference is misleading context.

### Rule 13: Supporting Artifacts Are Form-Disciplined and Content-Free

The method constrains the form of a supporting artifact, not its content or name —
a direct consequence of Technique Neutrality.

```text
form (method-governed):
  filename is a valid lowercase-kebab identifier (no spaces, quotes, or slashes;
    .md extension)
  the artifact lives at the canonical supporting-artifact location in the locked
    scaffold
  it carries the required project front-matter field and its typed relationship to
    what it supports
content and name (technique-governed):
  the artifact is whatever the technique requires, named whatever the technique
    calls it, within the form constraint
```

Identity is the typed reference edge plus front matter, not the filename; a
supporting artifact may be renamed freely as long as the reference pointing at it is
updated. The authoritative form of a supporting artifact is textual; diagrams are
embedded (for example Mermaid) or referenced from authoritative text, so the
artifact stays diff-able and coherence-checkable.

### Rule 14: Canonical Artifact Naming

Per-project artifacts use fixed, role-based filenames that are identical across all
projects. A filename identifies an artifact's role (vision.md, prd.md,
architecture.md, phase-plan.md), never its project. This is a consequence of
Technique Neutrality: the method fixes the form by which an artifact is named and
referenced, so that authority pointers resolve identically for every project.

```text
the project slug and project name must not appear in any artifact filename or in
  any cross-reference path between artifacts; cross-references use the fixed
  canonical paths
the slug must not be baked into filenames or cross-reference paths; it lives as a
  field in docs/project/project.yaml and is echoed only as the artifact identity
  field below
project identity is carried by location (the docs/project/ tree and the
  repository), by project.yaml, and by a strictly required front-matter field,
  project: <slug>, on every per-project authority artifact (every gate artifact,
  supporting artifact, and the gate log; navigational index files such as
  directory README.md files are exempt)
the project front-matter field must be present and must match the slug in
  project.yaml; it is a checkable provenance claim, not decoration
authority pointers, including AGENTS.md, reference canonical artifacts by their
  fixed full path; because names are project-independent, a single pointer is
  correct for all projects and requires no per-project maintenance
```

Scaling down a small project may combine or omit content (per the Blast-Radius
Scaling Principle), but it does not float artifact names: a combined or reduced
artifact still uses its canonical role-based name. Naming is fixed independently of
how much content a project's gates carry.

## Documentation Artifact Chain

The standard documentation chain is:

```text
1. Vision / Problem Framing
2. Product Requirements Document
3. Architecture Specification
4. Governance and Security Specification
5. Phase Plan (the build partition; certified at G5)
   The following are produced per phase inside the phase loop (G5.x checkpoints):
6. Phase Build Plan
7. Tactical Implementation Plan
8. Construction Directive / Build Prompt
9. Test and UAT Plan (the phase exit test is specified in the phase build plan)
10. Implementation Evidence
11. Code Review Report
12. Remediation Plan / Remediation Prompt
13. Phase Learnings
14. As-Built Documentation Close-Out
15. Traceability Matrix
```

The phase plan partitions the build into ordered, independently testable phases
and is what G5 certifies. Artifacts 6 through 13 are produced for each phase in
the loop interior to the G5 to G6 span. See docs/methodology/guides/phase-loop.md.

Not every project needs every document as a separate file. For small projects, multiple artifacts may be combined. The required content must still exist.

## Artifact Provenance

Authority and evidence artifacts must identify their origin. A future human or agent should be able
to determine who produced the artifact, when it was produced, whether an agent participated, and
which upstream documents or prompts it was derived from.

Minimum provenance fields:

```text
Produced by
Produced on
Produced with
Agent identity
Derived from path and revision
```

Revision values should be immutable identifiers where practical, such as a commit SHA, tag, pull
request revision, signed release, or other durable artifact identifier. Draft artifacts may use
`TBD` until the upstream source is committed or otherwise pinned.

If an upstream authority changes after an artifact pins that authority, the downstream artifact is
`Stale` until reviewed and reconciled. Stale artifacts may remain useful context, but they should
not be used as gate evidence without explicit reconciliation.

## Authority Amendment And Regression

Accepted authority may be amended when the project learns something material. The methodology does
not require teams to pretend that accepted artifacts are immutable. It requires teams to make the
cost of change visible.

Amendment cost scales with blast radius:

```text
editorial change
  -> record if useful; no re-approval
additive-within-scope change
  -> lightweight approval and downstream review
structural change
  -> explicit approval and downstream reconciliation
gate-invalidating change
  -> formal regression to the affected gate
```

An amendment must identify affected downstream artifacts, traceability rows, plans, tests, reviews,
implementation evidence, deployment evidence, or close-out records. Downstream artifacts that may no
longer match amended authority must be marked `Stale` until reconciled or `Superseded` if replaced.

Unamended stale authority is a methodology violation. It is not permission for agents to infer new
scope, reinterpret architecture, bypass security/governance rules, or continue a gate transition
using evidence known to be stale.

## Enforcement Principle

Methodology rules should be enforced where practical, attested where enforcement is unavailable,
and declared in the active project control plane.

Projects must state their enforcement class in `docs/project/project.yaml`:

```text
enforced
attested
```

`enforced` means a mechanical binding exists, such as hooks, protected-branch checks, policy
automation, or equivalent controls. `attested` means a named human performs or reviews the required
checks on a declared cadence and records attestation in the gate log.

Attested mode is valid at baseline. It must not become invisible. Exceptions, cadence, required
attester, override policy, and binding paths belong in the project enforcement block. The active
contract is `docs/methodology/guides/enforcement-contract.md`.

## Measurement Principle

GenDev projects should emit enough evidence to test whether the methodology is reducing drift,
rework, approval delay, and escaped defects. Measurement must be derived from artifacts this
constitution already requires: gate-log events, approvals, traceability, review results, as-built
records, enforcement overrides, and value reviews.

Measurement must not become a separate bureaucracy. At baseline, metrics are computed on demand
from project records, and phase close-out may snapshot the generated report. Outcome metrics outrank
activity metrics. A high finding count is not automatically good, a low finding count is not
automatically good, and success criteria cannot be redefined after delivery to make the project look
successful.

Every G1 vision must define success criteria with a measure, target, read timing, owner, and
evidence source. Production or value-bearing releases must eventually report those criteria as
`met`, `missed`, or `unmeasurable`.

## Required Artifact Definitions

### Vision / Problem Framing

Purpose:

```text
define why the project or phase exists
```

Must include:

```text
problem statement
target users
desired outcomes
success criteria
non-goals
strategic constraints
major risks
```

Completion standard:

```text
the team can explain why the work matters and what success looks like
```

### Product Requirements Document

Purpose:

```text
define product-visible requirements and acceptance boundaries
```

Must include:

```text
user goals
functional requirements
non-functional requirements
acceptance criteria
primary user workflows
edge cases
out-of-scope behavior
dependencies
open questions
```

Completion standard:

```text
requirements are specific enough to become architecture and test cases
```

### Architecture Specification

Purpose:

```text
define system structure, ownership, behavior, and boundaries
```

Must include:

```text
terminology
domain model
component ownership
runtime model
data model
state lifecycle
interfaces
error behavior
security-sensitive boundaries
extension points
deferred architecture
diagrams where useful
```

Completion standard:

```text
implementation cannot reinterpret major object ownership or lifecycle behavior
```

### Governance and Security Specification

Purpose:

```text
define how the system remains safe, auditable, and controlled
```

Must include:

```text
identity model
roles and permissions
authorization rules
policy model
approval model
audit model
secrets handling
data sensitivity
trust boundaries
threat scenarios
security tests
failure and recovery behavior
```

Completion standard:

```text
security-sensitive behavior is explicit, testable, and not left to implementation inference
```

### Phase Plan

Purpose:

```text
partition the build into ordered, independently testable phases; this is the
artifact that gate G5 certifies
```

Must include:

```text
the ordered phase sequence, each phase identified by a stable label
a requirement coverage map assigning every in-scope requirement to an owning phase
cross-phase rules and invariants
the partitioning rationale, including the sizing criterion
integration criteria and who declares the integration tests
an amendments section for later phase insertions and splits
```

Completion standard:

```text
the build is partitioned into ordered, independently testable phases, every
in-scope requirement is assigned to a phase, and integration criteria are
declared
```

Note: phase order is defined by this plan, never computed from the phase label.
The per-phase build plan, tactical plan, construction directive, build prompt,
and learnings are produced inside the phase loop at the interior G5.x
checkpoints. See docs/methodology/guides/phase-loop.md.

### Build Definition

Purpose:

```text
define the buildable unit of work and its authority
```

Must include:

```text
scope
source authority documents
feature boundaries
implementation constraints
deferred items
required test categories
documentation close-out requirements
```

Completion standard:

```text
the team knows what this build may and may not implement
```

### Phase Build Plan

Purpose:

```text
sequence the build into a manageable phase
```

Must include:

```text
phase objective
phase scope
out-of-scope items
dependencies
implementation workstreams
risk areas
test strategy
CLI/UAT strategy, if applicable
migration strategy
acceptance criteria
documentation close-out
```

Completion standard:

```text
the phase is bounded and can be converted into tactical implementation work
```

### Tactical Implementation Plan

Purpose:

```text
convert phase intent into executable implementation work
```

Must include:

```text
workstreams
file/module ownership expectations
data/schema changes
API/CLI changes
migration order
test plan
negative tests
acceptance criteria
verification commands
rollback or reset considerations
documentation close-out
accuracy pass findings
```

Completion standard:

```text
an AI builder can implement from this plan without inventing architecture or scope
```

### Construction Directive / AI Build Prompt

Purpose:

```text
instruct an AI engineering tool to implement a bounded unit of work
```

Must include:

```text
role of the AI builder
source authority documents
source authority revisions
implementation objective
allowed scope
explicit non-goals
required behavior
required tests
required verification
migration instructions
security constraints
documentation close-out
reporting expectations
```

Completion standard:

```text
the directive is preserved, pinned to authority, and precise enough to reduce drift while remaining
broad enough to complete the phase
```

### Test and UAT Plan

Purpose:

```text
define how success will be proven
```

Must include:

```text
unit test requirements
integration test requirements
CLI/UAT scenarios
security/governance tests
negative tests
migration tests
fixtures
manual checks
expected outputs
coverage gaps
```

Completion standard:

```text
the implementation can be accepted or rejected using documented evidence
```

### Code Review Report

Purpose:

```text
evaluate whether the code matches the documented authority
```

Must include:

```text
review scope
source documents reviewed
implementation areas reviewed
findings
severity
spec drift
test gaps
security risks
quality concerns
opportunities for improvement
residual risk
```

Completion standard:

```text
the team knows whether the implementation is conformant and what must be remediated
```

### Remediation Plan / Prompt

Purpose:

```text
correct specific review findings without widening scope
```

Must include:

```text
finding-to-remediation mapping
precise implementation instructions
tests required for each finding
non-goals
verification steps
documentation updates
```

Completion standard:

```text
each finding has a targeted correction path
```

### As-Built Documentation Close-Out

Purpose:

```text
reconcile documentation with the implemented system
```

Must include:

```text
implemented behavior
deferred behavior
changed assumptions
updated developer guides
updated CLI/API/config docs
updated examples
updated diagrams
updated schema references
known limitations
test evidence
```

Completion standard:

```text
future developers can understand the actual system without relying on chat history
```

### Traceability Matrix

Purpose:

```text
prove requirement-to-test continuity
```

Minimum columns:

```text
requirement id
requirement summary
source document
architecture rule
build-plan item
tactical task
implementation file/module
test or UAT evidence
status
notes
```

Completion standard:

```text
major requirements have visible implementation and verification evidence
```

## Process Gates

The canonical gate enumeration and detailed entry/exit criteria live in
docs/methodology/guides/gates.md. The enumeration below must remain synchronized
with that document. In any conflict, gates.md controls.

### G0: Project Initialized

Exit criteria:

```text
manifest paths are syntactically valid
starter docs exist
current gate is recorded as G1
```

### G1: Vision Ready

Exit criteria:

```text
problem statement is clear
target users are clear
success criteria are measurable and include read timing
non-goals are explicit
blocking open questions are assigned
```

### G2: Requirements Ready

Exit criteria:

```text
every baseline requirement has acceptance criteria
requirements are specific enough for architecture and tests
deferred items have reasons
open questions that block architecture are resolved or assigned
```

### G3: Architecture Ready

Exit criteria:

```text
architecture rules trace to requirements
ownership boundaries are clear
state and lifecycle are defined
stack decision is accepted
implementation does not need to invent core structure
```

### G4: Governance Ready

Exit criteria:

```text
every actor has permitted and forbidden actions
authorization rules include positive and negative tests
audit requirements are explicit
secrets and sensitive data handling are defined
agent/tool stop conditions are documented or marked N/A
```

### G5: Build Ready

Exit criteria:

```text
the build is partitioned into ordered, independently testable phases
every phase carries a stable id label; order is defined by the phase plan
the requirement coverage map accounts for all in-scope requirements
integration criteria are declared
the partitioning rationale records the sizing criterion
```

The G5 to G6 span has an interior phase loop: while current gate stays G5, the
build proceeds one phase at a time through interior checkpoints (`G5.x`) that
produce each phase's planning artifacts and record its exit. Checkpoints are not
gates; `G5.0` is the phase plan checkpoint, not a gate transition. Current
gate remains G5 through all `G5.x`.

The canonical definition is in docs/methodology/guides/gates.md ("G5 Interior:
The Phase Loop") and docs/methodology/guides/phase-loop.md.

### G6: Implementation Ready For Review

Exit criteria:

```text
all declared phases have closed phase-exit checkpoints
aggregate regression suite is green at the candidate revision
integration criteria are satisfied or carried forward as explicit residuals
implementation summary and evidence are complete enough for one conformance cycle
```

### G7: Acceptance Ready

Exit criteria:

```text
critical findings are remediated
major findings are remediated or explicitly accepted with rationale
tests and UAT evidence exist
residual risk is documented
traceability matrix reflects actual status
```

### G8: Deployment Ready

Exit criteria:

```text
deployment/release scope is accepted
deployment approvals, command/rollback plan, runbook, and monitoring are defined
production-impacting migrations and security implications are approved
post-deployment owner, value-review disposition, and validation trigger are defined
if not deploying, a non-deployment disposition is explicitly accepted
```

### G9: As-Built Closed

Exit criteria:

```text
future agents can understand the actual system without chat history
implemented behavior, deferred behavior, and deviations are explicit
deployment/validation outcomes and operational disposition are recorded
test evidence is complete and traceable
project status is closed for this iteration or release
```

## AI-Assisted Build Prompt Standard

Every substantial AI build prompt should include this structure.

```markdown
# Build Prompt

## Role
You are implementing a bounded software phase from documented authority.

## Source Authority
- Vision:
- PRD:
- Architecture:
- Governance/Security:
- Build Plan:
- Tactical Implementation Plan:
- Traceability Matrix:

## Objective
State exactly what must be built.

## Scope
State what is in scope.

## Non-Goals
State what must not be built.

## Implementation Requirements
List required behavior, modules, schemas, APIs, CLI commands, and migration behavior.

## Security and Governance Requirements
List permission, identity, audit, approval, data, and policy requirements.

## Test Requirements
List required tests, negative tests, fixtures, and UAT commands.

## Documentation Close-Out
List docs that must be updated.

## Verification
List commands to run and expected evidence.

## Reporting
Require summary of changes, tests run, skipped tests, risks, and deviations.
```

## Review Standard

A review should prioritize findings over summary.

Minimum review questions:

```text
does the code implement the documented requirements?
does the code preserve architecture boundaries?
does the code preserve security and governance rules?
does the code include required tests?
does the CLI/API expose the required UAT surface?
does the code introduce undocumented scope?
does the implementation leave deferred features accidentally executable?
does the documentation reflect the as-built result?
```

Finding format:

```text
id:
severity:
source requirement:
affected code:
problem:
risk:
required remediation:
required test:
```

## Traceability Matrix Template

```markdown
| Requirement ID | Requirement | Source | Architecture Rule | Build Item | Tactical Task | Implementation | Test/UAT Evidence | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ-001 |  |  |  |  |  |  |  | planned |  |
```

Status values:

```text
planned
implemented
verified
deferred
rejected
blocked
```

## Decision Record Template

```markdown
# Decision Record: <title>

Date:
Status: Proposed | Accepted | Rejected | Superseded
Owner:

## Context

## Decision

## Rationale

## Alternatives Considered

## Consequences

## Test Impact

## Security/Governance Impact

## Documentation Impact

## Deferred Follow-Up
```

## Documentation Close-Out Checklist

```text
developer guide updated
architecture docs updated
PRD status updated
CLI/API/config docs updated
examples updated
schemas updated
diagrams updated
traceability matrix updated
deferred backlog updated
known limitations updated
test evidence recorded
as-built deviations documented
```

## Anti-Patterns

Avoid:

```text
building directly from a chat idea
using an AI prompt as the only source of truth
letting implementation define architecture
adding tests only after code review finds gaps
mixing deferred features into current phase
keeping security behavior implicit
letting docs describe planned behavior as implemented
accepting code without traceability to requirements
writing remediation prompts that do not map to findings
allowing AI tools to silently broaden scope
```

## Minimal Project Profile

For a small project or prototype, the minimum acceptable artifact set is:

```text
1. short vision/problem statement
2. compact PRD with acceptance criteria
3. lightweight architecture note
4. tactical implementation plan with tests
5. AI build prompt
6. review/remediation notes
7. as-built close-out
```

Even in the minimal profile, the project must preserve:

```text
scope boundaries
testability
security notes
deferred items
traceability from requirement to verification
```

## Large Project Profile

For complex, security-sensitive, agentic, or multi-phase projects, use the full artifact chain:

```text
vision
PRD
architecture specification
governance/security specification
build definition
phase build plans
tactical implementation plans
construction directives
test/UAT plans
traceability matrix
code review reports
remediation prompts
as-built documentation close-out
decision records
deferred feature backlog
```

## Final Standard

A project governed by this constitution is ready for AI-assisted implementation only when:

```text
the work is documented
the scope is bounded
the architecture is explicit
security and governance are testable
implementation prompts cite authority
tests are planned
review checks conformance
remediation is traceable
documentation is reconciled
```

If those conditions are not met, the next task is documentation, not code generation.

## Appendix A: Reusable AI Prompt Library

This appendix provides reusable prompts for applying this constitution with AI-assisted engineering tools.

The prompts are intentionally verbose. Their purpose is to reduce ambiguity, control scope, preserve traceability, and prevent AI-assisted phase drift.

Use these prompts as templates. Replace bracketed values with project-specific context.

### Prompt 1: Vision and Problem Framing

Use when starting a new product, major feature, or refactor before writing requirements.

```text
I am starting a new software effort: [project or feature name].

Help me build a vision and problem-framing document that can serve as the first authority document for future requirements, architecture, and implementation planning.

The document must include:

- problem statement;
- target users or operators;
- user pain or opportunity;
- desired outcomes;
- success criteria;
- non-goals;
- major assumptions;
- major risks;
- initial security, governance, or compliance concerns;
- likely testability implications;
- open questions that must be answered before writing a PRD.

Do not write implementation details yet.

Ask any clarifying questions that would materially improve the document before drafting. If assumptions are necessary, state them explicitly.
```

### Prompt 2: PRD Construction

Use after vision/problem framing is stable.

```text
Using the following vision/problem-framing document as authority:

[attach or cite document path]

Build a Product Requirements Document for [project or feature name].

The PRD must be precise, testable, and implementation-ready but must not prescribe code architecture unless the vision document already requires it.

Include:

- product objective;
- target users;
- functional requirements;
- non-functional requirements;
- primary workflows;
- edge cases;
- explicit non-goals;
- deferred items;
- acceptance criteria;
- security/governance requirements visible at the product level;
- observability/audit requirements if applicable;
- testability notes;
- open questions.

Assign stable requirement IDs.

For each requirement, identify whether it is:

- baseline;
- deferred;
- optional;
- open pending decision.

Perform an accuracy pass when complete. During the accuracy pass, identify contradictions, vague requirements, missing acceptance criteria, untestable claims, and any scope that appears to exceed the vision document.
```

### Prompt 3: Architecture Specification

Use after the PRD is accepted.

```text
Using these authority documents:

- Vision / Problem Framing: [path]
- PRD: [path]

Build an architecture specification for [project or feature name].

The architecture must be detailed enough to guide future tactical implementation plans and AI-assisted code generation without forcing implementers to invent core boundaries.

Include:

- purpose and scope;
- terminology and glossary;
- domain model;
- component responsibilities;
- ownership boundaries;
- runtime model;
- data model;
- state lifecycle;
- interfaces and integration points;
- error and failure behavior;
- security/governance boundaries;
- identity and permission model if applicable;
- audit and observability model if applicable;
- configuration model;
- extension points;
- deferred architecture;
- diagrams where useful;
- verification specification;
- open decisions.

Every major architecture rule must trace back to one or more PRD requirements.

Do not implement code.

Ask clarifying questions before drafting if needed. After drafting, perform an accuracy pass that identifies ambiguity, contradictions, missing security boundaries, missing testability hooks, and likely implementation risks.
```

### Prompt 4: Governance and Security Specification

Use for security-sensitive systems or any agentic/tool-using platform.

```text
Using these authority documents:

- Vision / Problem Framing: [path]
- PRD: [path]
- Architecture Specification: [path]

Build a governance and security specification for [project or feature name].

The specification must define security-sensitive behavior as testable requirements, not advisory guidance.

Include:

- identity model;
- actor types;
- permission model;
- authorization boundaries;
- policy model;
- approval model;
- audit record model;
- data sensitivity model;
- secrets handling;
- tool or external-system access rules;
- failure, pause, stop, retry, and recovery behavior;
- revocation/deactivation behavior;
- threat scenarios;
- negative tests;
- CLI/API/UAT inspection requirements if applicable;
- documentation close-out requirements.

For agentic systems, explicitly define:

- agent identity;
- agent definition/versioning;
- agent sessions;
- agent actions/effects;
- tool-use attribution;
- artifact attribution;
- cross-run or cross-workflow lineage;
- what must be auditable.

Perform an accuracy pass and identify any missing security boundary that could cause implementation drift.
```

### Prompt 5: Build Definition

Use to convert accepted requirements and architecture into a buildable unit of work.

```text
Using these authority documents:

- PRD: [path]
- Architecture Specification: [path]
- Governance/Security Specification: [path, if applicable]

Build a build definition for [project or feature name].

This document must define what the implementation effort is authorized to build.

Include:

- build objective;
- source authority documents;
- in-scope capabilities;
- out-of-scope capabilities;
- deferred features;
- implementation constraints;
- required schemas or interfaces;
- migration/removal requirements if applicable;
- required test categories;
- required CLI/API/UAT evidence;
- security/governance constraints;
- documentation close-out requirements;
- open decisions that block implementation.

Do not write a tactical implementation plan yet.

Perform an accuracy pass and identify any scope ambiguity, missing test requirement, missing migration boundary, or undocumented security assumption.
```

### Prompt 6: Phase Build Plan

Use when work must be split into phases.

```text
Using the following authority documents:

- Build Definition: [path]
- Architecture Specification: [path]
- PRD: [path]

Build a phase build plan for [phase name].

The phase plan must be bounded and must prevent feature smuggling.

Include:

- phase objective;
- phase scope;
- explicit non-goals;
- dependencies;
- deferred items;
- workstreams;
- sequencing;
- risk areas;
- security/governance implications;
- migration/removal implications;
- test strategy;
- CLI/API/UAT strategy;
- acceptance criteria;
- documentation close-out requirements.

Mark every requirement or feature as:

- included in this phase;
- explicitly deferred;
- not applicable;
- blocked pending decision.

Perform an accuracy pass and identify anything that is too vague to implement or too broad for this phase.
```

### Prompt 7: Tactical Implementation Plan

Use before any substantial code generation.

```text
Using these authority documents:

- Vision / Problem Framing: [path]
- PRD: [path]
- Architecture Specification: [path]
- Governance/Security Specification: [path, if applicable]
- Build Definition: [path]
- Phase Build Plan: [path]

Build a tactical implementation plan for [phase name].

The tactical plan must be detailed, precise, and executable by an AI-assisted engineering tool without requiring it to invent architecture, scope, or tests.

Include:

- implementation objective;
- source authority and precedence;
- assumptions;
- non-goals;
- workstreams;
- file/module ownership expectations;
- data/schema changes;
- API/CLI/config changes;
- migration order;
- security/governance work;
- tests for each workstream;
- negative tests;
- CLI/API/UAT checks;
- verification commands;
- acceptance criteria;
- documentation close-out;
- deferred items;
- known risks.

Every workstream must include test expectations.

Every security-sensitive behavior must include verification requirements.

Perform an accuracy pass when complete. During the accuracy pass, identify errors, omissions, contradictions, vague instructions, missing tests, missing migration steps, missing documentation close-out items, and opportunities for improvement.
```

### Prompt 8: Construction Directive

Use to convert the tactical plan into implementation authority for an AI builder.

```text
Using this tactical implementation plan as primary authority:

[path]

And these supporting authority documents:

- PRD: [path]
- Architecture Specification: [path]
- Governance/Security Specification: [path, if applicable]
- Phase Build Plan: [path]

Build a construction directive for [phase name].

The directive will be sent to an AI engineering tool to implement the phase.

It must be precise, bounded, and tightly coupled to the tactical implementation plan.

Include:

- AI builder role;
- implementation objective;
- source authority and precedence;
- allowed scope;
- explicit non-goals;
- required implementation workstreams;
- required migration/removal behavior;
- required security/governance behavior;
- required tests;
- required verification commands;
- required CLI/API/UAT evidence;
- documentation close-out requirements;
- reporting requirements;
- stop conditions.

The directive must tell the AI builder not to implement deferred features, not to silently change architecture, and not to broaden scope without explicit authorization.

Perform an accuracy pass and verify that each tactical workstream is represented in the directive.
```

### Prompt 9: Direct AI Build Prompt

Use when sending the final implementation request to an AI builder.

```text
You are implementing [phase name] for [project name].

Primary authority:

[construction directive path or pasted directive]

Supporting authority:

- Tactical Implementation Plan: [path]
- Phase Build Plan: [path]
- Architecture Specification: [path]
- Governance/Security Specification: [path, if applicable]
- PRD: [path]

Your task:

Implement only the scope authorized by the construction directive.

You must:

- follow the documented architecture;
- preserve all phase boundaries;
- avoid deferred features;
- implement required tests;
- implement required migration/rejection behavior;
- preserve security and governance requirements;
- update required documentation;
- run the specified verification commands where possible;
- report tests run, skipped tests, risks, and deviations.

You must not:

- infer new scope from surrounding context;
- rename core concepts unless authorized;
- remove unrelated code;
- weaken permissions, identity, audit, or policy behavior;
- mark planned behavior as implemented unless it is actually implemented;
- hide failures or skipped verification.

When complete, provide:

- summary of implementation;
- files changed;
- tests added/updated;
- commands run;
- skipped verification with reasons;
- known risks;
- documentation updated;
- any deviations from the directive.
```

### Prompt 10: Full Code Review

Use after AI-generated implementation.

```text
The code for [phase name] has been generated.

Perform a deep, independent code review.

Authority documents:

- PRD: [path]
- Architecture Specification: [path]
- Governance/Security Specification: [path, if applicable]
- Phase Build Plan: [path]
- Tactical Implementation Plan: [path]
- Construction Directive: [path]

Evaluate:

1. Did the code drift from the specification?
2. Does the code support the assertions made in the authority documents?
3. Is the code internally consistent with the documented architecture?
4. Does the code meet engineering quality expectations?
5. Are there security, governance, identity, permission, audit, or data risks?
6. Are required CLI/API/UAT surfaces implemented?
7. Are required tests present and meaningful?
8. Were deferred features accidentally implemented?
9. Were required documentation updates completed?
10. Are there opportunities for improvement?

Do not change code unless explicitly instructed.

Produce a Markdown review report with findings ordered by severity.

For each finding include:

- finding id;
- severity;
- affected files/modules;
- violated requirement or architecture rule;
- problem;
- risk;
- required remediation;
- required tests;
- documentation impact.

After findings, include residual risks and testing gaps.
```

### Prompt 11: Delta Code Review

Use after remediation or a smaller code update.

```text
The implementation for [phase name] has been updated after prior review/remediation.

Perform a delta review only.

Authority documents:

- Prior Code Review: [path]
- Remediation Plan or Prompt: [path]
- Tactical Implementation Plan: [path]
- Architecture Specification: [path]
- PRD: [path]

Evaluate:

- whether each prior finding was fully remediated;
- whether the remediation introduced regressions;
- whether tests were added or updated correctly;
- whether documentation close-out was completed;
- whether any new issue appears in the changed code.

Do not repeat the full original review unless necessary.

Produce precise findings only. If no findings remain, say so and identify residual risk.
```

### Prompt 12: Remediation Prompt

Use to turn review findings into a direct fix prompt for an AI builder.

```text
Using this code review as authority:

[path]

Construct a remediation prompt for [phase name].

The remediation prompt must mitigate every finding and must not introduce unrelated scope.

For each finding, include:

- finding id;
- required code change;
- required test change;
- required documentation change, if any;
- acceptance criteria for the fix.

The prompt must instruct the AI builder to:

- preserve existing architecture;
- avoid deferred features;
- avoid broad refactors not required by the findings;
- run relevant tests;
- report any skipped verification;
- summarize how each finding was remediated.

Before finalizing, perform an accuracy pass and confirm that every finding is covered exactly once.
```

### Prompt 13: Traceability Matrix Construction

Use to enforce requirement-to-test continuity.

```text
Using these authority documents:

- PRD: [path]
- Architecture Specification: [path]
- Governance/Security Specification: [path, if applicable]
- Build Plan: [path]
- Tactical Implementation Plan: [path]
- Test/UAT Plan: [path, if separate]

Build a traceability matrix.

The matrix must map:

- requirement id;
- requirement summary;
- source document;
- architecture rule;
- build-plan item;
- tactical task;
- implementation area, if known;
- test or UAT evidence;
- status;
- notes.

Identify:

- requirements without architecture coverage;
- architecture rules without implementation tasks;
- implementation tasks without tests;
- tests that do not map to requirements;
- deferred requirements;
- blocked requirements;
- unclear or untestable requirements.

Do not invent implementation status unless evidence exists.
```

### Prompt 14: Documentation Close-Out

Use after implementation and remediation.

```text
Perform documentation close-out for [phase name].

Authority documents:

- Tactical Implementation Plan: [path]
- Construction Directive: [path]
- Code Review Report: [path]
- Remediation Report or Prompt: [path]
- Implementation summary: [path or pasted summary]

Update documentation to reflect the as-built outcome.

Review and update, as applicable:

- developer guide;
- architecture docs;
- PRD implementation status;
- CLI/API docs;
- configuration docs;
- examples;
- schema references;
- diagrams;
- deferred feature backlog;
- known limitations;
- traceability matrix;
- test evidence.

Do not describe planned behavior as implemented unless it is actually implemented.

Identify any documentation that could not be updated and explain why.
```

### Prompt 15: Migration and Removal Analysis

Use before a major refactor or replacement of old architecture.

```text
We are planning a refactor for [system/subsystem].

Using these authority documents:

- Current Architecture or Code Review: [path]
- Target Architecture Specification: [path]
- Build Plan: [path, if available]

Build a migration and removal analysis.

The analysis must compare the old implementation against the new target architecture object by object.

Classify each current object, module, schema, command, and test as:

- replace;
- adapt;
- split;
- retain;
- quarantine;
- remove;
- defer.

Include:

- current implementation inventory;
- target object inventory;
- object-by-object migration matrix;
- superseded concepts;
- retained/adapted subsystems;
- removal requirements;
- schema/store migration requirements;
- CLI/API migration requirements;
- test migration requirements;
- risks;
- acceptance criteria.

Assume backward compatibility is [required/not required].

Be precise. The goal is to prevent old architecture from surviving under new names.
```

### Prompt 16: Architecture Drift Review

Use when several AI-generated phases may have drifted from documentation.

```text
We have made significant code changes across multiple phases:

[list phases]

Perform a deep architecture drift review.

Authority documents:

- PRDs: [paths]
- Architecture Specifications: [paths]
- Build Plans: [paths]
- Tactical Implementation Plans: [paths]
- Construction Directives: [paths]

Evaluate:

- whether code drifted from specifications;
- whether code supports assertions made in the documents;
- whether code evolution is internally consistent;
- whether generated code quality meets engineering standards;
- whether security/governance/identity/permission/audit behavior is correct;
- whether required CLI/API/UAT surfaces exist;
- whether tests prove feature completeness;
- whether design decisions should be revisited.

Do not change code.

Create a Markdown report with precise findings, risks, and opportunities for improvement.

For each finding, identify the violated authority and recommended remediation.
```

### Prompt 17: Q&A Hardening Session

Use when the architecture needs collaborative tightening before implementation.

```text
We are not ready to implement yet.

Help run a Q&A hardening session for [topic/system/phase].

Use these documents as context:

- [paths]

Your role:

- identify the next most important unresolved decision;
- ask one focused question at a time;
- explain why the question matters;
- recommend an option when useful;
- identify risks and tradeoffs;
- record locked decisions;
- identify deferred items;
- identify documentation updates needed after each decision.

Do not write code.

Do not broaden scope.

After the session, produce or update a decision document summarizing:

- locked decisions;
- open decisions;
- deferred features;
- terminology changes;
- architecture implications;
- tactical planning implications.
```

### Prompt 18: Accuracy Pass

Use after any important document is drafted.

```text
Perform an accuracy pass on this document:

[path]

Evaluate:

- contradictions;
- missing definitions;
- terminology drift;
- unclear authority;
- untestable requirements;
- missing acceptance criteria;
- missing security/governance requirements;
- missing migration behavior;
- missing documentation close-out;
- accidental deferred-feature authorization;
- implementation ambiguity.

Do not rewrite the document yet.

Return:

- findings;
- severity;
- recommended correction;
- questions that must be answered before finalizing.
```

### Prompt 19: Prompt Quality Review

Use before sending a construction prompt to an AI builder.

```text
Review this AI construction prompt before I send it to an implementation agent:

[path or pasted prompt]

Evaluate whether the prompt:

- cites the correct authority documents;
- has clear scope;
- has clear non-goals;
- prevents phase drift;
- includes required tests;
- includes security/governance requirements;
- includes migration/removal instructions;
- includes documentation close-out;
- defines reporting expectations;
- has any ambiguity that could cause incorrect implementation.

Do not implement anything.

Return recommended edits and a revised prompt if needed.
```

### Prompt 20: Deferred Feature Backlog Extraction

Use to prevent deferred features from being lost or accidentally implemented.

```text
Using these documents:

- PRD: [path]
- Architecture Specification: [path]
- Build Plan: [path]
- Tactical Implementation Plan: [path]
- Code Review Report: [path, if available]

Extract a deferred feature backlog.

For each deferred item include:

- id;
- title;
- source document;
- description;
- reason deferred;
- dependencies;
- security/governance implications;
- likely tests;
- suggested future phase;
- notes.

Also identify any deferred feature that appears to have been accidentally implemented or partially implemented.
```

## Appendix B: Prompt Selection Guide

Use this guide to choose the right prompt.

| Situation | Use Prompt |
| --- | --- |
| Starting from an idea | Vision and Problem Framing |
| Turning vision into product requirements | PRD Construction |
| Defining system boundaries | Architecture Specification |
| Defining permissions, identity, audit, or policy | Governance and Security Specification |
| Deciding what a build may include | Build Definition |
| Partitioning the build into ordered, testable phases | Phase Plan |
| Splitting work into phases | Phase Build Plan |
| Preparing executable implementation instructions | Tactical Implementation Plan |
| Creating the AI builder's authority document | Construction Directive |
| Sending implementation work to an AI builder | Direct AI Build Prompt |
| Reviewing generated code | Full Code Review |
| Reviewing after fixes | Delta Code Review |
| Fixing review findings | Remediation Prompt |
| Proving requirement-to-test coverage | Traceability Matrix Construction |
| Reconciling docs after build | Documentation Close-Out |
| Planning a refactor | Migration and Removal Analysis |
| Checking multi-phase drift | Architecture Drift Review |
| Tightening uncertain architecture | Q&A Hardening Session |
| Checking a document | Accuracy Pass |
| Checking a build prompt | Prompt Quality Review |
| Capturing out-of-scope future work | Deferred Feature Backlog Extraction |
