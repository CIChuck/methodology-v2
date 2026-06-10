# 11. Production Operations

## Purpose

This chapter explains how GenDev treats production (the real operating environment where intended
users depend on the product), production readiness (proof that an accepted product state can safely
enter that environment), deployment (release to that environment), rollback (returning to a
previous known-good state), monitoring (observing health, errors, and important signals), and
post-production operation (the work after release).

## Production Is A Separate Gate

Implementation acceptance (human acceptance of the built state after review) is not deployment
approval (human approval to release). A product can be accepted as implemented and still be unready
for production.

Deployment readiness requires:

- accepted implementation;
- release scope (exactly what is being released);
- deployment target (the environment where the product will run);
- configuration and secrets documentation (required settings and protected credentials);
- migration plan (data, schema, configuration, or environment changes needed for release);
- rollback plan;
- monitoring or validation plan;
- operational runbook (operator instructions for deployment, validation, failure response, and
  rollback);
- enforcement or attestation evidence required by the project enforcement block;
- value review trigger and owner;
- human deployment approval.

## Deployment Readiness

The deployment readiness agent (the agent role that prepares and checks release readiness) should
confirm:

- what exactly is being released;
- where it is being deployed;
- what environment variables or secrets are required;
- what database or storage changes occur;
- what migrations run;
- what can fail;
- how rollback works;
- how success will be measured;
- which G1 success criteria are due for value review;
- who owns post-deployment response.

If rollback is impossible or partial, the risk must be explicitly accepted.

## Runbook

A production runbook should include:

- service or product name;
- deployment target;
- deployment command or procedure;
- configuration checklist;
- secrets handling notes;
- smoke test procedure (small post-release checks for the most important workflow);
- monitoring signals;
- common failure modes;
- rollback procedure;
- incident contacts or owners;
- post-deployment validation steps.

The runbook should be usable by a future operator who was not present during implementation.

## Monitoring And Validation

Post-deployment validation (checks performed after release) should answer:

- Did deployment complete?
- Is the app reachable?
- Are expected workflows functional?
- Are errors within expected bounds?
- Are logs and metrics available?
- Are alerts configured, if needed?
- Are critical user or data flows intact?

For an early internal product, monitoring may be lightweight (for example logs plus a manual health
check). It still needs to be explicit.

## Value Review

Value review compares the G1 success criteria (the measurable outcomes declared at the vision gate)
against actual post-deployment evidence. Each due criterion is reported as `met`, `missed`, or
`unmeasurable`.

Before deployment, the team should know:

- the value read trigger or date;
- the owner of the value review;
- the evidence sources that will be used;
- which success criteria are due for this release.

Unmeasurable criteria are not success. They mean the project lacks the evidence needed to know
whether the intended outcome happened.

## Rollback

Rollback planning should define:

- rollback trigger (the condition that causes the team to roll back);
- rollback owner (the person accountable for deciding or executing rollback);
- rollback steps;
- data impact;
- validation after rollback;
- communication requirements;
- known limits.

If a deployment includes irreversible migration (a change that cannot be fully undone), the team
must either redesign the release or record explicit human risk acceptance.

## Deployment Approval Prompt

Before deployment, the agent should present:

```text
Release scope:
Deployment target:
Deployment procedure:
Rollback plan:
Monitoring/validation plan:
Value review trigger:
Value review owner:
Enforcement class:
Blast-radius class:
Attestation or enforcement evidence:
Override status:
Known risks:
Post-deployment owner:
Approval requested:
```

The human approval should be recorded in `docs/project/approvals/gate-log.md` and summarized in
`project.yaml`.

## Post-Production Operation

After deployment, the agent should help record:

- deployment result;
- post-deployment validation result;
- incidents or anomalies;
- rollback status;
- monitoring status;
- value review status;
- enforcement override status, if any methodology control was bypassed;
- known limitations;
- follow-up backlog;
- operational owner.

Production operation is part of the methodology, not an afterthought.

## Thin First-Release Standard

For a small first release, "production-ready" (sufficiently prepared for the intended production
context and risk level) may mean:

- a single approved deployment target;
- documented manual deployment steps;
- documented manual rollback;
- basic logs;
- a smoke test;
- a named value review owner when measurable value is expected;
- attested enforcement evidence when no mechanical binding exists;
- a named human owner.

That is acceptable when risk is low and explicitly accepted. It is not acceptable to have no
deployment procedure, no rollback thinking, and no owner.
