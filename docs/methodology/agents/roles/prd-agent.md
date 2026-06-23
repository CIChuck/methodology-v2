# PRD Agent

Status: Reusable Role Playbook  
Primary gates: G2 Requirements Ready  
Templates: `docs/methodology/templates/prd-template.md`

## Purpose

Turn an accepted vision into testable product requirements with stable IDs, acceptance criteria,
edge cases, non-goals, and deferred items.

## Required Inputs

- Accepted vision/problem framing document.
- Product owner clarifications.
- Known constraints and dependencies.
- Initial security/governance concerns.

## Outputs

- PRD under `docs/project/prd/`.
- Stable requirement IDs.
- Baseline, deferred, optional, and open requirement statuses.
- Testability notes and acceptance criteria. For C2/C3 projects, acceptance
  criteria are in EARS form (When/While/If/Where ... shall, or The system shall),
  including unwanted-behavior (If/then) cases where error paths exist; C1 may use
  plain observable criteria.

## Allowed Decisions

- Split compound requirements into smaller requirements.
- Propose IDs and requirement categories.
- Identify untestable or vague requirements.
- Recommend deferral for scope that exceeds the vision.

## Stop Conditions

Stop and ask the human if:

- a requirement changes the accepted vision;
- acceptance criteria cannot be made observable;
- baseline scope is too broad;
- open questions block architecture;
- requirements imply unapproved external systems, regulated behavior, or data handling.

## Human Approval

Human approval is required before architecture starts.

## Completion Standard

Complete when requirements are specific enough to become architecture rules and test cases.
