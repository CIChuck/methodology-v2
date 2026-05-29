# AI-Assisted Software Engineering Documentation Constitution

Status: Reusable Standard  
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

### Rule 3: Tests Are Design Artifacts

Tests must be planned before or during architecture and tactical planning, not treated as cleanup after code generation.

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

They should be:

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

Large implementation prompts should be saved or reproducible from the phase documents.

### Rule 7: Code Review Verifies Conformance

Code review must evaluate whether the implementation matches the documentation authority.

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

## Documentation Artifact Chain

The standard documentation chain is:

```text
1. Vision / Problem Framing
2. Product Requirements Document
3. Architecture Specification
4. Governance and Security Specification
5. Build Definition
6. Phase Build Plan
7. Tactical Implementation Plan
8. Construction Directive / AI Build Prompt
9. Test and UAT Plan
10. Implementation Evidence
11. Code Review Report
12. Remediation Plan / Remediation Prompt
13. As-Built Documentation Close-Out
14. Traceability Matrix
```

Not every project needs every document as a separate file. For small projects, multiple artifacts may be combined. The required content must still exist.

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
the prompt is precise enough to reduce drift and broad enough to complete the phase
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

### Gate 1: Vision Ready

Exit criteria:

```text
problem is clear
target users are clear
success criteria are clear
non-goals are documented
```

### Gate 2: Requirements Ready

Exit criteria:

```text
requirements are specific
acceptance criteria exist
edge cases are captured
requirements can be tested
```

### Gate 3: Architecture Ready

Exit criteria:

```text
core terminology is stable
system boundaries are clear
ownership is clear
security/governance rules are explicit
state and lifecycle are defined
deferred architecture is marked
```

### Gate 4: Build Ready

Exit criteria:

```text
phase scope is bounded
tactical plan exists
tests are planned
migration is planned
AI construction directive is ready
documentation close-out is defined
```

### Gate 5: Implementation Ready For Review

Exit criteria:

```text
implementation is complete
tests were added or updated
verification was run or skipped with justification
known deviations are documented
```

### Gate 6: Acceptance Ready

Exit criteria:

```text
code review completed
findings remediated or explicitly accepted
tests and UAT evidence exist
documentation close-out completed
traceability matrix updated
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
- acceptance criteria seed;
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
