# Phase Tactical Implementation Plan Authoring Directive

Use this directive to ask an AI to create a Phase X Tactical Implementation Plan.

## Template

Use:

```text
docs/AI-Build-Kit/templates/phase-tactical-implementation-plan-template.md
```

## Directive

```text
Using the accepted Phase X Build Plan as primary authority, build a detailed Phase X Tactical Implementation Plan.

Use this template:
docs/AI-Build-Kit/templates/phase-tactical-implementation-plan-template.md

The tactical implementation plan must define the build plan in greater implementation detail.

It must include:

- source authority and precedence;
- implementation objective;
- assumptions;
- explicit non-goals;
- detailed workstreams;
- likely affected modules/files/subsystems;
- data/schema changes;
- API/CLI/configuration changes;
- migration order;
- security/governance work;
- unit, integration, negative, migration, security/governance, and CLI/API/UAT tests;
- verification commands;
- documentation close-out;
- acceptance criteria;
- deferred items;
- risks and mitigations;
- accuracy pass.

Err on the side of verbosity and precision.

Do not write implementation code.

Do not create the construction directive unless explicitly asked.

Ask clarifying questions if the build plan is ambiguous or insufficient.
```

## Quality Check

Before accepting the output, verify:

```text
each build-plan workstream has tactical implementation detail
tests are mapped to workstreams
negative tests are included where relevant
migration order is clear
documentation close-out is executable
accuracy pass identifies gaps
```
