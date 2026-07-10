# Build Instruction Templates

**Status:** Reusable methodology template  
**Purpose:** Provide project-neutral prompts for phase planning, tactical planning, construction
directives, review, remediation, and documentation close-out.

Use these templates with the current project authority documents. Replace bracketed placeholders
with concrete project paths and phase names.

Each prompt produces one of the phase-loop artifacts whose templates live in this directory and
whose checkpoints are defined in `docs/methodology/guides/gates.md` ("G5 Interior: The Phase Loop")
and `docs/methodology/guides/phase-loop.md`. The accuracy pass at the end of each prompt may be
executed by an independent reviewer context as a conformance check.

## Phase Plan Prompt

Build the phase plan from the approved PRD, architecture, and governance/security specification.
This is the artifact gate G5 certifies; it partitions the build, it does not implement it.
Template: `phase-plan-template.md`.

The plan must define:

- the ordered phase sequence, each phase with a stable id label (ordering is authoritative in the
  sequence table, never computed from the id);
- a requirement coverage map assigning every in-scope requirement to an owning phase;
- cross-phase rules and invariants;
- the partitioning rationale, stating the sizing criterion (features testable together, bounded to
  what a focused implementation session can hold with its authority);
- integration criteria and who declares the integration tests;
- an amendments section for later phase insertions and splits.

Perform an accuracy pass and identify unassigned requirements, phases too broad to build without
drift, phases with no testable exit, and undefined integration criteria.

## Phase Build Plan Prompt

Build the `[phase name]` phase build plan using the approved phase plan, PRD, architecture,
and governance/security specification.
Template: `phase-build-plan-template.md`.

The plan must define:

- executive summary;
- source authority;
- in-scope work;
- out-of-scope work and explicit non-goals;
- deferred features with target phases;
- file/module ownership;
- security and governance constraints;
- test and UAT requirements;
- the phase exit test (the test that must pass for the phase to exit, its
  execution commands, and its pass criteria), with the project coverage policy
  and justified-exception rule;
- acceptance criteria;
- documentation close-out requirements.

Perform an accuracy pass and identify ambiguity, missing tests, security gaps, and scope drift risk.

## Tactical Implementation Plan Prompt

Build the tactical implementation plan for `[phase name]` from the approved phase build plan and
the prior phase's learnings (N/A for the first phase).

The plan must be executable by an implementation agent and include:

- ordered implementation tasks;
- allowed file/module changes;
- forbidden scope;
- migration or compatibility concerns;
- required tests;
- CLI/UAT checks when applicable;
- security/governance checks;
- documentation close-out.

Treat documentation reconciliation as part of the phase definition of done.

## Construction Directive Prompt

Create a bounded construction directive for `[phase name]`.
Template: `phase-construction-directive-template.md`.

The directive must cite the approved authority documents, pin the source authority revisions,
summarize the implementation objective, state non-goals, list files or modules that may change,
list required tests, and require an as-built documentation close-out. Every coding directive must
carry a Directive ID that names the tactical workstream it implements. It must not authorize
deferred features. The directive must be preserved with the resulting commit, diff, pull request, or
implementation reference.

## Build Prompt Prompt

Issue the build prompt for `[phase name]` from the accepted construction directive.
Template: `phase-build-prompt-template.md`.

The build prompt is a Rule 6 controlled artifact and must be sendable to the building agent as
written. It must:

- pin every authority document (construction directive, tactical plan, build plan, architecture,
  governance/security, PRD) at its accepted revision;
- restate scope boundaries and non-goals;
- require the phase exit test and the regression suite to pass, with the project
  coverage policy target;
- state validation gates the building agent must confirm before declaring the phase built;
- state reporting requirements (files changed, tests, commands, skipped verification with reasons,
  deviations, coverage status, residual risks);
- instruct the agent to ask clarifying questions before beginning if authority is missing,
  contradictory, or insufficient.

Perform an accuracy pass confirming all authority paths are correct and pinned, and that the prompt
can be sent without further authoring.

## Verification-Only Prompt

Perform a verification-only pass for `[phase name]`. Do not change behavior or widen scope.

Confirm:

- implementation matches the phase build plan and tactical plan;
- security/governance constraints are preserved;
- deferred features did not leak in;
- required tests and CLI/UAT checks pass;
- documentation reflects what was built.

Report actionable findings with severity, affected requirement, affected files, required
correction, and required verification.

## Code Review Prompt

Review the code generated for `[phase name or phase range]` against the approved documentation set.

Evaluate:

- requirement conformance;
- architecture conformance;
- governance/security conformance;
- test completeness;
- CLI/UAT completeness;
- error handling;
- migration behavior;
- deferred-feature boundaries;
- documentation drift;
- engineering quality.

Produce findings first, ordered by severity. If remediation is needed, include a precise
remediation prompt for each finding.
