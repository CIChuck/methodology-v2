# Phase Build Plan Authoring Directive

Use this directive to ask an AI to create a Phase X Build Plan.

## Template

Use:

```text
docs/AI-Build-Kit/templates/phase-build-plan-template.md
```

## Directive

```text
Using the Phase Roadmap and project methodology documents as baseline authority, build a comprehensive Phase X Build Plan.

Use this template:
docs/AI-Build-Kit/templates/phase-build-plan-template.md

The build plan must define:

- phase objective;
- source authority;
- phase scope;
- explicit non-goals;
- deferred work;
- methodology baseline;
- architecture baseline;
- governance/security baseline;
- workstreams;
- dependencies;
- migration/removal requirements;
- test strategy;
- CLI/API/UAT strategy where applicable;
- acceptance criteria;
- documentation close-out;
- risks;
- open questions;
- accuracy pass.

Err on the side of precision and useful detail.

Do not write implementation code.

Do not create the tactical implementation plan yet unless explicitly asked.

Ask clarifying questions if source authority is missing, contradictory, or insufficient.
```

## Quality Check

Before accepting the output, verify:

```text
phase scope is clear
non-goals are explicit
test strategy exists
documentation close-out exists
security/governance implications are addressed
accuracy pass identifies gaps
```
