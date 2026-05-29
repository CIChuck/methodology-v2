# Build Instruction Templates

**Status:** Reusable methodology template  
**Purpose:** Provide project-neutral prompts for phase planning, tactical planning, construction
directives, review, remediation, and documentation close-out.

Use these templates with the current project authority documents. Replace bracketed placeholders
with concrete project paths and phase names.

## Phase Build Plan Prompt

Build the `[phase name]` phase plan using the approved vision, PRD, architecture,
governance/security specification, traceability matrix, and roadmap.

The plan must define:

- executive summary;
- source authority;
- in-scope work;
- out-of-scope work;
- deferred features;
- file/module ownership;
- security and governance constraints;
- test and UAT requirements;
- acceptance criteria;
- documentation close-out requirements.

Perform an accuracy pass and identify ambiguity, missing tests, security gaps, and scope drift risk.

## Tactical Implementation Plan Prompt

Build the tactical implementation plan for `[phase name]` from the approved phase build plan.

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

The directive must cite the approved authority documents, summarize the implementation objective,
state non-goals, list files or modules that may change, list required tests, and require an
as-built documentation close-out. It must not authorize deferred features.

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
