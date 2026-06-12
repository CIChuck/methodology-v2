# Phase Build Artifact Process

Status: Initial Draft

## Purpose

This process defines how to move from a phase roadmap to an AI coding-agent build prompt.

It is optimized for projects where implementation is performed or assisted by AI coding agents and where phase discipline, testability, and documentation close-out matter.

## Process Overview

```text
Step 1: Build the Phase X Build Plan.
Step 2: Build the Phase X Tactical Implementation Plan.
Step 3: Build the Phase X Construction Directive.
Step 4: Build the Phase X Build Prompt.
Step 5: Send the build prompt to the AI coding agent.
Step 6: Review generated code against the artifacts.
Step 7: Remediate findings and close documentation.
```

This kit focuses on Steps 1 through 4.

## Step 1: Phase X Build Plan

Purpose:

```text
define what Phase X is authorized to build
```

The build plan should be based on:

```text
phase roadmap
project methodology
product requirements
architecture specifications
prior phase outcomes
known deferred work
```

The build plan must answer:

```text
what is the phase objective?
what is in scope?
what is out of scope?
what must be deferred?
what architecture governs the phase?
what security/governance concerns apply?
what tests must exist?
what documentation must be updated?
```

## Step 2: Phase X Tactical Implementation Plan

Purpose:

```text
convert the build plan into detailed implementation workstreams
```

The tactical implementation plan must define:

```text
workstreams
implementation tasks
affected modules or areas
schema/API/CLI/config changes
migration order
test expectations
negative tests
verification commands
acceptance criteria
documentation close-out
```

The tactical plan should be detailed enough that the construction directive does not need to invent implementation strategy.

## Step 3: Phase X Construction Directive

Purpose:

```text
convert tactical workstreams into coding-agent directives
```

The construction directive must instruct the AI coding agent:

```text
what to build
what not to build
which source documents control the work
which code areas are expected to change
which tests are required
which security/governance constraints must be preserved
what verification must be run
what documentation must be updated
when to stop and ask for clarification
```

## Step 4: Phase X Build Prompt

Purpose:

```text
provide the final prompt sent to an AI coding agent
```

The build prompt should be detailed, precise, and directive.

It should emphasize:

```text
source authority
scope boundaries
construction directive compliance
90% meaningful test coverage target
verification commands
documentation close-out
reporting requirements
```

## Accuracy Pass

Every artifact must end with an accuracy pass.

The accuracy pass should identify:

```text
errors
omissions
contradictions
scope drift
missing tests
missing security/governance requirements
missing documentation close-out
unresolved questions
opportunities for improvement
```

## Stop Conditions

Do not proceed to the next artifact if:

```text
source authority is missing
phase scope is unclear
architecture authority is contradictory
test requirements are absent
security/governance implications are unresolved
documentation close-out is missing
the AI must invent major product or architecture decisions
```
