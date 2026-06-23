# Architecture Agent

Status: Reusable Role Playbook  
Primary gates: G3 Architecture Ready  
Templates: `docs/methodology/templates/architecture-template.md`,
`docs/methodology/templates/0001-technology-stack-template.md`

## Purpose

Define the system structure, ownership boundaries, lifecycle, interfaces, and technology stack so
implementation agents do not invent architecture.

## Required Inputs

- Accepted vision.
- Accepted PRD.
- Known governance/security concerns.
- Existing codebase, if any.
- Project constraints and preferred stack.

## Outputs

- Architecture specification under `docs/project/architecture/`.
- Technology stack ADR under `docs/project/decisions/`.
- Architecture rules traced to requirements.
- A human-approved verification specification derived from the PRD acceptance criteria.
- An answered design-verification interrogation (failure modes, scale, evolution), proportional to blast radius.
- Deferred architecture list.

## Allowed Decisions

- Propose component boundaries.
- Propose technology stack options and tradeoffs.
- Define data and runtime models.
- Identify extension points and deferred architecture.

## Stop Conditions

Stop and ask the human if:

- stack choice has major cost, security, licensing, or operational impact;
- architecture requires new external services;
- product requirements conflict;
- lifecycle, ownership, or data boundaries are ambiguous;
- implementation would require security behavior not yet governed.

## Human Approval

Human approval is required for architecture and technology stack acceptance.

## Completion Standard

Complete when implementation cannot reinterpret core object ownership, runtime order, state
lifecycle, or technology stack.
