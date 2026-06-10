# 10. Review, Remediation, And Close-Out

## Purpose

This chapter explains how GenDev handles implementation review (checking built work against
accepted authority), remediation (fixing review findings or explicitly resolving them),
acceptance (human decision to accept the implemented state), and as-built documentation (records of
what actually exists after implementation).

## Review Is Conformance, Not Taste

The code review stage checks whether implementation conforms to documented authority (the accepted
artifacts and records governing the work).

Conformance review should be independent from the implementation context. Independent review means
the reviewer starts from accepted authority, the implementation diff or artifact, and verification
evidence, rather than continuing from the implementation agent's chat session.

The review should compare implementation against:

- construction directive (the controlling build instruction);
- tactical implementation plan (the actionable workstream and task plan);
- phase build plan (the approved phase scope and objectives);
- PRD (product requirements document);
- architecture (system structure and technical boundaries);
- governance/security specification (identity, authorization, data, audit, tool, and approval
  rules);
- test/UAT plan (automated and user acceptance testing plan);
- traceability matrix (map from requirements to implementation, tests, and evidence).

Review findings should be ordered by severity (how seriously a finding affects acceptance or
deployment) and tied to source authority (the governing document or record that the finding cites).
The review should also record source revisions when practical. A finding tied to `REQ-003` is more
useful when the reviewer can identify the PRD revision, architecture revision, construction
directive revision, and implementation diff that were actually reviewed.

If review discovers that accepted authority is wrong or incomplete, the reviewer should not fix the
implementation by inventing hidden authority. The finding should recommend amendment or regression.
The lead agent should then classify the amendment, record the decision, and reconcile downstream
artifacts before acceptance.

## Context Provenance

Every code review report should include context provenance, the record of what the reviewer was
given.

Minimum fields:

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

`Implementer session shared with reviewer` should normally be `No`. If the reviewer receives
implementer chat history or reasoning, the report should explain why that exception was necessary
and how it may affect independence.

## Code Review Report

The code review report should include:

- files reviewed;
- authority reviewed, including pinned revisions where practical;
- context provenance;
- construction directive or implementation prompt that produced the change;
- implementation reference, such as commit, diff, or pull request;
- findings by severity;
- missing tests;
- scope drift (implementation moving beyond or away from approved scope);
- security/governance issues;
- documentation drift;
- residual risks (risks remaining after remediation);
- recommended remediation.

Findings should be concrete. A finding such as "needs cleanup" is not enough. A useful finding says
what violates authority, why it matters, and what must change.

## Severity

Use practical severity categories:

- critical: cannot accept or deploy;
- major: must remediate or explicitly accept risk;
- minor: should fix but does not block acceptance;
- advisory: improvement suggestion, not a required change.

Critical and major findings require remediation or explicit human acceptance before phase
acceptance.

## Remediation

The remediation agent (the agent role focused on fixing review findings) or lead agent should
address findings exactly once.

For each finding:

- remediate;
- defer with human approval (move the issue to later work intentionally);
- accept risk with human approval (carry the known risk forward);
- open an amendment if the finding exposes incorrect accepted authority;
- reopen planning if the finding exposes an authority gap (missing or conflicting project
  authority).

The agent should not silently broaden scope during remediation.

## Verification After Remediation

After remediation, the agent should rerun relevant checks and update evidence (proof supporting
the new readiness claim).

Evidence may include:

- test command output summary;
- UAT result summary;
- security test result;
- migration validation (proof that data, schema, configuration, or environment changes worked);
- manual verification notes;
- review confirmation.

If verification cannot be run, the agent must report why and whether the risk is acceptable.

## Acceptance

Phase acceptance means the human accepts the implemented state after review and remediation.

Before acceptance, confirm:

```text
[ ] critical findings are remediated
[ ] major findings are remediated or explicitly accepted
[ ] required tests passed or exceptions are recorded
[ ] UAT evidence exists where required
[ ] traceability matrix reflects actual evidence
[ ] active amendments are resolved or explicitly non-blocking
[ ] code review report includes context provenance
[ ] known limitations are documented
[ ] deferred items are tracked
```

## As-Built Close-Out

As-built close-out records what actually exists (not merely what the plan said should exist).

It should update or reference:

- implemented behavior;
- deviations from plan (differences between intended and actual implementation);
- deferred behavior;
- known limitations;
- test/UAT evidence;
- traceability status;
- provenance updates, including changed source revisions and any stale downstream artifacts;
- architecture or PRD changes discovered during implementation;
- operational notes;
- next phase or backlog items (future work intentionally postponed or newly discovered).

The as-built document is important because future agents will not have perfect memory of the
implementation session.

## Close-Out Prompt

```text
Perform as-built close-out for Phase 1. Use the implementation summary, review report, remediation
results, test/UAT evidence, and traceability matrix. Update only the documents needed to make the
actual implemented state clear to a future agent.
```

Expected agent behavior:

- read the relevant evidence;
- identify planned-versus-actual differences;
- update close-out docs;
- update traceability;
- update artifact provenance or mark downstream artifacts stale when authority changed;
- report any missing evidence;
- recommend phase acceptance or next remediation.
