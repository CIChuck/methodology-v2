# Phase Build Prompt Authoring Directive

Use this directive to ask an AI to create the final Phase X Build Prompt.

## Template

Use:

```text
docs/AI-Build-Kit/templates/phase-build-prompt-template.md
```

## Directive

```text
It is time to build the Phase X Build Prompt.

Using the Phase X Construction Directive and Phase X Tactical Implementation Plan as primary authority, produce a very detailed, precise prompt for an AI coding agent to build Phase X code.

Use this template:
docs/AI-Build-Kit/templates/phase-build-prompt-template.md

Maintain the same style and precision as prior tactical construction directives.

Err on the side of verbosity.

Precision counts.

The prompt must:

- identify primary and supporting authority;
- instruct the AI coding agent to implement only Phase X scope;
- preserve architecture and methodology rules;
- preserve security/governance behavior;
- prohibit deferred features and scope drift;
- require tests;
- emphasize the importance of 90% meaningful test coverage for new or materially changed code unless impractical and justified;
- require verification commands where possible;
- require documentation close-out;
- require reporting of files changed, tests, commands, skipped verification, risks, and deviations;
- instruct the agent to ask clarifying questions before beginning if authority is missing or contradictory.

Do not implement code.

Ask any questions that would help clarify this request.
```

## Quality Check

Before accepting the output, verify:

```text
prompt can be sent directly to an AI coding agent
source authority paths are included
scope and non-goals are clear
90% coverage target is included
documentation close-out is included
reporting requirements are included
clarifying-question instruction is included
```
