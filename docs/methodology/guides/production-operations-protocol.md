# Production Operations Protocol

Status: Reusable Standard  
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This guide defines production as an operating lifecycle, not merely deployment. A project is not
production-ready until deployment, validation, monitoring, rollback, runbook, and operational handoff
are addressed.

## Production Scope

Production includes:

- release scope;
- deployment target;
- environment configuration;
- secrets and credentials;
- migration and rollback;
- deployment execution;
- post-deployment validation;
- monitoring and alert review;
- incident and rollback decision process;
- operating runbook;
- known limitations and follow-up backlog.

## Required Authority

Before production work, confirm:

- accepted PRD;
- accepted architecture;
- accepted governance/security specification;
- accepted phase scope;
- accepted implementation or release candidate;
- test and UAT evidence;
- code review and remediation status;
- deployment approver.

## Deployment Readiness Checklist

Required:

```text
[ ] release scope documented
[ ] deployment target approved
[ ] environment variables documented
[ ] secrets source documented without secret values
[ ] data migration plan documented or N/A
[ ] rollback plan documented or N/A with reason
[ ] operational checks defined
[ ] monitoring/alert checks defined
[ ] post-deployment validation defined
[ ] known limitations documented
[ ] human deployment approval recorded
```

## Environment And Secrets

Agents must not ask humans to paste production secrets into chat.

Documentation should state:

- secret names;
- expected storage location;
- rotation expectation;
- access owner;
- deployment-time validation;
- what must never be logged.

## Migration And Rollback

For any data, schema, or infrastructure change:

```text
Migration:
Preconditions:
Execution steps:
Validation:
Rollback trigger:
Rollback steps:
Rollback validation:
Irreversible impact:
Approver:
```

If rollback is not possible, the risk must be explicitly accepted before deployment.

## Production Runbook

A production runbook should include:

- service overview;
- deployment command or process;
- configuration and secret references;
- health checks;
- monitoring dashboards or signals;
- common failure modes;
- rollback procedure;
- incident contacts or owners;
- post-deployment checklist;
- known limitations;
- follow-up backlog.

## Release Approval

Use the deployment approval record from `human-approval-protocol.md`.

Required fields:

```text
Release scope:
Deployment target:
Approved by:
Date:
Rollback plan reviewed:
Monitoring plan reviewed:
Known risks accepted:
Post-deployment owner:
```

## Post-Deployment Validation

After deployment, validate:

- application starts successfully;
- health checks pass;
- required user workflow smoke tests pass;
- logs do not expose sensitive data;
- metrics and alerts are active;
- migration results are correct;
- no unexpected error spike appears.

Record:

```text
Validation time:
Validator:
Checks run:
Results:
Issues found:
Follow-up:
```

## Monitoring Review

Monitoring review should answer:

- What tells us the release is healthy?
- What tells us users are blocked?
- What tells us data or security behavior is wrong?
- Who receives alerts?
- What is the response expectation?

If monitoring is not available, record the limitation and acceptance.

## Rollback Decision Process

Define rollback triggers before deployment.

Example triggers:

- health checks fail;
- critical workflow fails;
- elevated error rate persists;
- data migration validation fails;
- security-sensitive behavior is wrong;
- human owner requests rollback.

Rollback decisions require a human owner unless emergency procedures define otherwise.

## Incident Handoff

If deployment causes an incident, record:

- incident summary;
- start time;
- affected users or systems;
- mitigation;
- rollback status;
- owner;
- follow-up tasks;
- documentation updates required.

## Operational Close-Out

A release is operationally closed when:

- deployment status is known;
- post-deployment validation is recorded;
- rollback was not needed or was completed;
- monitoring status is documented;
- incidents and follow-ups are tracked;
- as-built docs and known limitations are updated.

## Stop Conditions

Agents must stop before deployment or rollback if:

- human deployment approval is missing;
- production target is unknown;
- secrets are requested in chat;
- rollback is undefined for risky changes;
- monitoring/validation is absent and risk is not accepted;
- governance/security requirements are unmet.

## Completion Standard

This protocol is working when production release decisions are explicit, reversible where possible,
observable after deployment, and understandable to future humans and agents.
