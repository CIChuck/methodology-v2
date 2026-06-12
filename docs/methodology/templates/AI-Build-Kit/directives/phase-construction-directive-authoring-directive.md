# Phase Construction Directive Authoring Directive

Use this directive to ask an AI to create a Phase X Construction Directive.

## Template

Use:

```text
docs/AI-Build-Kit/templates/phase-construction-directive-template.md
```

## Directive

```text
Using the accepted Phase X Tactical Implementation Plan as primary authority, build a detailed Phase X Construction Directive.

Use this template:
docs/AI-Build-Kit/templates/phase-construction-directive-template.md

The construction directive must break the tactical implementation plan into very specific coding directives capable of being executed by an AI coding agent.

It must include:

- AI builder role;
- source authority and precedence;
- implementation objective;
- allowed scope;
- explicit non-goals;
- concrete coding directives;
- migration/removal directives;
- security/governance directives;
- test directives;
- verification directives;
- documentation close-out directives;
- reporting requirements;
- stop conditions;
- anti-drift rules;
- accuracy pass.

Each coding directive must include:

- directive ID;
- purpose;
- likely affected files/modules/subsystems;
- required behavior;
- required tests;
- acceptance criteria.

Emphasize the importance of 90% meaningful test coverage for new or materially changed code unless impractical and justified.

Do not implement code.

Do not create the final build prompt unless explicitly asked.

Ask clarifying questions if the tactical plan is ambiguous or insufficient.
```

## Quality Check

Before accepting the output, verify:

```text
each tactical workstream has coding directives
each directive has test expectations
90% coverage target appears
security/governance directives are present
stop conditions are clear
anti-drift rules are strong
documentation close-out is included
```
