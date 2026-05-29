---
name: architecture-spec-author
description: Use when creating or revising an architecture specification from PRDs or build authority. Focuses on terminology, domain model, component boundaries, ownership, lifecycle, data model, interfaces, runtime behavior, diagrams, security boundaries, deferred architecture, and acceptance criteria seeds.
metadata:
  short-description: Write architecture specifications
---

# Architecture Spec Author

Use this skill after PRD requirements are stable enough to define system structure.

The goal is to produce an architecture authority document that prevents implementers or AI builders from inventing core boundaries.

## Governing Standard

Follow `docs/methodology/constitution/gendev.md` when available.

## Inputs

Use:

- vision/problem framing;
- PRD;
- governance/security specification, if already available;
- existing code review or architecture notes;
- known constraints;
- known deferred features.

## Output Structure

Produce a Markdown architecture specification with:

- title;
- status;
- date;
- source authority;
- purpose and scope;
- architecture principles;
- terminology and glossary;
- domain model;
- component responsibilities;
- ownership boundaries;
- runtime model;
- state lifecycle;
- data model;
- interfaces and integration points;
- configuration model;
- error and failure behavior;
- security/governance boundaries;
- observability/audit model;
- extension points;
- deferred architecture;
- diagrams where useful;
- acceptance criteria seed;
- open decisions.

## Architecture Rules

- Define ownership explicitly.
- Separate design-time, runtime, configuration, and persistence concepts when applicable.
- Identify what components must not do.
- Define lifecycle and state transitions.
- Make security-sensitive boundaries testable.
- Mark deferred behavior clearly.

## Diagrams

Use Mermaid diagrams when they clarify:

- object relationships;
- cardinality;
- lifecycle;
- dependency direction;
- runtime sequence;
- trust boundaries.

Prefer several readable diagrams over one large unreadable diagram.

## Accuracy Pass

Before finalizing, identify:

- undefined terms;
- conflicting object boundaries;
- lifecycle gaps;
- unclear ownership;
- missing security/governance boundaries;
- missing acceptance criteria;
- deferred features that appear accidentally authorized;
- implementation details that should remain tactical planning.

## Completion Standard

The specification is complete when a tactical implementation plan can be written without reopening terminology, ownership, lifecycle, or authority boundaries.
