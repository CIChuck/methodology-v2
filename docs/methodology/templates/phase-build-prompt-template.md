# Phase Build Prompt: [Project Name] — Phase [id]: [Phase Name]

Status: Draft | Ready for Review | Ready for Approval | Accepted | Stale | Superseded
Date:
Owner:
Position: G5.[id].3
Authority: `docs/methodology/constitution/gendev.md` — Rule 6 (AI Build Prompts Are Controlled Artifacts)
Source:
  Construction Directive: `docs/project/build-plan/phases/[phase-construction-directive].md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/[phase-construction-directive].md
    revision: TBD

---

## Rule 6 Framing

This is a controlled build prompt. It is issued from the accepted construction
directive at a pinned revision, retained in the repository at the path above,
and is the dispatch the building agent receives. It must be sendable to the
building agent as written.

## Completion Standard

This document is complete when:

```text
it can be sent to a building agent as-is and will produce the phase exactly as
the construction directive specifies, with no further authoring required
```

---

## Pinned Authority

The building agent works from these documents at these revisions and no others.

```text
Primary authority:
- Phase [id] Construction Directive: [path] @ [revision]

Supporting authority:
- Phase [id] Tactical Implementation Plan: [path] @ [revision]
- Phase [id] Build Plan: [path] @ [revision]
- Phase Plan: [path] @ [revision]
- Architecture Specification: [path] @ [revision]
- Governance/Security Specification: [path] @ [revision, if applicable]
- PRD / Requirements: [path] @ [revision]
```

---

## Prompt

```text
It is time to build Phase [id] for [project name].

Primary authority:
- Phase [id] Construction Directive: [path] @ [revision]

Supporting authority:
- Phase [id] Tactical Implementation Plan: [path] @ [revision]
- Phase [id] Build Plan: [path] @ [revision]
- Architecture Specification: [path] @ [revision]
- Governance/Security Specification: [path] @ [revision, if applicable]
- PRD / Requirements: [path] @ [revision]

Your task:

Implement Phase [id] exactly as specified by the construction directive and
tactical implementation plan.

You must:
- follow the source authority and precedence order;
- preserve Phase [id] scope boundaries;
- implement only authorized Phase [id] behavior;
- avoid deferred features and non-goals;
- preserve architecture rules;
- preserve security, governance, identity, permission, audit, policy, approval,
  and data-handling requirements;
- implement required tests;
- target project-defined coverage policy coverage for new or materially changed
  code unless impractical and justified in writing with a named residual risk;
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

Ask any clarifying questions before beginning if the source authority is
missing, contradictory, or insufficient.
```

---

## Validation Gates

Before the phase is declared built, the building agent must confirm:

```text
[ ] the phase exit test (from the build plan) passes at the candidate revision
[ ] the accumulated regression suite is green
[ ] coverage meets project-defined target or the shortfall is justified with a named residual risk
[ ] required verification commands ran or were reported as skipped with reasons
[ ] required documentation was updated
```

---

## Reporting Requirements

```text
files changed
tests added or updated
commands run
skipped verification with reasons
deviations from authority
coverage status
residual risks
```

---

## Accuracy Pass

Before issuing this prompt, verify:

```text
phase id/name is correct
all authority paths are correct and pinned at accepted revisions
construction directive exists and is Accepted
tactical implementation plan exists and is Accepted
build plan exists and is Accepted
project coverage policy reference is included
non-goals are explicit
documentation close-out is included
reporting requirements are included
clarifying-question instruction is included
```
