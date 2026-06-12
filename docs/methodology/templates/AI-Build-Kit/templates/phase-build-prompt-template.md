# Phase X Build Prompt

Status: Draft  
Date: YYYY-MM-DD  
Phase: Phase X  
Project:

## Prompt

```text
It is time to build Phase X for [project name].

Primary authority:
- Phase X Construction Directive: [path]

Supporting authority:
- Phase X Tactical Implementation Plan: [path]
- Phase X Build Plan: [path]
- Phase Roadmap: [path]
- Architecture Specification: [path]
- Governance/Security Specification: [path, if applicable]
- PRD / Requirements: [path]
- Project methodology documents: [paths]

Your task:

Implement Phase X exactly as specified by the construction directive and tactical implementation plan.

You must:

- follow the source authority and precedence order;
- preserve Phase X scope boundaries;
- implement only authorized Phase X behavior;
- avoid deferred features and non-goals;
- preserve architecture rules;
- preserve security, governance, identity, permission, audit, policy, approval, and data-handling requirements;
- implement required tests;
- target at least 90% meaningful test coverage for new or materially changed code unless impractical and justified;
- include negative tests where required;
- include migration or legacy-rejection tests where required;
- run required verification commands where possible;
- update required documentation;
- report skipped verification honestly;
- report deviations from the directive.

You must not:

- broaden scope;
- infer new feature authority from surrounding context;
- silently change architecture;
- weaken security or governance behavior;
- implement deferred features;
- remove unrelated code;
- rewrite unrelated modules;
- claim documentation close-out is complete unless docs were updated.

When complete, report:

- summary of implementation;
- files changed;
- tests added or updated;
- commands run;
- skipped commands and reasons;
- documentation updated;
- coverage status or best available coverage evidence;
- risks and residual gaps;
- deviations from source authority.

Ask any clarifying questions that would help complete this implementation safely and accurately before beginning if the source authority is missing, contradictory, or insufficient.
```

## Accuracy Pass

Before sending, verify:

```text
phase number/name is correct
all authority paths are correct
construction directive exists
tactical implementation plan exists
build plan exists
90% test coverage target is included
non-goals are explicit
documentation close-out is included
reporting requirements are included
clarifying-question instruction is included
```
