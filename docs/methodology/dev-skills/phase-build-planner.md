---
name: phase-build-planner
description: Use when defining build definitions or phase build plans from accepted PRD and architecture authority. Focuses on bounded scope, phase objectives, dependencies, deferred items, sequencing, risks, test strategy, migration behavior, acceptance criteria, and documentation close-out.
metadata:
  short-description: Plan bounded build phases
---

# Phase Build Planner

Use this skill to turn product and architecture authority into a bounded build phase.

The goal is to prevent feature smuggling and create a phase that can become a tactical implementation plan.

## Governing Standard

Follow `docs/methodology/constitution/gendev.md` when available.

## Inputs

Use:

- PRD;
- architecture specification;
- governance/security specification;
- build definition;
- prior phase reports;
- deferred feature backlog;
- code review findings, if applicable.

## Output Structure

Produce a Markdown build plan with:

- title;
- status;
- date;
- source authority;
- phase objective;
- in-scope work;
- out-of-scope work;
- deferred items;
- dependencies;
- assumptions;
- workstreams;
- sequencing;
- migration/removal requirements;
- security/governance implications;
- test strategy;
- CLI/API/UAT strategy;
- acceptance criteria;
- documentation close-out;
- risks;
- open decisions.

## Scope Rules

- Label every major item as included, deferred, out of scope, or blocked.
- Do not let implementation details override architecture.
- If scope is too broad, recommend subphases.
- Make migration/removal work first-class for refactors.
- Make documentation close-out part of definition of done.

## Accuracy Pass

Before finalizing, identify:

- scope ambiguity;
- deferred items that look included;
- included items without acceptance criteria;
- missing test strategy;
- missing migration work;
- missing security/governance work;
- unresolved decisions that block tactical planning.

## Completion Standard

The build plan is complete when a tactical implementation planner can convert it into executable workstreams.
