# Code Review Report: [Project Name] — Phase [N]: [Phase Name]

Status: Draft | Ready for Review | Complete | Stale | Superseded
project: [project-slug]
Date:
Reviewer:
Authority: `docs/methodology/constitution/gendev.md` — Rule 7: Code Review Verifies Conformance
Source:
  Construction Directive: `docs/project/build-plan/phases/[directive].md`
  Tactical Plan: `docs/project/build-plan/phases/[tactical-plan].md`
  Architecture: `docs/project/architecture/[architecture-document].md`
  Governance/Security: `docs/project/security-governance/[governance-document].md`
  PRD: `docs/project/prd/[prd-document].md`
  Traceability Matrix: `docs/project/traceability/[traceability-matrix].md`
Produced by: TBD
Produced on: [YYYY-MM-DD]
Produced with: human-agent collaboration
Agent identity: TBD
Derived from:
  - path: docs/project/build-plan/phases/[directive].md
    revision: TBD
  - path: docs/project/build-plan/phases/[tactical-plan].md
    revision: TBD
  - path: docs/project/architecture/[architecture-document].md
    revision: TBD
  - path: docs/project/security-governance/[governance-document].md
    revision: TBD
  - path: docs/project/prd/[prd-document].md
    revision: TBD
  - path: docs/project/traceability/[traceability-matrix].md
    revision: TBD

---

## Completion Standard

This document is complete when:

```text
the team knows whether the implementation is conformant
and what must be remediated
```

Do not mark Complete until all findings are categorized, residual risks are documented,
and the G6 checklist (Implementation Ready For Review) is satisfied.

---

## Review Scope

```text
What code, files, or subsystems were reviewed?
What was explicitly not reviewed?
```

---

## Context Provenance

```text
Reviewing agent:
Model/version:
Review context created on:
Inputs provided:
Authority document revisions used:
Implementation diff or commit reviewed:
Implementer session shared with reviewer: No
Exceptions:
```

Rules:

```text
Review should start from fresh context.
Do not include implementer session transcript, private reasoning trace, or broad chat history unless
an exception is justified here.
If implementer context was shared, explain why it was necessary and how it may affect independence.
```

---

## Review Questions Evaluated

```text
1. Does the code implement the documented requirements?
2. Does the code preserve architecture boundaries?
3. Does the code preserve security and governance rules?
4. Does the code include required tests?
5. Does the CLI/API expose the required UAT surface?
6. Does the code introduce undocumented scope?
7. Does the implementation leave deferred features accidentally executable?
8. Does the documentation reflect the as-built result?
```

---

## Findings

Findings are ordered by severity.

Severity values:

```text
critical   — blocks acceptance; must be remediated before merge
major      — significant risk or spec drift; requires remediation
minor      — quality or consistency issue; should be remediated
advisory   — observation; remediation at discretion
```

### Finding [ID]

```text
id:
severity:
affected files/modules:
violated requirement or architecture rule:
problem:
risk:
required remediation:
required tests:
documentation impact:
```

<!-- Repeat for each finding -->

---

## Summary

| Severity | Count |
| --- | --- |
| Critical |  |
| Major |  |
| Minor |  |
| Advisory |  |

---

## Residual Risks

```text
What risks remain after remediation of the findings above?
What is not fully covered by the current test suite?
```

---

## Testing Gaps

```text
What required tests are absent or insufficient?
```

---

## Accuracy Pass

Before marking this document Complete, perform an accuracy pass.

Check for:

```text
[ ] findings that reference the wrong requirement or architecture rule
[ ] severity assignments that are inconsistent with impact
[ ] residual risks that were not surfaced as findings
[ ] testing gaps that require a finding but were not raised
[ ] deferred feature leakage that was not flagged
[ ] documentation drift that was not noted
[ ] context provenance is complete
```

---

## G6 Status (Implementation Ready For Review)

```text
[ ] critical findings: none remaining
[ ] major findings: remediated or explicitly accepted with documented rationale
[ ] tests were added or updated
[ ] deferred features confirmed not accidentally executable
[ ] known deviations from the directive are documented
```

Implementation is ready for acceptance: Yes | No | Pending remediation
