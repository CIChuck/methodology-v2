# GenDev Lite Example: Contained Internal Tool

> **Phase-loop exemption.** This example predates the G5 phase loop (the
> `G5.x` checkpoints and the six-artifact phase set). Its artifacts illustrate
> earlier single-phase structure and do not demonstrate the phase plan,
> phase-loop checkpoints, or phase exit tests. A worked phase-loop example is
> deferred to a later release. Examples are non-authoritative.


Status: Non-Authoritative Example
Authority: `docs/methodology/constitution/gendev.md`

## Purpose

This example shows a legitimate C1 GenDev Lite path. C1 means contained, low-risk, reversible work:
an internal tool, no sensitive data, no external integration, no production automation, and no
irreversible side effects.

This example is intentionally procedural rather than complete. It demonstrates how a team can
combine early gates without skipping the content those gates normally require.

## Scenario

The team wants a small CLI helper that reads a local CSV export of non-sensitive sample inventory
data, normalizes column names, removes blank rows, and writes a cleaned CSV file.

The tool:

- runs locally;
- uses only files supplied by the operator;
- does not call external services;
- does not store credentials;
- does not process regulated, confidential, or production-sensitive data;
- writes a new output file rather than overwriting the input;
- can be discarded if it proves unhelpful.

This is a good C1 candidate. If any of those assumptions change, the project should reclassify to
C2 or C3 before implementation continues.

## Manifest Scaling Block

Example `docs/project/project.yaml` scaling block:

```yaml
scaling:
  blast_radius_class: C1
  classification_reason: Local reversible helper for non-sensitive sample data; no external systems or production automation.
  classification_owner: Product owner
  class_set_on: 2026-06-10
  gate_combination_policy: g1_g4_combined
  combined_gates:
    - gates: G1-G4
      mode: combined_framing_document
      justification: Required vision, PRD, architecture, and security assumptions are preserved in one compact framing artifact because the work is contained, reversible, and non-sensitive.
      approved_by: Product owner
      approved_on: 2026-06-10
      evidence: docs/project/vision/vision.md
```

The important part is not the exact words. The important part is that the class, reason, affected
gates, preserved content, approval, and evidence are visible.

## Combined G1-G4 Framing Artifact

For C1 work, the team may combine G1 through G4 into one document if that document preserves the
required content.

Example sections:

```text
# Vision / Requirements / Architecture / Governance: CSV Cleanup Helper

Status: Ready for Approval

## Problem Statement

Operations staff receive sample inventory CSV exports with inconsistent column names and occasional
blank rows. Manual cleanup takes time and produces inconsistent files for demos.

## Target Users

Primary users are internal operations staff preparing non-sensitive demo data.

## Success Criteria

| Criterion | Measure | Target | Read Timing | Owner | Evidence Source |
| --- | --- | --- | --- | --- | --- |
| Reduce manual cleanup | Median cleanup time for one sample CSV | <= 2 minutes | After first five uses | Operations lead | Timed operator sample |

## Non-Goals

- no production data processing;
- no automatic upload;
- no external APIs;
- no in-place file mutation;
- no UI.

## Requirements

REQ-001: The CLI accepts an input CSV path and output CSV path.

REQ-002: The CLI normalizes configured column names to canonical names.

REQ-003: The CLI removes rows where all cells are blank.

REQ-004: The CLI fails with a clear error when the input file is missing.

## Architecture Assumptions

- single local CLI command;
- no persistent service;
- no database;
- no network calls;
- standard library CSV parsing unless the accepted stack decision says otherwise.

## Security And Governance Assumptions

- input must be non-sensitive sample data;
- the tool must not request credentials;
- the tool must not overwrite the input file;
- the operator owns verifying the input file is safe to process.

## Test Expectations

- fixture CSV with inconsistent headers;
- fixture CSV with blank rows;
- missing-file negative test;
- output file assertion.
```

This combined artifact is still gate evidence. It is not a chat summary.

## Approval Record

The gate log should record that G1-G4 were intentionally combined:

```yaml
event_type: gate_transition
from_gate: G1
to_gate: G5
decision: approved
approved_by: Product owner
decided_on: 2026-06-10
blast_radius_class: C1
combined_gates: G1-G4
checked: Confirmed the combined artifact preserves vision, requirements, architecture assumptions, security assumptions, and test expectations for contained C1 work.
evidence:
  - docs/project/vision/vision.md
risks_accepted:
  - Input data classification is operator-attested for the first phase.
next_gate: G5
```

The project moves to G5 because implementation is still not authorized until the build-ready scope
and directive exist.

## Compact G5 Build-Ready Record

C1 does not need an elaborate phase plan when the work is small. It still needs a bounded build
record:

```text
Phase objective:
Build a local CLI that cleans one CSV file and writes a new output CSV.

In scope:
- parse input CSV;
- normalize configured headers;
- remove blank rows;
- write output CSV;
- add tests for normal and failure paths.

Out of scope:
- production data;
- network calls;
- UI;
- database;
- overwrite-in-place mode.

Verification:
- run unit tests;
- run CLI against fixture input;
- inspect generated output.

Construction directive:
Implement only this CLI helper. Stop if the implementation requires external services, production
data handling, credentials, persistent state, or destructive file writes.
```

Human approval is still required before implementation begins.

## Sub-Agent Budget

A C1 project may use no sub-agents. If the human requests review, keep it bounded:

```text
Role: Test reviewer
Objective: Check whether the planned tests prove the stated C1 requirements.
Source authority: Combined G1-G4 artifact and compact G5 record.
Scope: Testability only.
Non-goals: Do not redesign the CLI.
Questions to answer: Are fixture, negative, and output checks sufficient?
Budget: 10 minutes or one concise review pass.
Budget escalation: Stop if a broader architecture or security review appears necessary.
Output format: Findings by severity.
Stop conditions: Sensitive data, external service, or destructive write requirement appears.
```

## Review And Close-Out

Even a C1 project should close cleanly:

- G6 records implementation summary and verification commands.
- G7 records review findings and acceptance.
- G8 is marked N/A only if there is no deployment or release. If the CLI is distributed to users,
  record release, rollback, and support assumptions.
- G9 records as-built behavior, known limitations, traceability status, and metrics snapshot.

## Reclassification Triggers

Reclassify before continuing if:

- the tool will process confidential, regulated, customer, or production data;
- the output feeds a production workflow automatically;
- the tool calls external services;
- the tool mutates source files in place;
- failure could create financial, legal, operational, or security impact.

Reclassification is not a failure. It is the methodology noticing that the blast radius changed.
