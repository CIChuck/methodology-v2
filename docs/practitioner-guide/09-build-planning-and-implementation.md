# 09. Build Planning And Implementation

## Purpose

This chapter explains how GenDev moves from accepted product authority (approved artifacts and
records that govern the product) to implementation (building or changing the actual product).

## Implementation Waits For Authority

The agent should not implement meaningful product code until the project is build-ready (approved
to begin a bounded implementation phase).

Build-ready usually means:

- vision accepted (the problem and success definition are approved);
- PRD accepted (the product requirements document is approved);
- architecture accepted (the system structure and technical boundaries are approved);
- technology stack decision accepted (the core language, framework, service, and storage choices
  are approved);
- governance/security accepted (identity, authorization, data, audit, tool, and approval rules are
  approved);
- phase plan accepted (the build is partitioned into ordered, independently
  testable phases, with a requirement coverage map and integration criteria;
  this is what G5 certifies).

The per-phase build plan, tactical implementation plan, construction directive,
and build prompt are then produced one phase at a time inside the phase loop
(the G5.x checkpoints), each accepted before that phase is built. See
docs/methodology/guides/phase-loop.md.

This may look like a lot of ceremony. The point is to prevent implementation from becoming the
place where requirements, architecture, security, and acceptance criteria are invented.

For `C1` contained work, the build-ready authority may be compact. A single combined framing
artifact can preserve vision, requirements, architecture assumptions, governance assumptions, and
test expectations, and a short phase plan can define the implementation boundary. The agent still
must not begin meaningful product code until the human has approved the build-ready boundary.

For `C3` critical work, compact build-ready authority is usually inappropriate. The team should use
separate artifacts, stronger independent review, explicit enforcement or attestation evidence, and
clearer production/rollback decisions before implementation begins.

If accepted authority changes during implementation, do not keep building as if the old authority
still governs. Stop and use the amendment process. The current gate may hold while the PRD,
architecture, tests, construction directive, or traceability are reconciled. If the change
invalidates build-ready conditions, regress to the affected gate.

## Phase Build Plan

The phase build plan defines what a phase (a bounded increment of implementation work) is supposed
to deliver.

It should answer:

- What is the phase objective?
- What is in scope?
- What is out of scope?
- What requirements are included?
- What workstreams exist?
- What tests and UAT checks are expected?
- What documentation must be updated at close-out?

The phase plan is not yet a task list for the implementation agent. It is the phase boundary (the
line between what is included now and what is not).

## Tactical Implementation Plan

The tactical implementation plan converts phase scope into executable workstreams (groups of
related implementation tasks that can be built and verified).

It should define:

- workstream names;
- file or module ownership expectations;
- implementation tasks;
- test requirements;
- negative test requirements;
- migration steps (data, schema, configuration, or environment changes needed to move state);
- verification commands (commands that prove the work builds, tests, or checks correctly);
- documentation close-out items (documents that must be updated after implementation);
- stop conditions (situations where the agent must pause and ask the human before continuing).

The tactical plan should be specific enough that implementation does not need to invent architecture
or requirements.

## Test And UAT Plan

The test/UAT plan defines how the team proves the phase works. UAT means user acceptance testing,
or human-facing checks that prove the product satisfies expected workflows.

It should include:

- unit tests;
- integration tests;
- negative tests;
- security/governance tests;
- migration tests, if applicable;
- smoke tests (small checks that confirm the most important path still works);
- manual UAT scenarios (human-performed workflow checks);
- fixtures and expected outputs (known test data and the results it should produce);
- commands that must pass.

If no test command exists yet, the plan should define what command will exist after stack
initialization.

## Construction Directive

The construction directive is the controlling build instruction (the accepted, specific order to
build only the authorized scope) for the implementation agent.

It should include:

- source authority and precedence (which documents govern and which wins if documents conflict);
- implementation objective;
- allowed scope;
- non-goals;
- required workstreams;
- required tests and verification;
- security and governance requirements;
- documentation close-out requirements;
- stop conditions.

The implementation agent should follow the directive rather than renegotiating the product
(reopening product or architecture decisions during the build).

## Implementation Prompt

Good implementation prompt:

```text
Use execution-focused mode for Phase 1. Follow
docs/project/build-plan/phases/phase-1-construction-directive.md as controlling authority. Implement
only the authorized scope. Run the required verification commands. Stop if implementation requires
scope, architecture, governance, or migration changes not covered by the directive.
```

Expected agent behavior:

- read source authority;
- inspect the working tree (the current local repository files and uncommitted changes);
- implement within scope;
- add or update tests;
- run verification;
- report skipped checks honestly;
- update only the documentation required by the directive;
- stop at G6 for review (the gate where implementation is ready to be checked for conformance).

## Stop Conditions

The implementation agent must stop when:

- the directive is missing or not accepted;
- requirements are ambiguous;
- accepted authority changes without amendment classification;
- an active structural amendment affects the construction directive or source authority;
- implementation requires unapproved architecture;
- implementation requires unapproved external services;
- implementation changes security behavior;
- a migration is destructive (can lose data or be hard to reverse) or not documented;
- tests cannot be defined;
- verification fails in a way that changes scope or design.

## Practitioner Control

The practitioner should not ask the implementation agent to "just build it" unless the intended
result is a throwaway experiment. For product work, the better prompt is:

```text
Tell me whether we are build-ready. If not, identify the missing authority and recommend the next
artifact to complete.
```

That keeps implementation from becoming accidental product definition.
