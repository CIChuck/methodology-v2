# Phase 6.5 Remediation Plan: Production Output Optimization

**Status:** Draft for review

**Date:** 2026-05-26

**Phase:** 6.5 remediation

**Source authority:** `docs/project/build-plan/phases/phase-6-5-tuning-and-optimization.md`, `docs/project/build-plan/phases/phase-6-5-tactical-implementation-plan.md`, `docs/project/build-plan/phases/phase-6-5-ai-construction-directive.md`, `docs/project/configuration/config_yaml_reference.md`, `docs/project/testing/cli-uat-harness.md`, `docs/project/security-governance/governance-security-spec.md`

**Methodology:** `docs/methodology/constitution/gendev.md`

## Objective

Add a production-oriented optimization pass that treats the primary deliverables as:

- `evaluated_form_evidence_crosswalk_index.json`
- `evaluated_form_evidence_crosswalk.md`

The remediation should reduce unnecessary durable intermediate artifact creation and redundant
work while preserving enough provenance, traceability, and audit metadata to defend the reviewer
outputs.

## Output Modes

Phase 6.5 should define explicit output modes:

- `debug_full`: writes all current intermediate, trace, and review artifacts for development.
- `uat_review`: preserves phase-exit UAT behavior and detailed inspection artifacts.
- `production`: writes only the compact evaluated crosswalk index and Markdown review surface.
- `audit_minimal`: writes the review deliverables plus minimal audit metadata without verbose debug
  traces, raw prompts, raw responses, or full page text.

`uat_review` should remain the default until production mode is intentionally implemented and
verified.

## In Scope

- Add YAML configuration for output mode and intermediate artifact persistence.
- Define which artifacts are required, optional, minimized, or omitted by mode.
- Keep logical pipeline stages intact while allowing selected intermediate stages to remain
  in-memory in `production` mode.
- Add active-run page text caching so repeated field evaluations do not reread the same page text.
- Make hybrid PA form extraction adaptive in a future implementation path: start with text/OCR and
  invoke vision only when confidence or completeness gates fail.
- Allow production mode to skip durable writes for debug-only intermediates when the downstream
  deliverables can still be produced and audited.
- Preserve reviewer-facing generic review flags and definitions in the index and Markdown.

## Out of Scope

- Removing page inventory, PA form extraction, evidence candidate selection, or evidence evaluation
  as logical stages.
- Removing all traceability.
- Changing support statuses.
- Final approval, denial, adjudication, lifecycle, watcher, or SQLite production indexing.
- Provider-native model tool-call loops.
- Prompt/model tuning against a broader sample corpus.

## Artifact Policy by Mode

| Artifact | debug_full | uat_review | production | audit_minimal |
|---|---:|---:|---:|---:|
| `packet_digest.json` | required | required | not retained | required or minimal |
| `packet_digest.md` | required | required | not retained | optional |
| `packet_analysis_index.json` | required | required | not retained | optional |
| `pa_form_extraction.json` | required | required | not retained | required or summarized |
| `form_extraction_index.json` | required | required | not retained | optional |
| `form_evidence_crosswalk.json` | required | required | not retained | optional |
| `evidence_workspace.json` | required | required | not retained | optional |
| `analysis_trace.json` | required | required | not retained | minimal |
| `evaluated_form_evidence_crosswalk.json` | required | required | not retained | optional |
| `evaluated_form_evidence_crosswalk_index.json` | required | required | required | required |
| `evaluated_form_evidence_crosswalk.md` | required | required | required | required |
| `crosswalk_evaluation_trace.json` | required | required | not written | minimal |
| page text/image artifacts | required as configured | required as configured | not retained | minimal required refs |

## Workstreams

### 1. Output Mode Configuration

Add `analysis.output_mode` with allowed values: `debug_full`, `uat_review`, `production`, and
`audit_minimal`. Default to `uat_review` during MVP development. Validate the value during config
load.

### 2. Artifact Persistence Policy

Centralize artifact write decisions so workflows can ask whether to persist each artifact type.
Avoid scattered `if production` checks across the pipeline.
For Phase 6.5, production mode may still create upstream intermediates during processing, but a
successful run must prune them from the active run directory after the final review deliverables are
written.

### 3. Production Deliverable Builder

Ensure the final index and Markdown are produced from one evaluated crosswalk object, regardless of
whether debug intermediates are persisted. Preserve source identity, run ID, status counts,
supporting pages, reviewer flags, and flag definitions.

### 4. Minimal Trace and Manifest

Define a minimal trace/manifest for `audit_minimal`, containing source identity, input hashes,
model/profile metadata, prompt key/version, config mode, status counts, performance counters, and
artifact refs. It must not store raw page text, raw prompts, raw responses, or unnecessary tool
traces. `production` mode intentionally does not write this trace.

### 5. Page Text Cache

Cache active-run page text by page number during evaluation. The same page should be read once per
run and reused across fields and batches.

### 6. Adaptive Hybrid Extraction Definition

Define `adaptive_hybrid` behavior for a later code pass: attempt text extraction first, then use
vision only when required fields are missing, extraction confidence falls below threshold, or PA form
image quality/page-text gates fail.

### 7. UAT and Production Checks

Add separate UAT checks for `uat_review` and `production`. `production` acceptance should focus on
only the two reviewer deliverables, PHI-safe console output, and elapsed runtime.

## Acceptance Criteria

- Output modes are documented with explicit artifact policies.
- `production` mode is defined around the compact JSON index and Markdown review surface.
- Production mode retains only the two reviewer deliverables after a successful run.
- The two review deliverables retain source identity, status counts, field/value/supporting page
  data, generic reviewer flags, and flag definitions.
- Minimal trace/manifest behavior is defined and PHI-safe for `audit_minimal`.
- Page text caching is included in the implementation plan.
- Existing `uat_review` behavior remains available for phase-exit testing.

## Risks

| Risk | Mitigation |
|---|---|
| Production mode loses auditability | Use `audit_minimal` when audit metadata is required; keep `production` limited to the two reviewer deliverables. |
| Skipping intermediate persistence hides errors | Keep `debug_full` and `uat_review` available and make production omission configurable. |
| Output modes complicate workflow code | Centralize artifact policy in one helper/service. |
| Adaptive hybrid misses form fields | Gate vision fallback on required-field completeness and confidence thresholds. |

## Open Decisions

- Whether future production modes should stream or keep upstream intermediates in memory instead of
  writing then pruning them.
- Whether `audit_minimal` should retain a summarized `packet_digest.json` and `pa_form_extraction`
  artifact for audit.
- Exact config shape: `analysis.output_mode` versus `output.mode`.
- Whether a future audit manifest should replace `crosswalk_evaluation_trace.json` for
  `audit_minimal`.
